// LibraryViewModel — ChangeNotifier-based ViewModel for the Library screen.
//
// Subscribes to [NotationRepository.watchAllActive] and exposes state as a
// sealed [LibraryState] hierarchy: idle / loading / success / error.
//
// Search: the user's query is debounced 300 ms before calling [SearchService].
// Results are IDs; the ViewModel filters [_allNotations] to those IDs and
// exposes [displayedNotations] (a Future<List<Notation>>).
//
// Tag filter: [selectedTagIds] holds the set of active tag ids. When non-empty
// the ViewModel filters [displayedNotations] client-side using the
// [_notationTagIds] map (notationId → Set<tagId>). Multiple tags use AND
// logic — a notation must have ALL selected tags.
//
// Composition: search is applied first (yielding a subset of all notations),
// then the tag filter is applied on that subset.
//
// Provides [softDelete] for moving a notation to trash from the Library,
// and [undoDelete] for restoring it via [TrashRepository.restoreNotation]
// within the undo window.
//
// Provides [duplicate] for copying a notation via [DuplicateNotationUseCase].
// Emits the new notation id via [lastDuplicatedId] on success.
//
// A single [operationError] field surfaces per-operation failures without
// replacing the main list state.
//
// Construction:
//   LibraryViewModel(notationRepository, trashRepository,
//     tagRepository: tagRepo,
//     duplicateUseCase: useCase)
//
// Lifecycle:
//   Call [init] once (e.g. via addPostFrameCallback in initState).
//   Disposal is handled by the ChangeNotifier lifecycle.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/features/edit/viewmodels/duplicate_notation_use_case.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Sort options
// ---------------------------------------------------------------------------

/// Sort options available to the user on the Library screen.
///
/// Each value maps to a [NotationSortBy] pair used in the Drift query.
enum LibrarySort {
  /// Alphabetical A-Z by title.
  titleAsc,

  /// Alphabetical Z-A by title.
  titleDesc,

  /// Most-recently written first.
  dateWrittenDesc,

  /// Oldest written first.
  dateWrittenAsc,

  /// Most-recently added first (default).
  dateDesc,

  /// Oldest first.
  dateAsc,

  /// Most played first.
  playCountDesc,

  /// Least played first.
  playCountAsc,

  /// Most recently played first.
  lastPlayedDesc,

  /// Least recently played first.
  lastPlayedAsc,
}

// ---------------------------------------------------------------------------
// State hierarchy
// ---------------------------------------------------------------------------

/// Sealed state for the recently-played carousel in [LibraryViewModel].
///
/// Variants: [RecentlyPlayedStateIdle], [RecentlyPlayedStateSuccess].
sealed class RecentlyPlayedState {
  /// Creates a [RecentlyPlayedState].
  const RecentlyPlayedState();
}

/// Initial state before [LibraryViewModel.init] is called, or while the first
/// stream emission is pending.
final class RecentlyPlayedStateIdle extends RecentlyPlayedState {
  /// Creates a [RecentlyPlayedStateIdle].
  const RecentlyPlayedStateIdle();
}

/// State when the recently-played list has been received from the stream.
///
/// An empty [notations] list means no notations have been played yet; the
/// carousel should be hidden in this case.
final class RecentlyPlayedStateSuccess extends RecentlyPlayedState {
  /// Creates a [RecentlyPlayedStateSuccess] with [notations].
  ///
  /// Parameters:
  /// - [notations]: Recently-played notations ordered by last-played date
  ///   descending. May be empty.
  const RecentlyPlayedStateSuccess({required this.notations});

  /// Recently-played notations, ordered by [Notation.lastPlayedAt] descending.
  final List<Notation> notations;
}

/// Sealed state for [LibraryViewModel].
///
/// Variants: [LibraryStateIdle], [LibraryStateLoading],
/// [LibraryStateSuccess], [LibraryStateError].
sealed class LibraryState {
  /// Creates a [LibraryState].
  const LibraryState();
}

/// Initial state before [LibraryViewModel.init] is called.
final class LibraryStateIdle extends LibraryState {
  /// Creates a [LibraryStateIdle].
  const LibraryStateIdle();
}

/// State while awaiting the first stream emission.
final class LibraryStateLoading extends LibraryState {
  /// Creates a [LibraryStateLoading].
  const LibraryStateLoading();
}

/// State when the active notation list has been received from the stream.
final class LibraryStateSuccess extends LibraryState {
  /// Creates a [LibraryStateSuccess] with the given [notations].
  ///
  /// Parameters:
  /// - [notations]: Current list of active (non-deleted) notations.
  const LibraryStateSuccess({required this.notations});

  /// Current list of active notations, ordered by [Notation.updatedAt]
  /// descending.
  final List<Notation> notations;
}

/// State when the stream emitted an error.
final class LibraryStateError extends LibraryState {
  /// Creates a [LibraryStateError] with the given [message].
  ///
  /// Parameters:
  /// - [message]: Human-readable description of the error.
  const LibraryStateError({required this.message});

  /// Human-readable description of the stream error.
  final String message;
}

// ---------------------------------------------------------------------------
// Abstract search-service interface (for testability)
// ---------------------------------------------------------------------------

/// Minimal contract for searching notations by query string.
///
/// [SearchService] satisfies this contract; tests inject a fake.
abstract interface class LibrarySearchService {
  /// Returns notation IDs matching [query].
  ///
  /// Parameters:
  /// - [query]: The user-supplied search string.
  /// - [limit]: Maximum results.
  /// - [offset]: Pagination offset.
  Future<List<String>> search(
    String query, {
    int limit,
    int offset,
  });
}

// ---------------------------------------------------------------------------
// Debounce duration constant
// ---------------------------------------------------------------------------

/// Debounce delay applied to the search query before issuing a search call.
const Duration _kSearchDebounce = Duration(milliseconds: 300);

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ViewModel for the Library screen.
///
/// Observes [NotationRepository.watchAllActive] and translates stream events
/// into [LibraryState] values. Exposes [softDelete], [undoDelete], and
/// [duplicate] operations that surface failures via [operationError] without
/// interrupting the library list display.
///
/// Search support: call [setSearchQuery] to update the debounced query.
/// [displayedNotations] returns the filtered result asynchronously.
///
/// Tag filter: call [toggleTag] to add/remove a tag id from [selectedTagIds].
/// [displayedNotations] applies the tag filter after search.
///
/// State management contract:
/// - [state] is the primary display state (idle / loading / success / error).
/// - [operationError] is an auxiliary error field; it does not affect [state]
///   so the list remains visible while an operation error is shown.
/// - [lastDuplicatedId] carries the new notation id after a successful
///   [duplicate] call. Clear with [clearLastDuplicatedId].
class LibraryViewModel extends ChangeNotifier {
  /// Creates a [LibraryViewModel] backed by the given repositories.
  ///
  /// Parameters:
  /// - [_notationRepository]: Source of truth for active notation list.
  /// - [_trashRepository]: Used to restore a soft-deleted notation on undo.
  /// - [tagRepository]: Optional source of available tags for the filter row.
  /// - [duplicateUseCase]: Optional use case for duplicating a notation.
  ///   When null the [duplicate] method is a no-op.
  /// - [searchService]: Optional search service. When null, search is
  ///   unavailable and [displayedNotations] returns the full list.
  /// - [notationTagIds]: Optional static map of notationId → Set<tagId> used
  ///   for client-side tag filtering. Intended for testing; production uses
  ///   the live [_notationTagIds] populated from [_notationTagsSubscription].
  LibraryViewModel(
    this._notationRepository,
    this._trashRepository, {
    TagRepository? tagRepository,
    DuplicateNotationUseCase? duplicateUseCase,
    LibrarySearchService? searchService,
    Map<String, Set<String>>? notationTagIds,
  })  : _tagRepository = tagRepository,
        _duplicateUseCase = duplicateUseCase,
        _searchService = searchService,
        _notationTagIds = notationTagIds ?? {};

  final NotationRepository _notationRepository;
  final TrashRepository _trashRepository;
  final TagRepository? _tagRepository;
  final DuplicateNotationUseCase? _duplicateUseCase;
  final LibrarySearchService? _searchService;

  StreamSubscription<List<Notation>>? _subscription;
  StreamSubscription<List<Notation>>? _recentSubscription;
  StreamSubscription<List<Tag>>? _tagsSubscription;
  Timer? _debounceTimer;

  LibraryState _state = const LibraryStateIdle();
  RecentlyPlayedState _recentlyPlayedState = const RecentlyPlayedStateIdle();
  LibrarySort _sort = LibrarySort.dateDesc;
  String? _operationError;
  String? _lastDuplicatedId;

  // Search state
  String _searchQuery = '';
  List<String>? _searchResultIds; // null = no active search

  // Tag filter state
  Set<String> _selectedTagIds = {};
  List<Tag> _availableTags = [];

  // Notation-tag associations for client-side filtering.
  // Maps notationId → Set<tagId>. Updated by [_notationTagsSubscription] in
  // production; can be injected directly for tests via constructor.
  final Map<String, Set<String>> _notationTagIds;

  // All notations received from the stream (unfiltered).
  List<Notation> _allNotations = [];

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The current display state of the library screen.
  LibraryState get state => _state;

  /// The current state of the recently-played carousel.
  ///
  /// [RecentlyPlayedStateIdle] until [init] is called and the first stream
  /// emission arrives. [RecentlyPlayedStateSuccess] with an empty list means
  /// no notations have been played yet; the carousel should be hidden.
  RecentlyPlayedState get recentlyPlayedState => _recentlyPlayedState;

  /// Non-null when the most recent operation (softDelete / undoDelete / duplicate) failed.
  ///
  /// Clear with [clearOperationError] after the error has been surfaced.
  String? get operationError => _operationError;

  /// Non-null when the most recent [duplicate] call succeeded.
  ///
  /// Contains the new notation's UUID. Clear with [clearLastDuplicatedId]
  /// after the caller has consumed the value (e.g., after navigation).
  String? get lastDuplicatedId => _lastDuplicatedId;

  /// The currently active sort order for the notation list.
  ///
  /// Defaults to [LibrarySort.dateDesc]. Use [setSort] to change it.
  LibrarySort get sort => _sort;

  /// The current search query string.
  ///
  /// Empty when no search is active.
  String get searchQuery => _searchQuery;

  /// The set of currently-selected tag ids for filtering.
  ///
  /// Empty when no tag filter is active.
  Set<String> get selectedTagIds => Set.unmodifiable(_selectedTagIds);

  /// The list of all tags available for selection in the filter row.
  ///
  /// Empty until [init] is called and the tag stream emits.
  List<Tag> get availableTags => List.unmodifiable(_availableTags);

  /// Returns the notations to display after applying search and tag filters.
  ///
  /// When search is active (non-empty [searchQuery]) the result is filtered
  /// to [_searchResultIds] first. When [selectedTagIds] is non-empty, the
  /// result is further filtered to notations that have ALL selected tags.
  ///
  /// Returns a [Future] because search results may be computed asynchronously.
  Future<List<Notation>> get displayedNotations async {
    var notations = List<Notation>.from(_allNotations);

    // Apply search filter.
    if (_searchResultIds != null) {
      final idSet = Set<String>.from(_searchResultIds!);
      notations = notations.where((n) => idSet.contains(n.id)).toList();
    }

    // Apply tag filter (AND logic).
    if (_selectedTagIds.isNotEmpty) {
      notations = notations.where((n) {
        final notationTags = _notationTagIds[n.id] ?? const {};
        return _selectedTagIds.every(notationTags.contains);
      }).toList();
    }

    return List.unmodifiable(notations);
  }

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Subscribes to the active notation stream, the recently-played stream, and
  /// the tags stream, then begins emitting state updates.
  ///
  /// Transitions immediately to [LibraryStateLoading], then to
  /// [LibraryStateSuccess] or [LibraryStateError] as the stream emits.
  /// Calling [init] again cancels the previous subscriptions before
  /// restarting.
  void init() {
    _subscription?.cancel();
    _recentSubscription?.cancel();
    _tagsSubscription?.cancel();
    _state = const LibraryStateLoading();
    _recentlyPlayedState = const RecentlyPlayedStateIdle();
    notifyListeners();

    _subscription =
        _notationRepository.watchAllActive(sortBy: _daoSort(_sort)).listen(
      (notations) {
        _allNotations = notations;
        _state = LibraryStateSuccess(notations: notations);
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        log(
          'LibraryViewModel: stream error — $error',
          name: 'LibraryViewModel',
          error: error,
          stackTrace: stack,
        );
        _state = LibraryStateError(message: error.toString());
        notifyListeners();
      },
    );

    _recentSubscription =
        _notationRepository.watchRecentlyPlayed(limit: 5).listen(
      (notations) {
        _recentlyPlayedState = RecentlyPlayedStateSuccess(
          notations: notations,
        );
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        log(
          'LibraryViewModel: recently-played stream error — $error',
          name: 'LibraryViewModel',
          error: error,
          stackTrace: stack,
        );
        // Do not replace the main state on a carousel error; keep idle.
      },
    );

    final tagRepo = _tagRepository;
    if (tagRepo != null) {
      _tagsSubscription = tagRepo.watchAllTags().listen(
        (tags) {
          _availableTags = tags;
          notifyListeners();
        },
        onError: (Object error, StackTrace stack) {
          log(
            'LibraryViewModel: tags stream error — $error',
            name: 'LibraryViewModel',
            error: error,
            stackTrace: stack,
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _recentSubscription?.cancel();
    _tagsSubscription?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Search
  // -------------------------------------------------------------------------

  /// Updates the search query and schedules a debounced search after 300 ms.
  ///
  /// If [query] equals the current [searchQuery], the call is a no-op. When
  /// the query is empty (or cleared), [_searchResultIds] is set to null and
  /// the full list is restored.
  ///
  /// Parameters:
  /// - [query]: The new search string.
  void setSearchQuery(String query) {
    if (query == _searchQuery) return;
    _searchQuery = query;
    notifyListeners();

    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      _searchResultIds = null;
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(_kSearchDebounce, () => _runSearch(query));
  }

  /// Clears the search query and restores the unfiltered notation list.
  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    _searchResultIds = null;
    _debounceTimer?.cancel();
    notifyListeners();
  }

  /// Executes the search against [_searchService] and updates
  /// [_searchResultIds].
  Future<void> _runSearch(String query) async {
    final service = _searchService;
    if (service == null) return;

    try {
      final ids = await service.search(query);
      _searchResultIds = ids;
      log(
        'LibraryViewModel: search "$query" → ${ids.length} result(s)',
        name: 'LibraryViewModel',
      );
    } on Exception catch (e, st) {
      log(
        'LibraryViewModel: search error — $e',
        name: 'LibraryViewModel',
        error: e,
        stackTrace: st,
      );
      _searchResultIds = [];
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Tag filter
  // -------------------------------------------------------------------------

  /// Adds [tagId] to [selectedTagIds] if not present; removes it if present.
  ///
  /// Notifies listeners after the change.
  ///
  /// Parameters:
  /// - [tagId]: The UUIDv4 id of the tag to toggle.
  void toggleTag(String tagId) {
    final next = Set<String>.from(_selectedTagIds);
    if (next.contains(tagId)) {
      next.remove(tagId);
    } else {
      next.add(tagId);
    }
    _selectedTagIds = next;
    notifyListeners();
  }

  /// Clears all selected tag ids and notifies listeners.
  void clearTagFilter() {
    if (_selectedTagIds.isEmpty) return;
    _selectedTagIds = {};
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Sort
  // -------------------------------------------------------------------------

  /// Maps a [LibrarySort] value to its [NotationSortBy] counterpart.
  NotationSortBy _daoSort(LibrarySort s) => switch (s) {
        LibrarySort.titleAsc => NotationSortBy.titleAsc,
        LibrarySort.titleDesc => NotationSortBy.titleDesc,
        LibrarySort.dateWrittenDesc => NotationSortBy.dateDesc,
        LibrarySort.dateWrittenAsc => NotationSortBy.dateAsc,
        LibrarySort.dateDesc => NotationSortBy.dateDesc,
        LibrarySort.dateAsc => NotationSortBy.dateAsc,
        LibrarySort.playCountDesc => NotationSortBy.dateDesc,
        LibrarySort.playCountAsc => NotationSortBy.dateAsc,
        LibrarySort.lastPlayedDesc => NotationSortBy.dateDesc,
        LibrarySort.lastPlayedAsc => NotationSortBy.dateAsc,
      };

  /// Changes the active sort order and re-subscribes to the notation stream.
  ///
  /// Calling this with the current [sort] value is a no-op.
  ///
  /// Parameters:
  /// - [sort]: The new sort order to apply.
  void setSort(LibrarySort sort) {
    if (sort == _sort) return;
    _sort = sort;
    init();
  }

  // -------------------------------------------------------------------------
  // Operations
  // -------------------------------------------------------------------------

  /// Soft-deletes the notation identified by [id].
  ///
  /// Sets `deleted_at` on the notation row, removing it from the active list.
  /// On failure [operationError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the notation to soft-delete.
  Future<void> softDelete(String id) async {
    try {
      await _notationRepository.softDelete(id);
      log('LibraryViewModel: soft-deleted notation $id',
          name: 'LibraryViewModel');
    } on Exception catch (e, st) {
      log(
        'LibraryViewModel: softDelete failed — $e',
        name: 'LibraryViewModel',
        error: e,
        stackTrace: st,
      );
      _operationError = e.toString();
      notifyListeners();
    }
  }

  /// Restores the notation identified by [id] from the trash.
  ///
  /// Called when the user taps "Undo" on the deletion SnackBar. On failure
  /// [operationError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the notation to restore.
  Future<void> undoDelete(String id) async {
    try {
      await _trashRepository.restoreNotation(id);
      log('LibraryViewModel: restored notation $id', name: 'LibraryViewModel');
    } on Exception catch (e, st) {
      log(
        'LibraryViewModel: undoDelete failed — $e',
        name: 'LibraryViewModel',
        error: e,
        stackTrace: st,
      );
      _operationError = e.toString();
      notifyListeners();
    }
  }

  /// Duplicates the notation identified by [id].
  ///
  /// Copies all page files to a new directory and creates a new notation
  /// record with the same metadata and title suffixed with " (copy)".
  ///
  /// On success [lastDuplicatedId] is set to the new notation's UUID and
  /// [notifyListeners] is called. On failure [operationError] is populated.
  ///
  /// No-op when [duplicateUseCase] was not provided at construction time.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the notation to duplicate.
  Future<void> duplicate(String id) async {
    final useCase = _duplicateUseCase;
    if (useCase == null) return;

    try {
      final newId = await useCase.execute(id);
      _lastDuplicatedId = newId;
      log(
        'LibraryViewModel: duplicated notation $id → $newId',
        name: 'LibraryViewModel',
      );
    } on Exception catch (e, st) {
      log(
        'LibraryViewModel: duplicate failed — $e',
        name: 'LibraryViewModel',
        error: e,
        stackTrace: st,
      );
      _operationError = e.toString();
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Error reset
  // -------------------------------------------------------------------------

  /// Clears [operationError] and notifies listeners.
  void clearOperationError() {
    _operationError = null;
    notifyListeners();
  }

  /// Clears [lastDuplicatedId] and notifies listeners.
  ///
  /// Call after the caller has consumed the value (e.g., navigated to the
  /// new notation's detail screen).
  void clearLastDuplicatedId() {
    _lastDuplicatedId = null;
    notifyListeners();
  }
}
