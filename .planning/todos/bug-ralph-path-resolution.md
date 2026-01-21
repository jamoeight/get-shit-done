# Bug: ralph.sh not found when spawning new terminal

## Priority: High

## Description

Path resolution issue with ralph.sh when terminal-launcher spawns a new terminal window.

**Symptoms:**
- Running ralph.sh directly in gitbash works
- When ralph.sh tries to spawn a Claude instance in a new terminal, get "ralph.sh not found" error
- Suggests the path passed to the spawned terminal isn't resolving correctly

**Likely cause:**
The terminal launcher is passing a path that works in the current shell context but doesn't resolve in the freshly spawned terminal (different working directory, no $HOME expansion, or relative path issue).

## To investigate

1. Check how `terminal-launcher.js` constructs the ralph.sh path
2. Check if it's using `$HOME` expansion vs absolute path
3. Test on Windows Terminal, PowerShell, cmd.exe
4. May need to pass fully resolved absolute path to spawned terminal

## Related files

- `bin/lib/terminal-launcher.js`
- `bin/ralph.sh`

---
*Created: 2026-01-21*
