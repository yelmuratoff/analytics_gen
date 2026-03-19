#!/usr/bin/env node
/**
 * Fixes self-referencing meta-refresh redirects in dartdoc topic pages.
 * Dartdoc generates stub HTML files that redirect to themselves when the
 * canonical URL matches the filename. This script detects and removes
 * the meta-refresh tag from such files, replacing the stub with a proper
 * redirect to the index page or leaving the link as a clickable fallback.
 */
import { readdirSync, readFileSync, writeFileSync } from 'fs';
import { join, basename } from 'path';

const docsDir = join(process.cwd(), 'public', 'docs');
const topicsDir = join(docsDir, 'topics');

let fixed = 0;

try {
  const files = readdirSync(topicsDir).filter(f => f.endsWith('.html'));

  for (const file of files) {
    const filePath = join(topicsDir, file);
    const content = readFileSync(filePath, 'utf-8');

    // Only process small redirect stubs (< 500 bytes)
    if (content.length > 500) continue;

    // Check if it has a meta refresh (dartdoc uses &#47; for /)
    const refreshMatch = content.match(/url=\.\.(?:\/|&#47;)topics(?:\/|&#47;)([^"]+)/);
    if (!refreshMatch) continue;

    const targetFile = refreshMatch[1];
    const currentFile = basename(filePath);

    // Self-referencing redirect — replace with redirect to index
    if (decodeURIComponent(targetFile) === currentFile || targetFile === currentFile) {
      const title = currentFile.replace(/-topic\.html$/, '').replace(/[_-]/g, ' ');
      writeFileSync(filePath, `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="0; url=../index.html">
  <title>${title}</title>
</head>
<body>
  <p>Redirecting to <a href="../index.html">documentation index</a>...</p>
</body>
</html>`);
      fixed++;
      console.log(`  Fixed self-redirect: ${file} → index.html`);
    }
    // Valid redirect to different file — leave as is
  }

  console.log(`✓ Fixed ${fixed} self-referencing redirect(s)`);
} catch (err) {
  // topics dir may not exist — that's fine
  if (err.code !== 'ENOENT') throw err;
  console.log('⚠ No topics directory found, skipping redirect fix');
}
