import Dexie, { type Table } from 'dexie';

import type {
  CustomFieldDefinition,
  InstrumentClass,
  InstrumentInstance,
  Notation,
  NotationPage,
  StoredBlob,
  Tag,
  UserPreferences,
} from './types';

/** IndexedDB schema. See docs/data-model.md for the SQLite-to-Dexie mapping. */
export class SwaralipiDB extends Dexie {
  notations!: Table<Notation, string>;
  notationPages!: Table<NotationPage, string>;
  tags!: Table<Tag, string>;
  instrumentClasses!: Table<InstrumentClass, string>;
  instrumentInstances!: Table<InstrumentInstance, string>;
  customFieldDefs!: Table<CustomFieldDefinition, string>;
  blobs!: Table<StoredBlob, string>;
  preferences!: Table<UserPreferences, number>;

  constructor() {
    super('swaralipi');
    this.version(1).stores({
      notations:
        'id, title, dateWritten, createdAt, updatedAt, deletedAt, ' +
        'playCount, lastPlayedAt, *tagIds, *artists, *languages',
      notationPages: 'id, notationId, [notationId+pageOrder]',
      tags: 'id, &name',
      instrumentClasses: 'id, &name',
      instrumentInstances: 'id, classId, deletedAt',
      customFieldDefs: 'id, &keyName',
      blobs: 'path',
      preferences: 'id',
    });
  }
}

export const db = new SwaralipiDB();
