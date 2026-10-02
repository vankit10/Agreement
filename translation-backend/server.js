import http from 'node:http';
import { timingSafeEqual } from 'node:crypto';
import { Firestore } from '@google-cloud/firestore';
import { GoogleAuth } from 'google-auth-library';
import { MONTHLY_LIMIT, validateRequest, monthKey } from './policy.js';

const project = process.env.GOOGLE_CLOUD_PROJECT;
const token = process.env.APP_TOKEN;
if (!project || !token || token.length < 32) throw new Error('Project and a strong APP_TOKEN are required.');
const db = new Firestore({ projectId: project });
const auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/cloud-translation'] });
function authorized(header = '') {
  const supplied = Buffer.from(header);
  const expected = Buffer.from(`Bearer ${token}`);
  return supplied.length === expected.length && timingSafeEqual(supplied, expected);
}
function respond(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
  res.end(JSON.stringify(body));
}

http.createServer(async (req, res) => {
  if (req.method === 'GET' && req.url === '/health') return respond(res, 200, { status: 'ok' });
  if (req.method !== 'POST' || req.url !== '/translate') return respond(res, 404, { error: 'Not found' });
  if (!authorized(req.headers.authorization)) return respond(res, 401, { error: 'Unauthorized' });
  try {
    let raw = ''; let bytes = 0;
    for await (const chunk of req) {
      bytes += chunk.length;
      if (bytes > 65536) return respond(res, 413, { error: 'Request too large' });
      raw += chunk.toString('utf8');
    }
    let body, characters;
    try { body = JSON.parse(raw); characters = validateRequest(body); }
    catch (error) { return respond(res, 400, { error: error.message }); }
    const usage = db.collection('translationUsage').doc(monthKey());
    // Reserve before calling Google, in a transaction shared by every device.
    // Failed calls retain their reservation to avoid undercounting uncertain calls.
    const allowed = await db.runTransaction(async transaction => {
      const snapshot = await transaction.get(usage);
      const used = snapshot.exists ? snapshot.data().characters || 0 : 0;
      if (used + characters > MONTHLY_LIMIT) return false;
      transaction.set(usage, { characters: used + characters, limit: MONTHLY_LIMIT });
      return true;
    });
    if (!allowed) return respond(res, 429, { error: 'Monthly free-use limit reached. Saved translations remain available.' });
    const client = await auth.getClient();
    const result = await client.request({
      url: `https://translation.googleapis.com/v3/projects/${project}/locations/global:translateText`,
      method: 'POST', timeout: 20000,
      data: { contents: body.texts, targetLanguageCode: body.target, mimeType: 'text/plain' }
    });
    const translations = result.data.translations;
    if (!Array.isArray(translations) || translations.length !== body.texts.length) throw new Error('Invalid translation response');
    respond(res, 200, { texts: translations.map(item => item.translatedText) });
  } catch {
    // Do not log client agreement content, credentials, or provider responses.
    respond(res, 503, { error: 'Translation unavailable. Please try again later.' });
  }
}).listen(process.env.PORT || 8080);
