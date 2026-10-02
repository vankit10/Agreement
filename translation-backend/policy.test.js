import test from 'node:test';
import assert from 'node:assert/strict';
import { validateRequest, MONTHLY_LIMIT, monthKey } from './policy.js';
test('counts Unicode code points rather than UTF-16 units', () => {
  assert.equal(validateRequest({ texts: ['house 🏠', 'घर'], target: 'hi' }), 9);
});
test('rejects invalid languages, empty strings, and oversized requests', () => {
  for (const body of [{ texts: ['house'], target: 'fr' }, { texts: [' '], target: 'en' }, { texts: ['x'.repeat(5001)], target: 'hi' }]) {
    assert.throws(() => validateRequest(body));
  }
  assert.equal(MONTHLY_LIMIT, 450000);
});
test('uses Pacific month boundary', () => {
  assert.equal(monthKey(new Date('2026-10-01T00:30:00Z')), '2026-09');
});
