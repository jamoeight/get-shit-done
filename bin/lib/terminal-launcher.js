#!/usr/bin/env node
// Terminal Launcher - Cross-platform terminal window spawning
// Part of Phase 11: Terminal Launcher
//
// Detects platform, finds available terminal emulator, launches ralph.sh
// in a new window as a detached process for execution isolation.

const { spawn } = require('child_process');
const path = require('path');
const os = require('os');

// Get the installed ralph.sh location (relative to this file)
// When installed: ~/.claude/get-shit-done/bin/lib/terminal-launcher.js
// ralph.sh is at: ~/.claude/get-shit-done/bin/ralph.sh
const RALPH_SCRIPT = path.join(__dirname, '..', 'ralph.sh');

// Convert Windows path to Git Bash path (C:/Users/... → /c/Users/...)
function toGitBashPath(windowsPath) {
  const normalized = windowsPath.replace(/\\/g, '/');
  // Match drive letter pattern like C:/ or D:/
  const match = normalized.match(/^([A-Za-z]):\//);
  if (match) {
    return '/' + match[1].toLowerCase() + normalized.slice(2);
  }
  return normalized;
}

// command-exists for checking terminal availability
let commandExistsSync;
try {
  commandExistsSync = require('command-exists').sync;
} catch (e) {
  // Fallback if command-exists not installed
  commandExistsSync = () => false;
}

// Terminal configurations by platform
// Order matters - first available terminal is used
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
      if (commandExistsSync(terminal.name)) {
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
  const script = toGitBashPath(RALPH_SCRIPT);

  return spawn('cmd.exe', ['/c', 'start', 'cmd', '/k', `bash "${script}"`], {
    detached: true,
    stdio: 'ignore',
    cwd: cwd,
    shell: false
  });
}

function launchPowerShell() {
  const cwd = process.cwd();
  const script = toGitBashPath(RALPH_SCRIPT);
  const bashCwd = toGitBashPath(cwd);

  return spawn('powershell.exe', [
    '-Command', 'Start-Process', 'powershell',
    '-ArgumentList', `"-NoExit", "-Command", "cd '${cwd.replace(/'/g, "''")}'; bash '${script}'"`
  ], {
    detached: true,
    stdio: 'ignore',
    cwd: cwd,
    shell: false
  });
}

function launchWindowsTerminal() {
  const cwd = process.cwd();
  const script = toGitBashPath(RALPH_SCRIPT);

  return spawn('wt.exe', [
    '--title', 'GSD Ralph',
    'bash', script
  ], {
    detached: true,
    stdio: 'ignore',
    cwd: cwd,
    shell: false
  });
}

function launchGitBash() {
  const cwd = process.cwd();
  const script = toGitBashPath(RALPH_SCRIPT);
  const bashCwd = toGitBashPath(cwd);

  return spawn('cmd.exe', [
    '/c', 'start', '""', 'bash', '--login', '-i', '-c',
    `cd "${bashCwd}" && bash "${script}"`
  ], {
    detached: true,
    stdio: 'ignore',
    cwd: cwd,
    shell: false
  });
}

function launchMacTerminal() {
  const cwd = process.cwd();
  const script = RALPH_SCRIPT;

  // Escape for AppleScript
  const escapedCwd = cwd.replace(/"/g, '\\"');
  const escapedScript = script.replace(/"/g, '\\"');

  const appleScript = `tell application "Terminal"
    do script "cd \\"${escapedCwd}\\" && \\"${escapedScript}\\""
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
  const script = RALPH_SCRIPT;

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
  const script = RALPH_SCRIPT;

  return spawn('xterm', [
    '-hold',
    '-title', 'GSD Ralph',
    '-e', `cd "${cwd}" && "${script}"`
  ], {
    detached: true,
    stdio: 'ignore',
    cwd: cwd
  });
}

function launchXtermEmulator() {
  // x-terminal-emulator is a Debian alternatives symlink
  // Use same approach as xterm
  return launchXterm();
}

function showManualInstructions(platform) {
  const cwd = process.cwd();
  const script = RALPH_SCRIPT;

  console.log('\n==========================================');
  console.log(' TERMINAL LAUNCH UNAVAILABLE');
  console.log('==========================================\n');
  console.log('Could not detect a supported terminal emulator.\n');
  console.log('To run autopilot manually:\n');
  console.log('  1. Open a new terminal window');
  console.log(`  2. cd ${cwd}`);

  if (platform === 'win32') {
    console.log(`  3. bash ${script}\n`);
    console.log('Supported terminals on Windows:');
    console.log('  - Windows Terminal (wt.exe)');
    console.log('  - Command Prompt (cmd.exe)');
    console.log('  - PowerShell');
    console.log('  - Git Bash');
  } else if (platform === 'darwin') {
    console.log(`  3. ${script}\n`);
    console.log('Supported terminals on macOS:');
    console.log('  - Terminal.app');
  } else {
    console.log(`  3. ${script}\n`);
    console.log('Supported terminals on Linux:');
    console.log('  - gnome-terminal');
    console.log('  - xterm');
    console.log('  - x-terminal-emulator');
  }

  console.log('\n==========================================\n');
}

/**
 * Launch ralph.sh in a new terminal window
 *
 * @returns {Object} Result object with:
 *   - success: boolean - whether terminal was launched
 *   - terminal: string - terminal name used (if success)
 *   - pid: number - process ID (if success)
 *   - reason: string - failure reason (if !success)
 *   - error: string - error message (if launch failed)
 */
function launchTerminal() {
  const platform = process.platform;
  const terminal = findTerminal(platform);

  if (!terminal) {
    showManualInstructions(platform);
    return { success: false, reason: 'no_terminal_found' };
  }

  try {
    const subprocess = terminal.launcher();
    subprocess.unref(); // Critical: allow parent to exit independently

    console.log(`\nLaunched ralph.sh in new ${terminal.name} window`);
    console.log('You can now close this Claude session - ralph.sh will continue running.\n');

    return {
      success: true,
      terminal: terminal.name,
      pid: subprocess.pid
    };
  } catch (err) {
    console.error(`\nFailed to launch ${terminal.name}: ${err.message}\n`);
    showManualInstructions(platform);
    return {
      success: false,
      reason: 'launch_failed',
      error: err.message
    };
  }
}

module.exports = {
  launchTerminal,
  findTerminal,  // Exported for testing
  showManualInstructions  // Exported for direct use if needed
};

// CLI support - run directly for testing
if (require.main === module) {
  console.log('Terminal Launcher Test');
  console.log('Platform:', process.platform);

  const terminal = findTerminal(process.platform);
  if (terminal) {
    console.log('Found terminal:', terminal.name);
    console.log('\nLaunching terminal in 3 seconds...');
    setTimeout(() => {
      const result = launchTerminal();
      console.log('Result:', JSON.stringify(result, null, 2));
      process.exit(result.success ? 0 : 1);
    }, 3000);
  } else {
    console.log('No terminal found');
    showManualInstructions(process.platform);
    process.exit(1);
  }
}
