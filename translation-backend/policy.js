export const MONTHLY_LIMIT = 450_000;
export function validateRequest(body) {
  if (!body || !['en', 'hi'].includes(body.target) || !Array.isArray(body.texts) ||
      body.texts.length < 1 || body.texts.length > 50 ||
      body.texts.some(text => typeof text !== 'string' || !text.trim())) {
    throw new Error('Send 1–50 nonempty texts and target en or hi.');
  }
  const characters = body.texts.reduce((sum, text) => sum + Array.from(text).length, 0);
  if (characters > 5000) throw new Error('Maximum 5000 characters per request.');
  return characters;
}
export function monthKey(date = new Date()) {
  // Use the billing calendar timezone, rather than the phone's timezone.
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Los_Angeles', year: 'numeric', month: '2-digit'
  }).formatToParts(date);
  return `${parts.find(part => part.type === 'year').value}-${parts.find(part => part.type === 'month').value}`;
}
