// ==============================================================================
// Resume Doctor — Node.js / Express Backend Proxy Server
// ==============================================================================
const http = require('http');
const fs = require('fs');
const path = require('path');
const https = require('https');

const PORT = process.env.PORT || 8080;
const BASE_DIR = __dirname;

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.txt': 'text/plain; charset=utf-8',
  '.md': 'text/plain; charset=utf-8',
  '.zip': 'application/zip'
};

function sendJson(res, statusCode, obj) {
  const json = JSON.stringify(obj);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, x-gemini-api-key, Authorization'
  });
  res.end(json);
}

const server = http.createServer((req, res) => {
  // CORS Headers for all requests
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-gemini-api-key, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    return res.end();
  }

  const url = new URL(req.url, `http://${req.headers.host}`);

  // ----------------------------------------------------------------------------
  // Backend Proxy: POST /api/analyze
  // ----------------------------------------------------------------------------
  if (url.pathname === '/api/analyze' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let parsed;
      try {
        parsed = JSON.parse(body);
      } catch (err) {
        return sendJson(res, 400, { error: 'Invalid JSON request payload.' });
      }

      const apiKey = req.headers['x-gemini-api-key'] || process.env.GEMINI_API_KEY;
      if (!apiKey || !apiKey.trim()) {
        return sendJson(res, 400, {
          error: 'No API key provided. Set GEMINI_API_KEY in environment or provide in Settings.'
        });
      }

      const model = parsed.model || 'gemini-2.0-flash';
      const prompt = parsed.prompt;
      if (!prompt) {
        return sendJson(res, 400, { error: 'Missing prompt in request payload.' });
      }

      const parts = [];
      if (parsed.imageBase64) {
        parts.push({
          inlineData: {
            mimeType: parsed.imageMime || 'image/jpeg',
            data: parsed.imageBase64
          }
        });
      }
      parts.push({ text: prompt });

      const genConfig = { temperature: 0.2 };
      if (model.startsWith('gemini')) {
        genConfig.responseMimeType = 'application/json';
      }

      const payload = JSON.stringify({
        contents: [{ parts }],
        generationConfig: genConfig
      });

      const endpoint = `/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey.trim())}`;
      const options = {
        hostname: 'generativelanguage.googleapis.com',
        port: 443,
        path: endpoint,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(payload)
        },
        timeout: 45000
      };

      const proxyReq = https.request(options, (proxyRes) => {
        let respData = '';
        proxyRes.on('data', chunk => { respData += chunk; });
        proxyRes.on('end', () => {
          try {
            const data = JSON.parse(respData);
            if (proxyRes.statusCode >= 400) {
              const msg = data.error?.message || `HTTP ${proxyRes.statusCode}`;
              return sendJson(res, proxyRes.statusCode, { error: msg, statusCode: proxyRes.statusCode });
            }

            const candidate = data.candidates?.[0]?.content?.parts?.[0]?.text;
            return sendJson(res, 200, {
              success: true,
              model: model,
              rawText: candidate
            });
          } catch (e) {
            return sendJson(res, 500, { error: 'Failed to parse Gemini API response: ' + e.message });
          }
        });
      });

      proxyReq.on('timeout', () => {
        proxyReq.destroy();
        return sendJson(res, 504, { error: 'Gemini API call timed out after 45 seconds.' });
      });

      proxyReq.on('error', (err) => {
        return sendJson(res, 500, { error: 'Network error communicating with Google AI: ' + err.message });
      });

      proxyReq.write(payload);
      proxyReq.end();
    });
    return;
  }

  // ----------------------------------------------------------------------------
  // Static Files
  // ----------------------------------------------------------------------------
  let reqPath = url.pathname === '/' ? '/index.html' : url.pathname;
  let safePath = path.normalize(path.join(BASE_DIR, reqPath));

  if (!safePath.startsWith(BASE_DIR)) {
    res.writeHead(403);
    return res.end('Access Denied');
  }

  fs.stat(safePath, (err, stats) => {
    if (err || !stats.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      return res.end('File Not Found');
    }

    const ext = path.extname(safePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    res.writeHead(200, { 'Content-Type': contentType });
    const stream = fs.createReadStream(safePath);
    stream.pipe(res);
  });
});

server.listen(PORT, () => {
  console.log(`Resume Doctor Server running at http://localhost:${PORT}/`);
});
