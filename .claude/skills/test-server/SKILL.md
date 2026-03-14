---
name: test-server
description: E2E testing workflow for the RDoc live-reload server (rdoc --server)
---

# Test Server

End-to-end testing workflow for the RDoc live-reload server. Use after modifying server code, templates, generators, or routing.

## Steps

### 1. Start the server

```bash
bundle exec rdoc --server &
SERVER_PID=$!
sleep 2  # wait for TCP server to bind
```

Or on a custom port:

```bash
bundle exec rdoc --server=8080 &
```

Default port is 4000.

### 2. Verify core endpoints

Run these curl checks against the running server:

```bash
# Root → 200, HTML index page
curl -s -o /dev/null -w '%{http_code}' http://localhost:4000/
# Expected: 200

# Status endpoint → 200, JSON with last_change float
curl -s http://localhost:4000/__status
# Expected: {"last_change":1234567890.123}

# Class page → 200, HTML with live-reload script
curl -s http://localhost:4000/RDoc.html | head -5
# Expected: HTML containing class documentation

# CSS asset → 200, stylesheet
curl -s -o /dev/null -w '%{http_code}' http://localhost:4000/css/rdoc.css
# Expected: 200

# JS search index → 200, search data
curl -s -o /dev/null -w '%{http_code}' http://localhost:4000/js/search_data.js
# Expected: 200

# Missing page → 404, still has live-reload script
curl -s -w '\n%{http_code}' http://localhost:4000/Missing.html | tail -1
# Expected: 404

# Path traversal via asset route → 404 (blocked by expand_path check)
curl -s -o /dev/null -w '%{http_code}' 'http://localhost:4000/css/../../etc/passwd'
# Expected: 404
```

### 3. Verify live-reload

HTML pages should contain the live-reload polling script:

```bash
# Check for live-reload script in a class page
curl -s http://localhost:4000/RDoc.html | grep 'var lastChange'
# Expected: var lastChange = <float>;

# Check that 404 pages also get live-reload
curl -s http://localhost:4000/Missing.html | grep 'var lastChange'
# Expected: var lastChange = <float>;
```

The script polls `/__status` and reloads when `data.last_change > lastChange`.

### 4. Verify file change detection

Confirm the server detects source file changes and invalidates its cache:

```bash
# Record the current last_change timestamp
BEFORE=$(curl -s http://localhost:4000/__status | grep -o '"last_change":[0-9.]*' | cut -d: -f2)

# Touch a source file to trigger the file watcher
touch lib/rdoc.rb
sleep 2  # watcher polls every 1 second

# Check that last_change has advanced
AFTER=$(curl -s http://localhost:4000/__status | grep -o '"last_change":[0-9.]*' | cut -d: -f2)
echo "before=$BEFORE after=$AFTER"
# Expected: AFTER > BEFORE
```

### 5. (Optional) Visual testing with Playwright CLI

For visual inspection of rendered pages, use Playwright CLI commands directly:

```bash
# Install browsers (one-time)
npx playwright install chromium

# Take a screenshot of the index page
npx playwright screenshot http://localhost:4000/ /tmp/rdoc-index.png

# Take a screenshot of a specific class page
npx playwright screenshot http://localhost:4000/RDoc.html /tmp/rdoc-class.png

# Full-page screenshot
npx playwright screenshot --full-page http://localhost:4000/RDoc.html /tmp/rdoc-full.png
```

Review the screenshots to verify layout, styling, and content rendering.

### 6. Stop the server

```bash
kill $SERVER_PID 2>/dev/null
```
