# Pitfalls Research: Terminal Path Resolution

**Domain:** Cross-platform terminal spawning on Windows with bash variants
**Researched:** 2026-01-21
**Confidence:** HIGH (multiple verified sources, confirmed by project experience)

## Known Failed Approaches

These approaches were tried and failed during v1.2 development:

### Failed Attempt 1: Windows Paths (`C:/Users/...`)

**What was tried:**
```javascript
spawn('wt.exe', ['--title', 'GSD', 'bash', scriptPath])
// Where scriptPath = "C:/Users/Jameson/Downloads/project/bin/ralph.sh"
```

**Why it failed:** Git Bash doesn't understand Windows-style paths in the `cd` command. Internally, Git Bash (MSYS2) translates drive letters to `/c/`, `/d/`, etc.

**Error seen:**
```
bash: cd: C:/Users/Jameson/Downloads/project: No such file or directory
```

**Lesson:** Never pass raw Windows paths to Git Bash commands.

---

### Failed Attempt 2: Git Bash Paths (`/c/Users/...`)

**What was tried:**
```javascript
function toGitBashPath(windowsPath) {
  return '/' + windowsPath[0].toLowerCase() + windowsPath.slice(2).replace(/\\/g, '/');
}
// Result: "/c/Users/Jameson/Downloads/project"
```

**Why it failed:** This works for Git Bash but NOT for WSL bash. When the user's Windows Terminal default profile is WSL, `wt.exe bash` spawns WSL bash, not Git Bash.

**Error seen:**
```
/bin/bash: line 1: cd: /c/Users/Jameson/Downloads/gsd-auto-pilot-test: No such file or directory
```

The `/bin/bash` prefix reveals WSL bash (Git Bash shows `/usr/bin/bash`).

**Lesson:** Can't assume which bash `wt.exe` will spawn - it depends on user's default profile.

---

### Failed Attempt 3: Using `wt.exe -d` Flag

**What was tried:**
```javascript
spawn('wt.exe', ['-d', cwd, 'bash', '-c', `bash "${scriptPath}"`])
```

**Why it failed:** The `-d` flag sets the starting directory, but the script path inside the `-c` command still needs the correct format for whichever bash runs.

**Lesson:** The `-d` flag helps with working directory but doesn't solve script path format issues.

---

### Failed Attempt 4: Hardcoded Git Bash Path

**What was tried:**
```javascript
const gitBashPath = 'C:\\Program Files\\Git\\bin\\bash.exe';
spawn('wt.exe', ['--title', 'GSD', gitBashPath, '--login', '-c', `cd "${bashCwd}" && bash "${bashScript}"`]);
```

**Why it may fail:** Assumes Git Bash is installed at the standard location. Some users install to different paths (e.g., `C:\Git\bin\bash.exe` or user-local installs).

**Lesson:** Hardcoding paths is fragile. Need fallback detection or user configuration.

## Path Format Pitfalls

### Pitfall 1: Bash Variant Path Format Mismatch

**What goes wrong:** Code assumes one path format but a different bash variant runs.

**Path formats by bash type:**

| Bash Type | Path Format | Example | Detection |
|-----------|-------------|---------|-----------|
| Git Bash (MSYS2) | `/c/Users/...` | `/c/Users/Jameson/project` | `uname -s` returns `MINGW64_NT*` or `MSYS_NT*` |
| WSL | `/mnt/c/Users/...` | `/mnt/c/Users/Jameson/project` | `uname -s` returns `Linux`, has `WSL_DISTRO_NAME` env var |
| Cygwin | `/cygdrive/c/Users/...` | `/cygdrive/c/Users/Jameson/project` | `uname -s` returns `CYGWIN_NT*` |
| Native bash | `C:/Users/...` | `C:/Users/Jameson/project` | Rare, typically not configured |

**How to detect early:** Check `$OSTYPE` or `uname -s` before path operations.

**Prevention strategy:**
```bash
# Runtime detection - works in any bash
if [ -n "$WSL_DISTRO_NAME" ]; then
  PATH_PREFIX="/mnt"
elif [[ "$(uname -s)" == CYGWIN* ]]; then
  PATH_PREFIX="/cygdrive"
else
  PATH_PREFIX=""
fi
```

**Fix pattern - universal path resolution:**
```bash
# Try each format until one works
cd "$(cygpath -u 'C:\Users\Jameson\project')" 2>/dev/null || \
cd "/mnt/c/Users/Jameson/project" 2>/dev/null || \
cd "/c/Users/Jameson/project" 2>/dev/null || \
cd "C:/Users/Jameson/project"
```

---

### Pitfall 2: Assuming `cygpath` Availability

**What goes wrong:** Code uses `cygpath` for path conversion but it's not available.

**Availability:**
- Git Bash (MSYS2): YES, `cygpath` included
- WSL: NO, use `wslpath` instead
- Cygwin: YES, `cygpath` included
- Native Windows bash: NO

**How to detect:** Check if command exists before using.

**Prevention:**
```bash
if command -v cygpath &>/dev/null; then
  unix_path=$(cygpath -u "$windows_path")
elif command -v wslpath &>/dev/null; then
  unix_path=$(wslpath -u "$windows_path")
else
  # Manual fallback
  unix_path="${windows_path//\\//}"  # Replace backslashes
  unix_path="/${unix_path%%:*}${unix_path#*:}"  # C:/foo -> /C/foo
fi
```

---

### Pitfall 3: Backslash vs Forward Slash Confusion

**What goes wrong:** Path separators get mangled during string operations.

**Windows native:** `C:\Users\Jameson\project`
**Unix-style:** `/c/Users/Jameson/project`
**Node.js path.join on Windows:** Returns backslashes

**How to detect:** Visually inspect paths in debug output.

**Prevention in Node.js:**
```javascript
// Always normalize after path operations
const scriptPath = path.join(__dirname, '..', 'ralph.sh').replace(/\\/g, '/');
```

**Prevention in bash:**
```bash
# Convert backslashes to forward slashes
path="${path//\\//}"
```

---

### Pitfall 4: Spaces in Path Not Quoted

**What goes wrong:** Path with spaces breaks into multiple arguments.

**Example:** `C:\Users\John Smith\project` becomes two arguments: `C:\Users\John` and `Smith\project`.

**How to detect:** Test with paths containing spaces.

**Prevention - always quote paths:**
```javascript
// WRONG
spawn('bash', ['-c', `cd ${path} && ./script.sh`]);

// RIGHT
spawn('bash', ['-c', `cd "${path}" && ./script.sh`]);
```

**Double prevention - use spawn args array:**
```javascript
// BEST - let spawn handle quoting
spawn('bash', ['-c', `cd "${path}" && ./script.sh`], { cwd: path });
```

---

### Pitfall 5: Special Characters in Paths

**What goes wrong:** Paths with `&`, `$`, `!`, `;`, or quotes break commands.

**Dangerous characters:**
- `&` - Command separator in cmd/bash
- `$` - Variable expansion in bash
- `!` - History expansion in bash
- `;` - Command separator
- `'` and `"` - Quote characters
- `(` and `)` - Subshell in bash
- `` ` `` - Command substitution

**Prevention - escape or use single quotes:**
```bash
# Single quotes prevent most expansion
cd '/path/with/$pecial&chars'

# Or escape explicitly
cd "/path/with/\$pecial\&chars"
```

**In Node.js - avoid shell: true when possible:**
```javascript
// Safer - no shell interpretation
spawn(command, args, { shell: false });
```

---

### Pitfall 6: UNC/Network Paths

**What goes wrong:** `\\server\share\path` doesn't work in most bash implementations.

**UNC path challenges:**
- Git Bash: Use `//server/share/path` (forward slashes, no drive letter)
- WSL: Limited support, requires SMB mount
- cmd.exe: Doesn't support `cd` to UNC paths directly

**How to detect:** Path starts with `\\` or `//` followed by server name.

**Prevention - use mapped drives or warn:**
```javascript
if (path.startsWith('\\\\') || path.startsWith('//')) {
  console.error('Network paths are not supported. Please map the network drive first.');
  return { success: false, reason: 'unc_path_not_supported' };
}
```

**Workaround with pushd:**
```cmd
:: In cmd.exe, pushd maps a temporary drive
pushd \\server\share\path
:: Now you can run commands
popd
```

## wt.exe Pitfalls

### Pitfall 7: Default Profile Assumption

**What goes wrong:** Code assumes `wt.exe bash` will spawn Git Bash, but user's default profile might be WSL, PowerShell, or cmd.

**Root cause:** `wt.exe` spawns whatever the user has configured as default, not necessarily bash.

**How to detect:** Error messages show `/bin/bash` (WSL) instead of `/usr/bin/bash` (Git Bash).

**Prevention options:**

**Option A - Force profile by name:**
```javascript
spawn('wt.exe', ['--profile', 'Git Bash', 'bash', '-c', command]);
```
Caveat: Fails if user hasn't created a profile named "Git Bash".

**Option B - Explicitly invoke Git Bash binary:**
```javascript
const gitBashPath = 'C:\\Program Files\\Git\\bin\\bash.exe';
spawn('wt.exe', ['--title', 'GSD', gitBashPath, '--login', '-c', command]);
```
Caveat: Assumes standard install location.

**Option C - Don't use wt.exe for bash scripts:**
```javascript
// Use cmd.exe which reliably spawns Git Bash via PATH
spawn('cmd.exe', ['/c', 'start', 'bash', '--login', '-c', command]);
```
Most reliable but uglier window management.

---

### Pitfall 8: wt.exe January 2025 Bug (KB5050021)

**What goes wrong:** After Windows Update KB5050021, `wt.exe` fails to launch programmatically.

**Symptoms:**
- No error message displayed
- Process appears briefly in Task Manager, then disappears
- Terminal opens fine from Start menu

**How to detect:** Check Windows version and recent updates.

**Prevention:** Have fallback to cmd.exe or PowerShell when wt.exe launch fails silently.

**Status:** Microsoft is aware; may be fixed in future updates. Check [GitHub issue #18440](https://github.com/microsoft/terminal/issues/18440).

---

### Pitfall 9: Working Directory with -d Flag

**What goes wrong:** The `-d` flag sets initial directory but doesn't affect subsequent `cd` commands in scripts.

**Example:**
```javascript
// This sets initial directory correctly
spawn('wt.exe', ['-d', 'C:\\project', 'bash', '-c', 'pwd && cd /other && pwd']);
// First pwd shows C:\project (good)
// But script's cd still needs correct path format
```

**Prevention:** Don't rely on `-d` alone; include `cd` command with proper path format.

---

### Pitfall 10: Window Title with Special Characters

**What goes wrong:** Window title containing spaces or special characters breaks argument parsing.

**Prevention - quote the title:**
```javascript
// WRONG
spawn('wt.exe', ['--title', 'GSD Ralph Loop', ...]);

// RIGHT
spawn('wt.exe', ['--title', '"GSD Ralph Loop"', ...]);
// Or avoid spaces entirely
spawn('wt.exe', ['--title', 'GSD-Ralph', ...]);
```

## Bash Detection Pitfalls

### Pitfall 11: Detecting Bash Type Before Launch

**What goes wrong:** Can't reliably detect which bash will run after launch.

**Challenge:** The bash that responds to pre-launch detection commands may differ from the bash that `wt.exe` ultimately spawns.

**Example:**
```javascript
// This tests the bash in PATH, not the one wt.exe will spawn
const result = execSync('bash -c "echo $OSTYPE"').toString();
// Might return "msys" (Git Bash) but wt.exe spawns WSL
```

**Prevention strategies:**

**Option A - Runtime detection inside script:**
```bash
#!/bin/bash
# Detect and adapt at runtime
if [[ -n "$WSL_DISTRO_NAME" ]]; then
  cd "/mnt/c/path/to/project"
elif [[ "$OSTYPE" == "msys" ]]; then
  cd "/c/path/to/project"
else
  cd "C:/path/to/project"
fi
```

**Option B - Force specific bash binary:**
Don't rely on `bash` in PATH; invoke explicit binary path.

---

### Pitfall 12: $OSTYPE Variable Reliability

**What goes wrong:** `$OSTYPE` values vary across installations.

**Common values:**
| Environment | $OSTYPE |
|-------------|---------|
| Git Bash | `msys` |
| MSYS2 | `msys` |
| MinGW | `msys` |
| Cygwin | `cygwin` |
| WSL (Ubuntu) | `linux-gnu` |
| macOS | `darwin*` |

**How to detect:** `$OSTYPE` alone can't distinguish Git Bash from MSYS2.

**More reliable detection:**
```bash
case "$(uname -s)" in
  MINGW64_NT*|MINGW32_NT*) echo "Git Bash (64-bit or 32-bit)" ;;
  MSYS_NT*) echo "MSYS2" ;;
  CYGWIN_NT*) echo "Cygwin" ;;
  Linux)
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
      echo "WSL: $WSL_DISTRO_NAME"
    else
      echo "Native Linux"
    fi
    ;;
esac
```

---

### Pitfall 13: PATH-Based bash Detection

**What goes wrong:** Multiple bash binaries exist in PATH; wrong one gets invoked.

**Common bash locations on Windows:**
- `C:\Windows\System32\bash.exe` - WSL launcher
- `C:\Program Files\Git\bin\bash.exe` - Git Bash
- `C:\Program Files\Git\usr\bin\bash.exe` - Also Git Bash
- `C:\msys64\usr\bin\bash.exe` - MSYS2
- `C:\cygwin64\bin\bash.exe` - Cygwin

**How to detect:** `where bash` or `which bash` shows all locations.

**Prevention - use full paths:**
```javascript
// Instead of
spawn('bash', [...]);

// Use explicit path
spawn('C:\\Program Files\\Git\\bin\\bash.exe', [...]);
```

## Edge Cases to Handle

### Edge Case 1: Non-ASCII Characters in Path

**Scenario:** User's username or project folder contains non-ASCII characters.

**Example:** `C:\Users\Muller\projekt` or `C:\Users\Jose\proyecto`

**Risk:** Encoding issues when passing paths between Windows and bash.

**Prevention:**
- Use UTF-8 encoding explicitly
- Test with non-ASCII paths
- Avoid shell interpolation; use spawn args array

---

### Edge Case 2: Very Long Paths (>260 characters)

**Scenario:** Deep folder structures or long folder names exceed Windows MAX_PATH.

**Risk:** Classic Windows APIs fail; modern APIs need opt-in.

**Prevention:**
- Warn if path length approaches limit
- Use `\\?\` prefix for long path support on Windows
- Test with realistic deep folder structures

---

### Edge Case 3: Symlinks and Junctions

**Scenario:** Project path includes Windows symlinks or directory junctions.

**Risk:** Path resolution differs between Windows and WSL.

**Prevention:**
- Resolve symlinks to real paths before conversion
- Test with symlinked directories

---

### Edge Case 4: Spaces and Parentheses Together

**Scenario:** Paths like `C:\Program Files (x86)\Git\bin\bash.exe`

**Risk:** Parentheses plus spaces require careful quoting.

**Prevention - escape both:**
```javascript
const safePath = `"${path.replace(/"/g, '\\"')}"`;
```

---

### Edge Case 5: Drive Root Paths

**Scenario:** Project is directly on `C:\` or `D:\`

**Risk:** Trailing slash handling differs:
- `C:\` vs `C:` vs `/c/` vs `/c`

**Prevention:**
```javascript
// Ensure consistent trailing slash handling
const normalized = path.endsWith('/') ? path.slice(0, -1) : path;
```

---

### Edge Case 6: Git Bash Not Installed

**Scenario:** User has WSL but not Git Bash, or vice versa.

**Risk:** Assumed bash binary doesn't exist.

**Prevention:**
- Check for binary existence before attempting launch
- Fall back to alternative terminals
- Provide clear error with installation instructions

## Prevention Strategies

### Strategy 1: Universal Path Resolution at Runtime

Instead of converting paths before launch, let the bash script figure it out:

```bash
# universal-cd.sh
# Try each path format until one works
resolve_path() {
  local windows_path="$1"

  # Try cygpath if available (Git Bash, MSYS2, Cygwin)
  if command -v cygpath &>/dev/null; then
    cygpath -u "$windows_path" 2>/dev/null && return
  fi

  # Try wslpath if available (WSL)
  if command -v wslpath &>/dev/null; then
    wslpath -u "$windows_path" 2>/dev/null && return
  fi

  # Manual conversion - try each format
  local drive="${windows_path%%:*}"
  local rest="${windows_path#*:}"
  rest="${rest//\\//}"  # Backslash to forward slash
  drive="${drive,,}"    # Lowercase drive letter

  # Try WSL format first
  if [[ -d "/mnt/$drive$rest" ]]; then
    echo "/mnt/$drive$rest"
  # Try Git Bash format
  elif [[ -d "/$drive$rest" ]]; then
    echo "/$drive$rest"
  # Try Cygwin format
  elif [[ -d "/cygdrive/$drive$rest" ]]; then
    echo "/cygdrive/$drive$rest"
  else
    # Last resort - return as-is
    echo "$windows_path"
  fi
}

cd "$(resolve_path "$1")" || exit 1
```

### Strategy 2: Force Specific Bash Binary

Don't rely on `bash` in PATH:

```javascript
const BASH_CANDIDATES = [
  'C:\\Program Files\\Git\\bin\\bash.exe',
  'C:\\Program Files (x86)\\Git\\bin\\bash.exe',
  'C:\\Git\\bin\\bash.exe',
  process.env.USERPROFILE + '\\scoop\\apps\\git\\current\\bin\\bash.exe'
];

function findGitBash() {
  for (const candidate of BASH_CANDIDATES) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return null;
}
```

### Strategy 3: Avoid wt.exe for Bash Scripts

Use cmd.exe which has predictable behavior:

```javascript
// cmd.exe reliably spawns bash from PATH
spawn('cmd.exe', ['/c', 'start', 'cmd', '/k', 'bash --login -c "cd /c/path && ./script.sh"']);
```

### Strategy 4: Test Matrix

Always test across all scenarios:

| Test Case | Terminal | Default Profile | Expected Result |
|-----------|----------|-----------------|-----------------|
| 1 | Windows Terminal | Git Bash | Works |
| 2 | Windows Terminal | WSL | Works |
| 3 | Windows Terminal | PowerShell | Works |
| 4 | cmd.exe | N/A | Works |
| 5 | PowerShell | N/A | Works |
| 6 | Git Bash standalone | N/A | Works |
| 7 | Path with spaces | Any | Works |
| 8 | Path with special chars | Any | Works |
| 9 | Network path | Any | Clear error |
| 10 | Git not installed | Any | Clear error |

### Strategy 5: Graceful Degradation

Always have a fallback:

```javascript
function launchTerminal() {
  try {
    // Try wt.exe first (best UX)
    return launchWindowsTerminal();
  } catch (e) {
    console.log('Windows Terminal failed, trying cmd.exe');
    try {
      return launchCmd();
    } catch (e) {
      // Final fallback - show manual instructions
      showManualInstructions();
      return { success: false };
    }
  }
}
```

## Summary: Root Cause Analysis

The v1.2 bug stems from a single root cause with multiple manifestations:

**Root Cause:** `wt.exe` spawns the user's default terminal profile, which may be any of:
- Git Bash (expects `/c/Users/...`)
- WSL bash (expects `/mnt/c/Users/...`)
- Cygwin bash (expects `/cygdrive/c/Users/...`)
- PowerShell (expects `C:\Users\...`)
- cmd.exe (expects `C:\Users\...`)

**Why previous fixes failed:** Each fix assumed a specific bash variant would run.

**Correct approach:** Either:
1. Force a specific bash binary (bypass default profile), OR
2. Resolve paths at runtime inside the bash script, OR
3. Don't use wt.exe for bash scripts (use cmd.exe with predictable behavior)

## Sources

### Primary (HIGH confidence - official documentation)
- [Windows Terminal Command Line Arguments](https://learn.microsoft.com/en-us/windows/terminal/command-line-arguments) - Microsoft Learn
- [Node.js child_process Documentation](https://nodejs.org/api/child_process.html) - Official Node.js docs
- [MSYS2 Filesystem Paths](https://www.msys2.org/docs/filesystem-paths/) - MSYS2 official docs
- [cygpath Documentation](https://cygwin.com/cygwin-ug-net/cygpath.html) - Cygwin official docs

### Secondary (MEDIUM confidence - verified community resources)
- [Windows Terminal KB5050021 Issue](https://github.com/microsoft/terminal/issues/18440) - GitHub issue tracking
- [wslpath GitHub](https://github.com/Milly/wslpath) - Path conversion tool
- [Detect OS in bash](https://gist.github.com/prabirshrestha/3080525) - Community pattern
- [Git Bash vs WSL bash path conversion](https://github.com/microsoft/terminal/issues/1772) - Microsoft Terminal issue
- [Using Git Bash with Windows Terminal](https://medium.com/@techpreacher/using-git-bash-with-the-microsoft-terminal-bd1f71fa17a1) - Medium article
- [child_process.spawn path issues on Windows](https://github.com/nodejs/node/issues/3116) - Node.js GitHub issue
- [Spaces in Windows paths with WSL](https://github.com/microsoft/WSL/issues/1766) - WSL GitHub issue

### Project Experience (HIGH confidence - validated through failures)
- v1.2 development commits: `307cb70`, `8502138`, `82ae4c1`, `538155e`, `28739db`
- Bug documentation: `.planning/todos/v1.2-terminal-path-resolution.md`

---
*Last updated: 2026-01-21*
*Valid until: Path handling fundamentals are stable; wt.exe bugs may be fixed in updates*
