// Dev server with save endpoint for the slide presentation.
// Usage: node server.js [port]
// Serves static files and accepts POST /save to write the HTML back to disk.

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = parseInt(process.argv[2] || '8080', 10);
const ROOT = __dirname;
const SLIDE_FILE = path.join(ROOT, 'the-future-of-ruby-documentation.html');

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2',
  '.pdf': 'application/pdf',
};

const server = http.createServer((req, res) => {
  // Save endpoint — writes the POST body to the slide file
  if (req.method === 'POST' && req.url === '/save') {
    const chunks = [];
    req.on('data', chunk => chunks.push(chunk));
    req.on('end', () => {
      try {
        fs.writeFileSync(SLIDE_FILE, Buffer.concat(chunks));
        res.writeHead(200, {
          'Content-Type': 'text/plain',
          'Access-Control-Allow-Origin': '*',
        });
        res.end('saved');
        console.log(`[${new Date().toLocaleTimeString()}] Saved ${path.basename(SLIDE_FILE)}`);
      } catch (err) {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Error: ' + err.message);
        console.error('Save failed:', err.message);
      }
    });
    return;
  }

  // Static file serving
  const urlPath = decodeURIComponent(req.url.split('?')[0]);
  let filePath = path.join(ROOT, urlPath === '/' ? 'the-future-of-ruby-documentation.html' : urlPath);
  filePath = path.normalize(filePath);

  // Prevent directory traversal
  if (!filePath.startsWith(ROOT)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Not found: ' + urlPath);
      return;
    }
    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
    res.end(data);
  });
});

server.listen(PORT, () => {
  console.log(`Dev server running at http://localhost:${PORT}`);
  console.log(`Serving: ${ROOT}`);
  console.log(`Save target: ${path.basename(SLIDE_FILE)}`);
  console.log(`Press Ctrl+C to stop\n`);
});
