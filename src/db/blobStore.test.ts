import { afterEach, describe, expect, it } from 'vitest';

import { db } from './db';
import { deleteBlob, getBlob, putBlob } from './blobStore';

afterEach(async () => {
  await db.blobs.clear();
});

describe('blobStore', () => {
  it('round-trips a blob through put and get', async () => {
    const blob = new Blob(['page one'], { type: 'image/jpeg' });

    await putBlob('notations/abc/page_1.jpg', blob);
    const stored = await getBlob('notations/abc/page_1.jpg');

    expect(stored).toBeDefined();
    expect(await stored?.text()).toBe('page one');
  });

  it('returns undefined for a path that was never written', async () => {
    const stored = await getBlob('does/not/exist.jpg');
    expect(stored).toBeUndefined();
  });

  it('removes a blob on delete', async () => {
    await putBlob('notations/abc/page_1.jpg', new Blob(['x']));
    await deleteBlob('notations/abc/page_1.jpg');

    expect(await getBlob('notations/abc/page_1.jpg')).toBeUndefined();
  });
});
