# Stack Research: Terminal Path Resolution

**Project:** GSD Terminal Launcher Bug Fix
**Researched:** 2026-01-21
**Scope:** wt.exe bash variant detection and path conversion

## Executive Summary

The terminal-launcher.js currently hardcodes Git Bash path format (`/c/Users/...`), breaking when WSL or Cygwin is the default Windows Terminal profile. This research identifies detection and conversion approaches.

**Recommendation:** Use runtime detection via environment variables and shell utilities (`cygpath`/`wslpath`) rather than guessing. Shell utilities are authoritative and already available in each environment.

---

## 1. Tools for Bash Variant Detection

### Environment Variable Detection (RECOMMENDED - Zero Dependencies)

Each bash environment sets distinctive environment variables that Node.js can read via `process.env`:

| Environment | Detection Method | Confidence |
|-------------|-----------------|------------|
| **WSL** | `process.env.WSL_DISTRO_NAME` exists, OR `/proc/version` contains "microsoft" | HIGH |
| **Git Bash / MSYS2** | `process.env.MSYSTEM` is set (values: `MINGW64`, `MINGW32`, `MSYS`, `UCRT64`, `CLANG64`) | HIGH |
| **Cygwin** | `process.env.MSYSTEM` NOT set but `cygpath` exists, OR `uname -s` returns `CYGWIN*` | HIGH |

**Implementation pattern:**
```javascript
function detectBashVariant() {
  // WSL detection
  if (process.env.WSL_DISTRO_NAME || process.env.WSL_INTEROP) {
    return 'wsl';
  }

  // MSYS2/Git Bash detection
  if (process.env.MSYSTEM) {
    return 'msys'; // Git Bash is MSYS2-based
  }

  // Cygwin detection - no MSYSTEM but has CYGWIN env
  if (process.env.CYGWIN) {
    return 'cygwin';
  }

  return 'unknown';
}
```

**Confidence:** HIGH - These are authoritative markers set by the environments themselves.

**Source:** [Node.js Environment Variables Documentation](https://nodejs.org/api/environment_variables.html)

### uname -s Detection (Fallback)

When environment variables are unavailable, `uname -s` returns different values:

| Output Pattern | Environment |
|----------------|-------------|
| `Linux` + `/proc/version` contains "microsoft" | WSL |
| `MINGW64_NT-*` | Git Bash (64-bit) |
| `MINGW32_NT-*` | Git Bash (32-bit) / MinGW |
| `MSYS_NT-*` | MSYS2 |
| `CYGWIN_NT-*` | Cygwin |

**Source:** [detect os in bash (GitHub Gist)](https://gist.github.com/prabirshrestha/3080525)

### is-wsl npm Package (For WSL Only)

**Package:** `is-wsl` by sindresorhus
**Version:** Current (v3.x uses ESM)
**Weekly downloads:** ~40M

**Detection method:**
1. Checks `process.platform === 'linux'`
2. Checks if `os.release().toLowerCase().includes('microsoft')`
3. Falls back to reading `/proc/version`
4. Excludes Docker containers running on WSL

**Evaluation:** Reliable for WSL detection, but adds a dependency. The detection logic is simple enough to inline for zero-dependency approach.

**Source:** [is-wsl GitHub](https://github.com/sindresorhus/is-wsl)

---

## 2. Path Conversion Utilities

### cygpath (Git Bash, MSYS2, Cygwin)

**Availability:** Included in Git Bash, MSYS2, and Cygwin by default.

**Key flags:**
| Flag | Output Format | Example Input | Example Output |
|------|---------------|---------------|----------------|
| `-u` | Unix/POSIX | `C:\Users\foo` | `/c/Users/foo` (Git Bash) or `/cygdrive/c/Users/foo` (Cygwin) |
| `-w` | Windows backslash | `/c/foo` | `C:\foo` |
| `-m` | Mixed (forward slash) | `/c/foo` | `C:/foo` |
| `-p` | PATH list conversion | `C:\bin;D:\lib` | `/c/bin:/d/lib` |

**Critical insight:** `cygpath -u` output differs between environments:
- Git Bash/MSYS2: `/c/Users/...`
- Cygwin: `/cygdrive/c/Users/...`

This means `cygpath` automatically gives the correct format for the current environment.

**Node.js usage:**
```javascript
const { execSync } = require('child_process');

function convertPathViaCygpath(windowsPath) {
  try {
    const result = execSync(`cygpath -u "${windowsPath}"`, { encoding: 'utf8' });
    return result.trim();
  } catch (e) {
    return null; // cygpath not available
  }
}
```

**Confidence:** HIGH - Authoritative tool provided by each environment.

**Source:** [MSYS2 Filesystem Paths](https://www.msys2.org/docs/filesystem-paths/), [Cygwin cygpath manual](https://cygwin.com/cygwin-ug-net/cygpath.html)

### wslpath (WSL Only)

**Availability:** Built into WSL (Microsoft-provided utility).

**Key flags:**
| Flag | Output Format | Example |
|------|---------------|---------|
| `-u` | Unix/Linux | `C:\Users\foo` -> `/mnt/c/Users/foo` |
| `-w` | Windows | `/mnt/c/foo` -> `C:\foo` |
| `-m` | Mixed | `/mnt/c/foo` -> `C:/foo` |
| `-a` | Absolute path | Ensures full path |

**Node.js usage:**
```javascript
const { execSync } = require('child_process');

function convertPathViaWslpath(windowsPath) {
  try {
    const result = execSync(`wslpath -u "${windowsPath}"`, { encoding: 'utf8' });
    return result.trim();
  } catch (e) {
    return null; // wslpath not available (not in WSL)
  }
}
```

**Confidence:** HIGH - Microsoft's official path conversion for WSL.

**Source:** [wslpath blog post](https://blog.paulolc.pt/wslpath/), [laurent22/wslpath GitHub](https://github.com/laurent22/wslpath)

### Pure JavaScript Conversion (Fallback)

When shell utilities unavailable, pattern-based conversion:

```javascript
function toUnixPath(windowsPath, variant) {
  const normalized = windowsPath.replace(/\\/g, '/');
  const match = normalized.match(/^([A-Za-z]):\//);

  if (!match) return normalized;

  const drive = match[1].toLowerCase();
  const rest = normalized.slice(3);

  switch (variant) {
    case 'wsl':
      return `/mnt/${drive}/${rest}`;
    case 'cygwin':
      return `/cygdrive/${drive}/${rest}`;
    case 'msys': // Git Bash, MSYS2
    default:
      return `/${drive}/${rest}`;
  }
}
```

**Confidence:** MEDIUM - Works for simple paths but may miss edge cases (network paths, special mounts, etc.).

---

## 3. Cross-Platform Terminal Spawning

### Current Approach (terminal-launcher.js)

The existing code uses `child_process.spawn()` with hardcoded Git Bash paths:

```javascript
// Current problematic code (lines 141-151)
const gitBashPath = 'C:\\Program Files\\Git\\bin\\bash.exe';
return spawn('wt.exe', [
  '--title', windowTitle,
  gitBashPath, '--login', '-c', `cd "${bashCwd}" && bash "${bashScript}"`
], { detached: true, stdio: 'ignore' });
```

**Problems:**
1. Hardcodes Git Bash executable path
2. Uses Git Bash path format regardless of default profile
3. Ignores user's Windows Terminal configuration

### Windows Terminal Profile Detection

**Settings file location:**
```
%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

**Structure:**
```json
{
  "defaultProfile": "{guid-here}",
  "profiles": {
    "list": [
      { "guid": "{...}", "name": "PowerShell", "commandline": "powershell.exe" },
      { "guid": "{...}", "name": "Ubuntu", "commandline": "wsl.exe -d Ubuntu" },
      { "guid": "{...}", "name": "Git Bash", "commandline": "C:\\Program Files\\Git\\bin\\bash.exe" }
    ]
  }
}
```

**Detection approach:**
```javascript
const fs = require('fs');
const path = require('path');

function getWindowsTerminalDefaultProfile() {
  const settingsPath = path.join(
    process.env.LOCALAPPDATA,
    'Packages',
    'Microsoft.WindowsTerminal_8wekyb3d8bbwe',
    'LocalState',
    'settings.json'
  );

  try {
    const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
    const defaultGuid = settings.defaultProfile;
    const profiles = settings.profiles?.list || [];
    return profiles.find(p => p.guid === defaultGuid);
  } catch (e) {
    return null;
  }
}
```

**Confidence:** MEDIUM - File location is stable but schema could change.

**Source:** [Windows Terminal Profile Settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-general)

### Alternative: Let wt.exe Use Default Profile

Instead of specifying a shell, let Windows Terminal use its configured default:

```javascript
// Simpler approach - use default profile
spawn('wt.exe', ['--title', windowTitle], { ... });
```

Then write a wrapper script that:
1. Detects its environment at runtime
2. Converts paths appropriately
3. Runs the actual script

**Confidence:** HIGH for reliability, but requires script-level path handling.

---

## 4. Recommended Approach

### Strategy: Runtime Detection with Shell Utilities

**Why this approach:**
1. **Zero new dependencies** - Uses built-in shell utilities
2. **Authoritative** - `cygpath`/`wslpath` know their own path formats
3. **Future-proof** - Works even if environments change mount points
4. **Simple fallback** - JavaScript conversion as backup

### Implementation Plan

**Option A: Detect at spawn time (Node.js side)**

Read Windows Terminal settings.json to determine default profile, then convert paths accordingly before passing to wt.exe.

```javascript
function launchWindowsTerminal(scriptPath, windowTitle = 'GSD') {
  const profile = getWindowsTerminalDefaultProfile();
  const shellType = detectShellTypeFromProfile(profile);
  const bashPath = convertPathForShellType(scriptPath, shellType);
  const bashCwd = convertPathForShellType(process.cwd(), shellType);

  // Let wt.exe use its default profile
  return spawn('wt.exe', [
    '--title', windowTitle,
    'bash', '-c', `cd "${bashCwd}" && bash "${bashPath}"`
  ], { detached: true, stdio: 'ignore' });
}

function detectShellTypeFromProfile(profile) {
  if (!profile) return 'msys'; // default to Git Bash
  const cmd = (profile.commandline || '').toLowerCase();

  if (cmd.includes('wsl') || cmd.includes('ubuntu') || cmd.includes('debian')) {
    return 'wsl';
  }
  if (cmd.includes('cygwin')) {
    return 'cygwin';
  }
  // Default to MSYS/Git Bash format
  return 'msys';
}
```

**Option B: Detect at runtime (bash script side) - RECOMMENDED**

Let the bash script detect its own environment and handle paths:

```bash
#!/bin/bash
# ralph.sh - Self-detecting path handling

# Detect environment
detect_env() {
  if [ -n "$WSL_DISTRO_NAME" ]; then
    echo "wsl"
  elif [ -n "$MSYSTEM" ]; then
    echo "msys"
  elif [ -n "$CYGWIN" ]; then
    echo "cygwin"
  else
    echo "unknown"
  fi
}

# Convert path using native tools
convert_path() {
  local win_path="$1"
  local env=$(detect_env)

  case "$env" in
    wsl)
      wslpath -u "$win_path" 2>/dev/null || echo "$win_path"
      ;;
    msys|cygwin)
      cygpath -u "$win_path" 2>/dev/null || echo "$win_path"
      ;;
    *)
      echo "$win_path"
      ;;
  esac
}

# Use it
WORKING_DIR=$(convert_path "$1")
cd "$WORKING_DIR" || exit 1
```

**Why Option B is better:**
- Detection happens IN the spawned environment (authoritative)
- No guessing from Node.js side
- Uses native tools (`cygpath`/`wslpath`) which know their own format
- Simpler Node.js code

### Decision Matrix

| Scenario | Detection | Path Conversion |
|----------|-----------|-----------------|
| Running inside WSL | `WSL_DISTRO_NAME` env | `wslpath -u` |
| Running inside Git Bash | `MSYSTEM` env | `cygpath -u` |
| Running inside Cygwin | No `MSYSTEM`, has `CYGWIN` | `cygpath -u` |
| Spawning wt.exe from cmd/PS | Read settings.json OR pass Windows path and let script convert | Pre-convert or defer to script |
| Unknown/fallback | - | JavaScript pattern matching |

---

## 5. npm Packages Evaluated

### Recommended: Zero Dependencies (Inline Logic)

Given GSD's philosophy of minimal dependencies, inline the detection logic rather than adding packages.

### If Dependencies Acceptable

| Package | Purpose | Weekly Downloads | Verdict |
|---------|---------|------------------|---------|
| `is-wsl` | WSL detection | ~40M | Good but trivial to inline |
| `wsl-path` | WSL path conversion | ~5K | Requires `wslpath` CLI anyway |
| `wsl-utils` | WSL utilities | ~1K | Overkill for this use case |

**Recommendation:** Do not add dependencies. The detection logic is simple enough to implement directly, and path conversion should use the authoritative shell utilities.

---

## 6. Implementation Recommendations

### Approach: Modify ralph.sh for Runtime Detection

**Rationale:** Rather than trying to detect from Node.js which bash wt.exe will spawn, pass Windows paths to the bash script and let the script convert them using native tools.

**Changes needed:**

1. **terminal-launcher.js** - Pass Windows paths (not pre-converted)
   ```javascript
   // OLD: const bashScript = toGitBashPath(scriptPath);
   // NEW: Pass Windows path, let script handle conversion
   const windowsScript = scriptPath.replace(/\//g, '\\');
   ```

2. **ralph.sh** - Add environment detection and path conversion
   ```bash
   # At top of script
   convert_win_path() {
     if command -v wslpath >/dev/null 2>&1; then
       wslpath -u "$1"
     elif command -v cygpath >/dev/null 2>&1; then
       cygpath -u "$1"
     else
       # Fallback: basic conversion
       echo "$1" | sed 's|\\|/|g' | sed 's|^\([A-Za-z]\):|/\L\1|'
     fi
   }
   ```

3. **Fallback** - Keep JavaScript conversion for cases where script detection fails

### Alternative: Detect and Convert in Node.js

If modifying ralph.sh is undesirable, detect default profile in Node.js:

```javascript
function getPathConverter() {
  const profile = getWindowsTerminalDefaultProfile();
  if (!profile) return toGitBashPath; // default

  const cmd = (profile.commandline || '').toLowerCase();

  if (cmd.includes('wsl')) {
    return (p) => toWslPath(p);
  }
  if (cmd.includes('cygwin')) {
    return (p) => toCygwinPath(p);
  }
  return toGitBashPath;
}

function toWslPath(windowsPath) {
  const normalized = windowsPath.replace(/\\/g, '/');
  return normalized.replace(/^([A-Za-z]):/, (_, d) => `/mnt/${d.toLowerCase()}`);
}

function toCygwinPath(windowsPath) {
  const normalized = windowsPath.replace(/\\/g, '/');
  return normalized.replace(/^([A-Za-z]):/, (_, d) => `/cygdrive/${d.toLowerCase()}`);
}
```

---

## 7. Implementation Checklist

- [ ] Add `detectBashEnvironment()` to ralph.sh using env vars
- [ ] Add `convert_win_path()` to ralph.sh using cygpath/wslpath
- [ ] Update terminal-launcher.js to pass Windows paths (or add profile detection)
- [ ] Add JavaScript fallback converters for WSL and Cygwin formats
- [ ] Test with Git Bash as default profile
- [ ] Test with WSL as default profile
- [ ] Test with Cygwin as default profile (if available)
- [ ] Document the detection/conversion behavior

---

## Sources

### Official Documentation
- [Node.js child_process Documentation](https://nodejs.org/api/child_process.html)
- [Node.js Environment Variables](https://nodejs.org/api/environment_variables.html)
- [Windows Terminal Profile Settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-general)
- [Windows Terminal Command Line Arguments](https://learn.microsoft.com/en-us/windows/terminal/command-line-arguments)
- [Cygwin cygpath Manual](https://cygwin.com/cygwin-ug-net/cygpath.html)
- [MSYS2 Filesystem Paths](https://www.msys2.org/docs/filesystem-paths/)

### Community Resources
- [is-wsl GitHub (sindresorhus)](https://github.com/sindresorhus/is-wsl)
- [wslpath GitHub (laurent22)](https://github.com/laurent22/wslpath)
- [How to detect if running under WSL (GitHub Issue)](https://github.com/microsoft/WSL/issues/4071)
- [detect os in bash (GitHub Gist)](https://gist.github.com/prabirshrestha/3080525)
- [Cross Platform Bash Snippet (GitHub Gist)](https://gist.github.com/mikeslattery/5c60655478f76e26b9232aedc664eb7d)
- [Path conversion in Git Bash (DEV Community)](https://dev.to/taijidude/paths-conversion-in-git-bash-3jeh)
- [Differences Between Cygwin, MinGW, WSL, MSYS2, and Git Bash](https://www.softpost.org/c-language/differences-between-cygwin-mingw-wsl-windows-subsystem-for-linux-msys2-and-git-bash)

### npm Packages (Evaluated, Not Recommended)
- [wsl-path npm](https://www.npmjs.com/package/wsl-path)
- [wsl-utils npm](https://www.npmjs.com/package/wsl-utils)
- [is-wsl npm](https://www.npmjs.com/package/is-wsl)
