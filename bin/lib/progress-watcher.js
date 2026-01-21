#!/usr/bin/env node
// GSD Progress Watcher - Live autopilot progress display
// Part of Quick Task 001: Autopilot Progress Watcher
//
// Watches .planning/STATE.md and .planning/ralph.log for changes
// and displays formatted real-time progress updates.
// Zero API token consumption - pure file watching.

const fs = require('fs');
const path = require('path');
const os = require('os');

// ANSI color codes (respect NO_COLOR)
const NO_COLOR = process.env.NO_COLOR;
const COLORS = NO_COLOR ? {
  RED: '',
  GREEN: '',
  YELLOW: '',
  CYAN: '',
  BLUE: '',
  BOLD: '',
  DIM: '',
  RESET: ''
} : {
  RED: '\x1b[31m',
  GREEN: '\x1b[32m',
  YELLOW: '\x1b[33m',
  CYAN: '\x1b[36m',
  BLUE: '\x1b[34m',
  BOLD: '\x1b[1m',
  DIM: '\x1b[2m',
  RESET: '\x1b[0m'
};

// Clear screen
function clearScreen() {
  if (!NO_COLOR) {
    process.stdout.write('\x1b[2J\x1b[H');
  }
}

// Parse STATE.md for current position and progress
function parseState(stateContent) {
  const lines = stateContent.split('\n');
  const result = {
    phase: '',
    plan: '',
    status: '',
    progress: '',
    lastActivity: ''
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    if (line.startsWith('Phase:')) {
      result.phase = line.substring(6).trim();
    } else if (line.startsWith('Plan:')) {
      result.plan = line.substring(5).trim();
    } else if (line.startsWith('Status:')) {
      result.status = line.substring(7).trim();
    } else if (line.startsWith('Last activity:')) {
      result.lastActivity = line.substring(14).trim();
    } else if (line.startsWith('Progress:')) {
      result.progress = line.substring(9).trim();
    }
  }

  return result;
}

// Parse ralph.log for iteration entries
function parseRalphLog(logContent) {
  const entries = [];
  const blocks = logContent.split('---\n').filter(b => b.trim());

  for (const block of blocks) {
    const lines = block.split('\n');
    const entry = {};

    for (const line of lines) {
      if (line.startsWith('Iteration:')) {
        entry.iteration = line.substring(10).trim();
      } else if (line.startsWith('Timestamp:')) {
        entry.timestamp = line.substring(10).trim();
      } else if (line.startsWith('Task:')) {
        entry.task = line.substring(5).trim();
      } else if (line.startsWith('Status:')) {
        entry.status = line.substring(7).trim();
      } else if (line.startsWith('Duration:')) {
        entry.duration = line.substring(9).trim();
      } else if (line.startsWith('Summary:')) {
        entry.summary = line.substring(8).trim();
      }
    }

    if (entry.iteration) {
      entries.push(entry);
    }
  }

  return entries;
}

// Format status with color
function formatStatus(status) {
  if (!status) return '';

  const upper = status.toUpperCase();
  if (upper === 'SUCCESS') {
    return `${COLORS.GREEN}✓ ${status}${COLORS.RESET}`;
  } else if (upper === 'FAILURE') {
    return `${COLORS.RED}✗ ${status}${COLORS.RESET}`;
  } else if (upper === 'RETRY') {
    return `${COLORS.YELLOW}⟳ ${status}${COLORS.RESET}`;
  } else {
    return status;
  }
}

// Display current state
function displayProgress(stateFile, logFile) {
  clearScreen();

  const now = new Date().toLocaleTimeString();
  console.log(`${COLORS.BOLD}${COLORS.CYAN}═══════════════════════════════════════════════════════════════════${COLORS.RESET}`);
  console.log(`${COLORS.BOLD}${COLORS.CYAN}  GSD Progress Watcher${COLORS.RESET}                        ${COLORS.DIM}${now}${COLORS.RESET}`);
  console.log(`${COLORS.BOLD}${COLORS.CYAN}═══════════════════════════════════════════════════════════════════${COLORS.RESET}\n`);

  // Read and display STATE.md
  if (fs.existsSync(stateFile)) {
    try {
      const stateContent = fs.readFileSync(stateFile, 'utf8');
      const state = parseState(stateContent);

      console.log(`${COLORS.BOLD}Current Position:${COLORS.RESET}`);
      console.log(`  Phase:  ${state.phase}`);
      console.log(`  Plan:   ${state.plan}`);
      console.log(`  Status: ${state.status}`);
      if (state.lastActivity) {
        console.log(`  Last:   ${COLORS.DIM}${state.lastActivity}${COLORS.RESET}`);
      }
      console.log();

      if (state.progress) {
        console.log(`${COLORS.BOLD}Progress:${COLORS.RESET}`);
        console.log(`  ${state.progress}`);
        console.log();
      }
    } catch (err) {
      console.log(`${COLORS.RED}Error reading STATE.md: ${err.message}${COLORS.RESET}\n`);
    }
  } else {
    console.log(`${COLORS.DIM}Waiting for STATE.md...${COLORS.RESET}\n`);
  }

  // Read and display ralph.log (last 5 iterations)
  if (fs.existsSync(logFile)) {
    try {
      const logContent = fs.readFileSync(logFile, 'utf8');
      const entries = parseRalphLog(logContent);
      const recentEntries = entries.slice(-5); // Last 5 iterations

      if (recentEntries.length > 0) {
        console.log(`${COLORS.BOLD}Recent Iterations:${COLORS.RESET}`);
        for (const entry of recentEntries) {
          const statusFormatted = formatStatus(entry.status);
          console.log(`  ${COLORS.CYAN}#${entry.iteration}${COLORS.RESET} ${statusFormatted}`);
          console.log(`      Task: ${COLORS.DIM}${entry.task}${COLORS.RESET}`);
          if (entry.summary) {
            console.log(`      ${entry.summary}`);
          }
          if (entry.duration) {
            console.log(`      ${COLORS.DIM}Duration: ${entry.duration}${COLORS.RESET}`);
          }
          console.log();
        }
      }
    } catch (err) {
      console.log(`${COLORS.RED}Error reading ralph.log: ${err.message}${COLORS.RESET}\n`);
    }
  }

  console.log(`${COLORS.DIM}───────────────────────────────────────────────────────────────────${COLORS.RESET}`);
  console.log(`${COLORS.DIM}Watching for changes... (Ctrl+C to exit)${COLORS.RESET}`);
}

// Main watch function
function watchProgress(projectRoot) {
  const stateFile = path.join(projectRoot, '.planning', 'STATE.md');
  const logFile = path.join(projectRoot, '.planning', 'ralph.log');

  // Initial display
  displayProgress(stateFile, logFile);

  // Watch STATE.md
  let stateWatcher = null;
  if (fs.existsSync(path.dirname(stateFile))) {
    stateWatcher = fs.watch(path.dirname(stateFile), (eventType, filename) => {
      if (filename === 'STATE.md') {
        displayProgress(stateFile, logFile);
      }
    });
  }

  // Watch ralph.log
  let logWatcher = null;
  if (fs.existsSync(path.dirname(logFile))) {
    logWatcher = fs.watch(path.dirname(logFile), (eventType, filename) => {
      if (filename === 'ralph.log') {
        displayProgress(stateFile, logFile);
      }
    });
  }

  // Graceful shutdown
  const cleanup = () => {
    console.log(`\n\n${COLORS.YELLOW}Stopping progress watcher...${COLORS.RESET}`);
    if (stateWatcher) stateWatcher.close();
    if (logWatcher) logWatcher.close();
    process.exit(0);
  };

  process.on('SIGINT', cleanup);
  process.on('SIGTERM', cleanup);

  // Keep process alive
  setInterval(() => {
    // Refresh display every 10 seconds even without file changes
    displayProgress(stateFile, logFile);
  }, 10000);
}

// CLI
function showHelp() {
  console.log(`
${COLORS.BOLD}GSD Progress Watcher${COLORS.RESET}

Live progress display for autopilot execution.
Watches .planning/STATE.md and .planning/ralph.log for real-time updates.

${COLORS.BOLD}USAGE:${COLORS.RESET}
  progress-watcher.js [project-root]

${COLORS.BOLD}ARGUMENTS:${COLORS.RESET}
  project-root    Path to GSD project root (default: current directory)

${COLORS.BOLD}EXAMPLES:${COLORS.RESET}
  progress-watcher.js
  progress-watcher.js /path/to/project

${COLORS.BOLD}NOTES:${COLORS.RESET}
  - Press Ctrl+C to exit
  - Zero API token consumption (pure file watching)
  - Auto-launched when autopilot starts
  - Display updates on file changes + every 10 seconds
`);
}

// Entry point
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    showHelp();
    process.exit(0);
  }

  const projectRoot = args[0] || process.cwd();

  if (!fs.existsSync(projectRoot)) {
    console.error(`${COLORS.RED}Error: Project root not found: ${projectRoot}${COLORS.RESET}`);
    process.exit(1);
  }

  watchProgress(projectRoot);
}

module.exports = { watchProgress };
