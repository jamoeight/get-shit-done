# Phase 11: Terminal Launcher - Research

**Researched:** 2026-01-20
**Domain:** Cross-platform terminal window launching for process isolation
**Confidence:** MEDIUM

## Summary

Phase 11 implements terminal launching for the autopilot command to run ralph.sh in a separate terminal window for execution isolation. This enables the "fire and forget" pattern where users can close their Claude session while ralph.sh continues running independently.

The primary challenge is handling cross-platform terminal detection and launching across Windows (cmd/PowerShell/Git Bash/Windows Terminal), macOS (Terminal.app), and Linux (gnome-terminal/xterm/x-terminal-emulator). Each platform has different terminal emulators and launch mechanisms.

Research reveals that:
- **Windows**: Use `start` command with cmd.exe or PowerShell, or `wt.exe` for Windows Terminal
- **macOS**: Use `open -a Terminal` or AppleScript via `osascript` for Terminal.app
- **Linux**: Use `gnome-terminal`, `xterm`, or `x-terminal-emulator` with `--` flag for command execution
- **Node.js**: Use `child_process.spawn()` with `detached: true`, `stdio: 'ignore'`, and `subprocess.unref()` for true process independence

The key architectural decision is whether to build custom platform detection in Node.js or use existing npm packages. Given the maturity of the ecosystem and the need for reliability, a hybrid approach is recommended: use `command-exists` for detection, build custom spawning logic with platform-specific commands.

**Primary recommendation:** Build a Node.js module (bin/lib/terminal-launcher.js) that detects platform, probes for available terminals, launches ralph.sh in a new window using platform-specific commands, and falls back to manual instructions if detection fails. This should be called from the autopilot.md command.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Node.js child_process | Built-in | Process spawning | Native module, no dependencies |
| command-exists | 1.2.9 | Check if command exists in PATH | Industry standard, 1,833+ dependents |
| process.platform | Built-in | Platform detection | Native Node.js API |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| cross-spawn | 7.0.6 | Cross-platform spawn | If shell differences cause issues (10,422+ dependents) |
| which | Latest | Find executable in PATH | Alternative to command-exists |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| command-exists | which package | 'which' is more actively maintained but heavier dependency |
| Custom detection | open-terminal (npm) | Package is 5 years old, unmaintained (last update 2019) |
| Node.js spawn | ttab (macOS only) | ttab requires npm install globally, only works on macOS/Linux |
| Custom solution | open package (sindresorhus) | 'open' is for files/URLs, not terminal windows with commands |

**Installation:**
```bash
npm install command-exists --save
```

## Architecture Patterns

### Recommended Project Structure
```
bin/
├── lib/
│   └── terminal-launcher.js    # Cross-platform terminal launcher
└── ralph.sh                     # Outer loop script
commands/
└── gsd/
    └── autopilot.md             # Calls terminal-launcher.js
```

### Pattern 1: Platform Detection
**What:** Detect operating system and available terminal emulators
**When to use:** At startup before attempting to launch terminal

**Example:**
```javascript
// Source: Node.js official docs - process.platform
const platform = process.platform;

// Returns: 'win32' (Windows), 'darwin' (macOS), 'linux' (Linux)
const terminalConfig = {
  win32: ['wt.exe', 'cmd.exe', 'powershell.exe', 'bash.exe'],
  darwin: ['Terminal.app'],
  linux: ['gnome-terminal', 'xterm', 'x-terminal-emulator']
};

const candidateTerminals = terminalConfig[platform] || [];
```

### Pattern 2: Terminal Existence Checking
**What:** Check if a terminal emulator is available before attempting to launch
**When to use:** For each candidate terminal in priority order

**Example:**
```javascript
// Using command-exists package
const commandExists = require('command-exists').sync;

function findAvailableTerminal(candidates) {
  for (const terminal of candidates) {
    try {
      if (commandExists(terminal)) {
        return terminal;
      }
    } catch (err) {
      continue;
    }
  }
  return null;
}
```

### Pattern 3: Detached Process Spawning
**What:** Spawn terminal as detached process that continues after parent exits
**When to use:** When launching ralph.sh in new terminal window

**Example:**
```javascript
// Source: Node.js official docs - child_process
const { spawn } = require('child_process');
const path = require('path');

function launchDetached(command, args) {
  const subprocess = spawn(command, args, {
    detached: true,      // Create new process group
    stdio: 'ignore',     // Don't attach to parent's stdio
    cwd: process.cwd()   // Use current working directory
  });

  subprocess.unref();    // Allow parent to exit independently

  return subprocess.pid;
}
```

### Pattern 4: Platform-Specific Launch Commands

**Windows (cmd.exe):**
```javascript
// Start new cmd window running ralph.sh
const args = ['/c', 'start', 'cmd', '/k', 'bash bin/ralph.sh'];
launchDetached('cmd.exe', args);
```

**Windows (PowerShell):**
```javascript
// Start new PowerShell window
const args = ['-Command', 'Start-Process', 'powershell', '-ArgumentList', '"-NoExit", "-File", ".\\bin\\ralph.sh"'];
launchDetached('powershell.exe', args);
```

**Windows (Git Bash):**
```javascript
// Launch Git Bash in new window
const args = ['/c', 'start', '""', 'bash', '--login', '-i', '-c', 'cd /c/path && ./bin/ralph.sh'];
launchDetached('cmd.exe', args);
```

**Windows (Windows Terminal):**
```javascript
// Source: Microsoft docs - Windows Terminal command line
// Launch new wt.exe window
// NOTE: KB5050021 (Jan 2025) has known issues with wt.exe programmatic launch
const args = ['--title', 'GSD Ralph', 'bash', './bin/ralph.sh'];
launchDetached('wt.exe', args);
```

**macOS (Terminal.app):**
```javascript
// Source: ttab GitHub - macOS terminal launching via osascript
// Use osascript to control Terminal.app via AppleScript
const script = `tell application "Terminal"
    do script "cd ${process.cwd()} && ./bin/ralph.sh"
    activate
end tell`;

const args = ['-e', script];
launchDetached('osascript', args);
```

**Linux (gnome-terminal):**
```javascript
// Source: gnome-terminal man page
// Launch new window with command
const args = ['--window', '--title=GSD Ralph', '--', 'bash', '-c',
              `cd ${process.cwd()} && ./bin/ralph.sh; exec bash`];
launchDetached('gnome-terminal', args);
```

**Linux (xterm):**
```javascript
// Source: xterm man page
// Launch xterm with command
const args = ['-hold', '-e', `cd ${process.cwd()} && ./bin/ralph.sh`];
launchDetached('xterm', args);
```

### Pattern 5: Fallback to Manual Instructions
**What:** Display manual run instructions when terminal detection fails
**When to use:** When no supported terminal is found or launch fails

**Example:**
```javascript
function displayManualInstructions(platform) {
  console.log('\n========================================');
  console.log('TERMINAL LAUNCH FAILED');
  console.log('========================================\n');
  console.log('Could not detect a supported terminal emulator.\n');
  console.log('To run autopilot manually, open a new terminal and run:\n');

  if (platform === 'win32') {
    console.log('  cd ' + process.cwd());
    console.log('  bash bin/ralph.sh\n');
    console.log('Supported terminals: Windows Terminal, cmd, PowerShell, Git Bash');
  } else if (platform === 'darwin') {
    console.log('  cd ' + process.cwd());
    console.log('  ./bin/ralph.sh\n');
    console.log('Supported terminals: Terminal.app');
  } else {
    console.log('  cd ' + process.cwd());
    console.log('  ./bin/ralph.sh\n');
    console.log('Supported terminals: gnome-terminal, xterm, x-terminal-emulator');
  }

  console.log('========================================\n');
}
```

### Anti-Patterns to Avoid

- **Using shell: true without detached:** Creates shell but doesn't detach properly
- **Not calling subprocess.unref():** Parent process waits for child to exit
- **Forgetting stdio: 'ignore':** On Unix, child stays attached to parent's terminal
- **Hardcoding terminal paths:** Use command-exists to find in PATH, not C:\Windows\System32\cmd.exe
- **Not handling spaces in paths:** Windows paths with spaces need proper quoting
- **Assuming wt.exe works:** Windows Terminal has known issues (KB5050021 Jan 2025)

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Command existence checking | grep/which shell commands | command-exists npm package | Cross-platform (handles Windows where, Unix which, PowerShell Get-Command) |
| Process spawning cross-platform | Custom spawn wrapper | Node.js child_process.spawn + options | Native, well-tested, handles platform quirks |
| Shell escaping | String concatenation | spawn with args array | Prevents injection, handles quoting automatically |
| Platform detection | Parsing uname output | process.platform | Native, synchronous, reliable |

**Key insight:** Terminal launching is platform-specific by nature, but the primitives (platform detection, command existence, process spawning) are solved problems. Don't reinvent these - build on tested foundations.

## Common Pitfalls

### Pitfall 1: Windows Shell Differences
**What goes wrong:** Command works in cmd but not PowerShell, or vice versa
**Why it happens:** cmd and PowerShell have different syntax for arguments, escaping, and process spawning
**How to avoid:** Test on both cmd and PowerShell; prefer cmd with start command for simplicity
**Warning signs:** Works on developer machine (PowerShell) but fails for users (cmd)

### Pitfall 2: Process Not Truly Detached
**What goes wrong:** Terminal window closes when parent process exits
**Why it happens:** Missing one of the three requirements: detached: true, stdio: 'ignore', subprocess.unref()
**How to avoid:** Always use all three options together - they work as a set
**Warning signs:** Child process visible in ps but exits when Claude session ends

### Pitfall 3: Working Directory Not Set
**What goes wrong:** ralph.sh can't find files, relative paths broken
**Why it happens:** Spawned process inherits wrong cwd or no cwd set
**How to avoid:** Always set cwd: process.cwd() in spawn options, or cd in command
**Warning signs:** ralph.sh fails with "file not found" errors

### Pitfall 4: Terminal Emulator Priority
**What goes wrong:** Using outdated or buggy terminal instead of better one
**Why it happens:** Checking terminals alphabetically instead of by preference
**How to avoid:** Order candidates by quality/stability - Windows Terminal > PowerShell > cmd > Git Bash
**Warning signs:** Using cmd when Windows Terminal is available

### Pitfall 5: No Fallback Path
**What goes wrong:** Autopilot fails completely when terminal detection fails
**Why it happens:** Assuming terminal will always be detected
**How to avoid:** Always provide manual instructions as fallback (EXEC-03 requirement)
**Warning signs:** Autopilot exits with error instead of showing instructions

### Pitfall 6: PATH Environment Issues
**What goes wrong:** Terminal exists but command-exists returns false
**Why it happens:** PATH not inherited properly in spawned process, or command is aliased
**How to avoid:** Check common install locations as fallback; use full paths where possible
**Warning signs:** Manual launch works but automated detection fails

### Pitfall 7: Bash Script in New Terminal (Windows)
**What goes wrong:** ralph.sh is a bash script but Windows terminal is cmd/PowerShell
**Why it happens:** Assuming .sh files are executable on Windows
**How to avoid:** Always prefix with bash command: `bash bin/ralph.sh`, not `bin/ralph.sh`
**Warning signs:** "not recognized as internal or external command" on Windows

## Code Examples

Verified patterns from research:

### Complete Terminal Launcher Module
```javascript
// bin/lib/terminal-launcher.js
const { spawn } = require('child_process');
const commandExists = require('command-exists').sync;
const path = require('path');

// Platform-specific terminal configurations
const TERMINAL_CONFIG = {
  win32: [
    { name: 'wt.exe', launcher: launchWindowsTerminal },
    { name: 'cmd.exe', launcher: launchCmd },
    { name: 'powershell.exe', launcher: launchPowerShell },
    { name: 'bash.exe', launcher: launchGitBash }
  ],
  darwin: [
    { name: 'osascript', launcher: launchMacTerminal }
  ],
  linux: [
    { name: 'gnome-terminal', launcher: launchGnomeTerminal },
    { name: 'xterm', launcher: launchXterm },
    { name: 'x-terminal-emulator', launcher: launchXtermEmulator }
  ]
};

function findTerminal(platform) {
  const terminals = TERMINAL_CONFIG[platform] || [];

  for (const terminal of terminals) {
    try {
      if (commandExists(terminal.name)) {
        return terminal;
      }
    } catch (err) {
      continue;
    }
  }

  return null;
}

function launchCmd() {
  const cwd = process.cwd();
  const script = path.join(cwd, 'bin', 'ralph.sh');

  return spawn('cmd.exe', ['/c', 'start', 'cmd', '/k', `bash "${script}"`], {
    detached: true,
    stdio: 'ignore',
    cwd: cwd
  });
}

function launchPowerShell() {
  const cwd = process.cwd();
  const script = path.join(cwd, 'bin', 'ralph.sh');

  return spawn('powershell.exe', [
    '-Command', 'Start-Process', 'powershell',
    '-ArgumentList', `"-NoExit", "-Command", "cd '${cwd}'; bash '${script}'"`
  ], {
    detached: true,
    stdio: 'ignore',
    cwd: cwd
  });
}

function launchWindowsTerminal() {
  const cwd = process.cwd();
  const script = path.join(cwd, 'bin', 'ralph.sh');

  return spawn('wt.exe', [
    '--title', 'GSD Ralph',
    'bash', script
  ], {
    detached: true,
    stdio: 'ignore',
    cwd: cwd
  });
}

function launchGitBash() {
  const cwd = process.cwd();
  const script = path.join(cwd, 'bin', 'ralph.sh');

  // Git Bash needs special handling through cmd
  return spawn('cmd.exe', [
    '/c', 'start', '""', 'bash', '--login', '-i', '-c',
    `cd "${cwd}" && bash "${script}"`
  ], {
    detached: true,
    stdio: 'ignore',
    cwd: cwd
  });
}

function launchMacTerminal() {
  const cwd = process.cwd();
  const script = path.join(cwd, 'bin', 'ralph.sh');

  const appleScript = `tell application "Terminal"
    do script "cd ${cwd} && ${script}"
    activate
end tell`;

  return spawn('osascript', ['-e', appleScript], {
    detached: true,
    stdio: 'ignore',
    cwd: cwd
  });
}

function launchGnomeTerminal() {
  const cwd = process.cwd();
  const script = path.join(cwd, 'bin', 'ralph.sh');

  return spawn('gnome-terminal', [
    '--window',
    '--title=GSD Ralph',
    '--',
    'bash', '-c', `cd "${cwd}" && "${script}"; exec bash`
  ], {
    detached: true,
    stdio: 'ignore',
    cwd: cwd
  });
}

function launchXterm() {
  const cwd = process.cwd();
  const script = path.join(cwd, 'bin', 'ralph.sh');

  return spawn('xterm', [
    '-hold',
    '-e', `cd "${cwd}" && "${script}"`
  ], {
    detached: true,
    stdio: 'ignore',
    cwd: cwd
  });
}

function launchXtermEmulator() {
  // x-terminal-emulator is a Debian alternatives symlink
  return launchXterm(); // Use same approach as xterm
}

function showManualInstructions(platform) {
  const cwd = process.cwd();
  const script = path.join(cwd, 'bin', 'ralph.sh');

  console.log('\n========================================');
  console.log(' TERMINAL LAUNCH FAILED');
  console.log('========================================\n');
  console.log('Could not auto-launch terminal window.\n');
  console.log('To run ralph.sh manually:\n');
  console.log('1. Open a new terminal window');
  console.log(`2. cd ${cwd}`);
  console.log(`3. ${platform === 'win32' ? 'bash ' : ''}${script}\n`);

  if (platform === 'win32') {
    console.log('Supported terminals:');
    console.log('  - Windows Terminal (wt.exe)');
    console.log('  - Command Prompt (cmd.exe)');
    console.log('  - PowerShell');
    console.log('  - Git Bash\n');
  } else if (platform === 'darwin') {
    console.log('Supported terminals:');
    console.log('  - Terminal.app\n');
  } else {
    console.log('Supported terminals:');
    console.log('  - gnome-terminal');
    console.log('  - xterm');
    console.log('  - x-terminal-emulator\n');
  }

  console.log('========================================\n');
}

function launchTerminal() {
  const platform = process.platform;
  const terminal = findTerminal(platform);

  if (!terminal) {
    showManualInstructions(platform);
    return { success: false, reason: 'no_terminal' };
  }

  try {
    const subprocess = terminal.launcher();
    subprocess.unref(); // Critical: allow parent to exit

    console.log(`\nLaunched ralph.sh in new ${terminal.name} window`);
    console.log('You can now close this Claude session - ralph.sh will continue running.\n');

    return { success: true, terminal: terminal.name, pid: subprocess.pid };
  } catch (err) {
    console.error(`\nFailed to launch ${terminal.name}: ${err.message}\n`);
    showManualInstructions(platform);
    return { success: false, reason: 'launch_failed', error: err.message };
  }
}

module.exports = { launchTerminal };
```

### Usage from autopilot.md
```javascript
// In commands/gsd/autopilot.md Step 4: Execute
const launcher = require('../../bin/lib/terminal-launcher.js');

// After settings confirmed and plans ready
const result = launcher.launchTerminal();

if (result.success) {
  console.log(`Ralph.sh is now running in ${result.terminal} (PID: ${result.pid})`);
  console.log('Process will continue independently after this session ends.');
} else {
  console.log('Could not auto-launch terminal.');
  console.log('Follow the manual instructions above to run ralph.sh.');
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline ralph.sh execution | Terminal window launch | Phase 11 (v1.1) | Execution isolation, fire-and-forget UX |
| Block on ralph.sh completion | Detached process | Phase 11 (v1.1) | User can close Claude session |
| Assume terminal available | Detect + fallback | Phase 11 (v1.1) | Graceful degradation (EXEC-03) |
| Single terminal option | Multi-terminal detection | Phase 11 (v1.1) | Works across environments |

**Deprecated/outdated:**
- open-terminal npm package (last update 5 years ago) - use custom solution instead
- Windows Terminal wt.exe (Jan 2025 KB5050021 bug) - may need fallback to cmd/PowerShell

## Open Questions

Things that couldn't be fully resolved:

1. **Windows Terminal (wt.exe) reliability**
   - What we know: KB5050021 (Jan 2025) breaks wt.exe programmatic launch
   - What's unclear: When will Microsoft fix this? Should we prioritize wt.exe or deprioritize?
   - Recommendation: Place wt.exe first in priority but have robust fallback to cmd/PowerShell

2. **Git Bash detection on Windows**
   - What we know: Git Bash installs to various locations (Program Files, user directory)
   - What's unclear: Best way to detect - check for bash.exe in PATH or look in common install paths?
   - Recommendation: Use command-exists for bash.exe in PATH; document that Git Bash must be in PATH

3. **macOS Terminal.app vs iTerm2**
   - What we know: iTerm2 is popular among developers but not bundled with macOS
   - What's unclear: Should we support iTerm2 detection?
   - Recommendation: Start with Terminal.app only (always available), add iTerm2 in future if requested

4. **Linux terminal multiplicity**
   - What we know: 20+ different terminal emulators exist on Linux
   - What's unclear: Which terminals should we support beyond gnome-terminal/xterm?
   - Recommendation: Support gnome-terminal, xterm, x-terminal-emulator (Debian alternative); others can use manual fallback

5. **Working directory persistence**
   - What we know: ralph.sh needs to run from project root
   - What's unclear: Should we use cwd option or cd command in terminal?
   - Recommendation: Use both - set cwd option AND include cd command for redundancy

## Sources

### Primary (HIGH confidence)
- [Node.js child_process Documentation](https://nodejs.org/api/child_process.html) - Official docs on detached processes, spawn options
- [Node.js OS Documentation](https://nodejs.org/api/os.html) - process.platform values
- [command-exists npm package](https://www.npmjs.com/package/command-exists) - Command existence checking

### Secondary (MEDIUM confidence - verified with official docs)
- [Windows Terminal command line arguments - Microsoft Learn](https://learn.microsoft.com/en-us/windows/terminal/command-line-arguments) - wt.exe usage
- [gnome-terminal man page - Ubuntu](https://manpages.ubuntu.com/manpages/trusty/man1/gnome-terminal.1.html) - gnome-terminal options
- [ttab GitHub](https://github.com/mklement0/ttab) - macOS terminal launching patterns
- [Start-Process - PowerShell Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-process?view=powershell-7.5) - PowerShell process spawning

### Tertiary (LOW confidence - WebSearch only, need validation)
- [Unable to Launch Windows Terminal via wt.exe After KB5050021 Update](https://learn.microsoft.com/en-us/answers/questions/2148845/unable-to-launch-windows-terminal-via-wt-exe-or-wi) - Windows Terminal Jan 2025 bug
- [nohup Command in Linux - DigitalOcean](https://www.digitalocean.com/community/tutorials/nohup-command-in-linux) - Background processes (not directly used but informative)
- [How to Check if a Program Exists From a Bash Script - Baeldung](https://www.baeldung.com/linux/bash-script-check-program-exists) - command -v usage (not used in Node.js solution)

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - Node.js built-ins are HIGH, but npm packages have medium usage/maintenance
- Architecture: MEDIUM - Patterns verified from official docs, but platform-specific commands need testing
- Pitfalls: MEDIUM - Based on GitHub issues and documentation, but not personally validated

**Research date:** 2026-01-20
**Valid until:** 60 days (Jan 2025 Windows Terminal bug may be fixed; npm package versions may update)
