# fix-claude-code-vscode-wsl

This patch script fixes the issue where the Claude Code for VS Code extension fails to stream output correctly in the WSL environment.

**Reload target VS Code instance(s) for the patch to take effect.**

Re-run is required after every update until this problem is officially fixed.

## Why this happens

The extension's `spawnClaude` method sets `includePartialMessages:!<var>.env.remoteName` (the minified variable name varies per build, e.g. `G4`, `O0`). In WSL2, `.env.remoteName` evaluates to `"wsl"` (truthy), so the expression becomes `false`, and `--include-partial-messages` is never passed to the Claude CLI process. Without that flag, the CLI only emits complete assistant content blocks — no incremental `content_block_delta` events reach the webview, so all text appears at once.

The data path in normal operation is: Claude CLI stdout (`stream-json`) → extension host pipe → `QK` line-delimited JSON decoder → `kO` async iterator → `for await` loop in `launchClaude` → `webview.postMessage({type:"from-extension"})` → webview `readMessages` → `processStreamEvent` handles `content_block_delta` events for incremental rendering. The single flag `--include-partial-messages` controls whether the first step produces deltas or only complete blocks.

---

## Credits and Notes

 - The analysis and solution was completed by `DeepSeek V4 Pro` in the `Claude Code environment`.
 - AI's Methodology: extracted the minified extension.js from `.vscode-server/extensions/`, traced the `spawnClaude` → `spawnLocalProcess` → CLI flag assembly chain via grep/context extraction, and cross-checked with live process args from `ps`.
