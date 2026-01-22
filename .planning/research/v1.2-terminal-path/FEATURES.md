# Features Research: Path Resolution Patterns

**Domain:** Terminal path resolution for Windows bash variants
**Researched:** 2026-01-21
**Overall Confidence:** HIGH (verified with official documentation and battle-tested patterns)

## Executive Summary

Path resolution across Windows bash variants (Git Bash, WSL, Cygwin) is a well-understood problem with multiple proven solutions. The key insight is that **each bash variant has built-in tools** for path translation - the challenge is invoking the right tool for the active environment.

There are three viable approaches: (1) detect bash type and use the correct format, (2) use built-in conversion tools like `cygpath` or `wslpath`, or (3) implement a fallback chain. Major tools (VS Code, Docker, JetBrains) each take different approaches based on their constraints.

**Recommended pattern:** Detect bash type via `$OSTYPE` and use the appropriate built-in converter, with a fallback chain as safety net.

---

## 1. Universal Path Resolution Patterns

### Pattern A: Built-in Path Converters (RECOMMENDED)

Each bash variant provides a dedicated path conversion utility:

| Bash Variant | Converter | Usage |
|--------------|-----------|-------|
| Git Bash / MSYS2 | `cygpath` | `cygpath -u "C:\Users\..."` -> `/c/Users/...` |
| WSL | `wslpath` | `wslpath -u "C:\Users\..."` -> `/mnt/c/Users/...` |
| Cygwin | `cygpath` | `cygpath -u "C:\Users\..."` -> `/cygdrive/c/Users/...` |

**Implementation:**
```bash
# Universal: let the active bash's converter handle it
cd "$(cygpath -u "$WINDOWS_PATH" 2>/dev/null || wslpath -u "$WINDOWS_PATH" 2>/dev/null || echo "$WINDOWS_PATH")"
```

**Reliability:** HIGH - These are official, maintained utilities
**Complexity:** LOW - Single command with fallback
**Battle-tested:** YES - Used by Docker, VS Code, countless scripts

**Handles edge cases:**
- Paths with spaces: YES (use quotes)
- Special characters: YES (converters handle escaping)
- Network paths: PARTIAL (UNC paths need special handling)

**Source:** [MSYS2 Filesystem Paths Documentation](https://www.msys2.org/docs/filesystem-paths/), [Cygwin cygpath manual](https://cygwin.com/cygwin-ug-net/cygpath.html)

---

### Pattern B: Detection + Format Selection

Detect the bash type first, then apply the correct path format directly.

**Detection via `$OSTYPE`:**
```bash
case "$OSTYPE" in
  msys*|cygwin*)
    # Git Bash or Cygwin - use /c/ prefix
    ;;
  linux*)
    # Could be native Linux or WSL - check further
    if grep -qi microsoft /proc/version 2>/dev/null; then
      # WSL - use /mnt/c/ prefix
    else
      # Native Linux - paths work as-is
    fi
    ;;
esac
```

**Performance advantage:** No subprocess spawn for converter
**Reliability:** HIGH - `$OSTYPE` is a bash built-in
**Complexity:** MEDIUM - Need to handle edge cases

**Source:** [GitHub Gist: OS detection in bash](https://gist.github.com/prabirshrestha/3080525), [WSL Issue #844](https://github.com/microsoft/WSL/issues/844)

---

### Pattern C: Fallback Chain (SAFETY NET)

Try multiple path formats in order until one works:

```bash
try_cd() {
  cd "$1" 2>/dev/null && return 0
  return 1
}

# Try all known formats
try_cd "/mnt/c${WINDOWS_PATH:2}" ||  # WSL format
try_cd "/c${WINDOWS_PATH:2}" ||       # Git Bash format
try_cd "/cygdrive/c${WINDOWS_PATH:2}" ||  # Cygwin format
try_cd "$WINDOWS_PATH" ||             # Native Windows
{ echo "Failed to resolve path"; exit 1; }
```

**Reliability:** HIGHEST - Will find working format if any exists
**Complexity:** LOW - Simple conditional chain
**Performance:** Slower (multiple attempts)
**Battle-tested:** YES - Common in cross-platform scripts

---

### Pattern D: Windows Path with Auto-Conversion

Pass Windows paths directly and rely on automatic conversion (MSYS2/Git Bash only):

```bash
# Git Bash auto-converts when calling native executables
cd "C:/Users/Jameson/project"  # Works in Git Bash directly
```

**Limitation:** Only works in MSYS2-based shells (Git Bash), not WSL or Cygwin
**Reliability:** MEDIUM - Depends on bash variant
**Complexity:** LOWEST - No conversion needed
**Battle-tested:** YES but variant-specific

---

## 2. Bash Type Detection Approaches

### Approach 1: `$OSTYPE` Variable (RECOMMENDED)

**How it works:** Built-in bash variable set at compile time

| Value | Environment |
|-------|-------------|
| `msys` | Git Bash / MSYS2 |
| `cygwin` | Cygwin |
| `linux-gnu` | Native Linux or WSL |
| `darwin*` | macOS |

**WSL disambiguation:**
```bash
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "WSL"
  else
    echo "Native Linux"
  fi
fi
```

**Reliability:** HIGH
**Performance:** Instant (no subprocess)
**Availability:** All bash versions

**Source:** [neofetch Issue #433](https://github.com/dylanaraps/neofetch/issues/433)

---

### Approach 2: `uname` Command

**How it works:** Returns OS/kernel information

| `uname -s` Output | Environment |
|-------------------|-------------|
| `MINGW64_NT*` | Git Bash (64-bit) |
| `CYGWIN_NT*` | Cygwin |
| `Linux` | Native Linux or WSL |

**Reliability:** HIGH
**Performance:** Subprocess spawn (slower than `$OSTYPE`)
**Portability:** POSIX standard

---

### Approach 3: Check for Environment Markers

**WSL-specific:**
```bash
# WSL sets this variable
[ -n "$WSL_DISTRO_NAME" ] && echo "WSL"

# Or check for WSL-specific filesystem
[ -d "/mnt/c/Windows" ] && echo "WSL"
```

**Git Bash-specific:**
```bash
# MSYSTEM is set in MSYS2/Git Bash
[ -n "$MSYSTEM" ] && echo "Git Bash"

# Or check for Git Bash paths
[ -d "/mingw64" ] && echo "Git Bash"
```

**Reliability:** MEDIUM - Depends on environment configuration
**Complexity:** LOW

---

### Approach 4: Pre-spawn Detection from Node.js

**How it works:** Before spawning bash, run a detection command

```javascript
const { execSync } = require('child_process');

function detectBashType() {
  try {
    const ostype = execSync('bash -c "echo $OSTYPE"').toString().trim();
    if (ostype.startsWith('msys')) return 'gitbash';
    if (ostype.startsWith('cygwin')) return 'cygwin';
    if (ostype === 'linux-gnu') {
      const version = execSync('bash -c "cat /proc/version"').toString();
      return version.toLowerCase().includes('microsoft') ? 'wsl' : 'linux';
    }
  } catch (e) {
    return 'unknown';
  }
}
```

**Reliability:** HIGH
**Performance:** Adds ~100-200ms startup time
**Complexity:** MEDIUM

**CAUTION:** The `bash` that responds to this detection may not be the same bash that `wt.exe` spawns with its default profile. Windows Terminal has its own profile system.

---

## 3. Fallback Chain Patterns

### Recommended Chain Order

Based on path format specificity and commonality:

```bash
resolve_path() {
  local win_path="$1"

  # 1. Try built-in converter (most reliable)
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$win_path" 2>/dev/null && return 0
  fi
  if command -v wslpath >/dev/null 2>&1; then
    wslpath -u "$win_path" 2>/dev/null && return 0
  fi

  # 2. Pattern-based fallback
  local drive="${win_path:0:1}"
  local path_part="${win_path:2}"
  path_part="${path_part//\\//}"  # backslash to forward slash

  # Try each format
  for prefix in "/mnt/${drive,,}" "/${drive,,}" "/cygdrive/${drive,,}"; do
    [ -d "${prefix}${path_part}" ] && echo "${prefix}${path_part}" && return 0
  done

  # 3. Raw Windows path (some shells accept this)
  echo "$win_path"
}
```

### Why This Order?

1. **cygpath/wslpath first:** Native tools know their environment best
2. **WSL format second:** Most common modern Windows dev environment
3. **Git Bash format third:** Very common, but less than WSL now
4. **Cygwin format fourth:** Less common, legacy
5. **Raw Windows last:** Only works in specific contexts

---

## 4. How Major Tools Solve This

### VS Code

**Approach:** Separate extensions for each environment

- **Remote-WSL Extension:** Runs entirely inside WSL, no path translation needed
- **Native Windows:** Uses Windows paths, shell profile determines formatting
- **Git Path Handling:** Dedicated `git.path` setting; recommends using `wsl.exe /usr/bin/git` wrapper

**Key insight:** VS Code avoids the problem by running commands **inside** the target environment rather than translating paths across environments.

**Source:** [VS Code WSL Documentation](https://code.visualstudio.com/docs/remote/wsl)

---

### Docker Desktop

**Approach:** Environment-specific workarounds + user configuration

**For Git Bash (MSYS2):**
```bash
# Disable MSYS path auto-conversion
export MSYS_NO_PATHCONV=1
docker run -v "$(pwd)":/app ...
```

**For WSL:**
- Recommends configuring `/etc/wsl.conf` to mount at `/c` instead of `/mnt/c`
- Or accept the `/mnt/c` format in volume mounts

**Key insight:** Docker documents the problem and provides environment-specific solutions rather than universal resolution.

**Source:** [Docker Git Bash Workaround](https://gist.github.com/borekb/cb1536a3685ca6fc0ad9a028e6a959e3), [Docker Troubleshooting](https://docs.docker.com/desktop/troubleshoot-and-support/troubleshoot/topics/)

---

### JetBrains IDEs (IntelliJ, WebStorm, etc.)

**Approach:** Explicit configuration + built-in path translation

- Terminal shell path: User configures explicitly (e.g., `wsl.exe --distribution Ubuntu`)
- Path conversion: Internal `WslPath` class handles `/mnt/c` <-> `C:\` translation
- Starting directory: Must be valid for the target shell type

**Key insight:** JetBrains requires explicit user configuration of which shell to use, then handles path translation internally.

**Source:** [JetBrains WSL Documentation](https://www.jetbrains.com/help/idea/how-to-use-wsl-development-environment-in-product.html)

---

### OpenAI Codex CLI

**Approach:** Explicit bash selection + fallback (still buggy)

**Known issue (as of 2025):** Codex hardcodes WSL detection, ignoring user's PATH resolution for MSYS2 bash. This causes performance issues as WSL access to Windows files via `/mnt/c` is slower.

**Attempted workaround:**
```powershell
# Users try to point bash to MSYS2
$env:Path = "D:\msys64\usr\bin;" + $env:Path
```

But Codex still uses `C:\Windows\System32\bash.exe` (WSL) because system paths take precedence.

**Key insight:** Codex's approach is considered a bug. The community wants explicit shell configuration rather than auto-detection.

**Source:** [Codex Issue #3159](https://github.com/openai/codex/issues/3159)

---

## 5. Recommended Pattern for GSD

Based on research, here is the recommended implementation:

### Primary Strategy: Explicit Shell Selection

Instead of relying on `wt.exe` default profile (which varies per user), spawn a **specific shell**:

```javascript
// Option A: Force Git Bash explicitly
spawn('wt.exe', [
  'C:\\Program Files\\Git\\bin\\bash.exe',
  '--login', '-c',
  `cd "${bashPath}" && bash "${scriptPath}"`
]);

// Option B: Force WSL explicitly (if WSL is target)
spawn('wt.exe', [
  'wsl.exe', '--cd', windowsPath,
  'bash', scriptPath
]);
```

### Secondary Strategy: Runtime Path Resolution

Pass Windows path to bash, let bash resolve it:

```bash
#!/bin/bash
# At the start of ralph.sh

resolve_and_cd() {
  local target="$1"

  # Already in correct format?
  if [ -d "$target" ]; then
    cd "$target" && return 0
  fi

  # Try converter tools
  if command -v cygpath >/dev/null 2>&1; then
    cd "$(cygpath -u "$target")" 2>/dev/null && return 0
  fi
  if command -v wslpath >/dev/null 2>&1; then
    cd "$(wslpath -u "$target")" 2>/dev/null && return 0
  fi

  # Pattern-based fallback for C:\path or C:/path
  if [[ "$target" =~ ^([A-Za-z]):[/\\] ]]; then
    local drive="${BASH_REMATCH[1]}"
    local rest="${target:3}"
    rest="${rest//\\//}"

    for prefix in "/mnt/${drive,,}" "/${drive,,}" "/cygdrive/${drive,,}"; do
      [ -d "${prefix}/${rest}" ] && cd "${prefix}/${rest}" && return 0
    done
  fi

  echo "ERROR: Could not resolve path: $target"
  return 1
}

# Usage
resolve_and_cd "$1"
```

### Tertiary Strategy: Fallback Terminal

If `wt.exe` proves unreliable, fall back to `cmd.exe` which always spawns Git Bash consistently:

```javascript
// In terminal detection priority
const TERMINAL_CONFIG = {
  win32: [
    // REMOVE wt.exe from priority, or
    // { name: 'wt.exe', ... },  // Skip due to profile ambiguity
    { name: 'cmd.exe', launcher: launchCmd },  // Reliable Git Bash
    // ...
  ]
}
```

---

## 6. Edge Cases and Gotchas

### Paths with Spaces

**Problem:** `C:\Program Files\...` -> `/c/Program Files/...` breaks without quotes

**Solution:** Always quote paths in commands:
```bash
cd "/c/Program Files/Git"  # Correct
cd /c/Program Files/Git    # WRONG - interpreted as two arguments
```

### Special Characters

**Problem:** Characters like `&`, `$`, `(`, `)` in paths

**Solution:** Use single quotes for literal interpretation, or escape:
```bash
cd '/c/Users/O'"'"'Brien'  # For O'Brien (escaped single quote)
cd "/c/Data/2024 & Beyond"  # Double quotes work for &
```

### UNC Paths (Network Shares)

**Problem:** `\\server\share` doesn't map cleanly to Unix format

**Git Bash:** `//server/share`
**WSL:** `//wsl.localhost/...` for WSL shares, network shares need mounting
**Cygwin:** `//server/share`

### Path Length Limits

**Windows:** 260 characters (without long path support)
**Unix-on-Windows:** Typically no limit, but accessing Windows paths respects Windows limits

---

## 7. Confidence Assessment

| Pattern | Confidence | Reasoning |
|---------|------------|-----------|
| `cygpath`/`wslpath` converters | HIGH | Official tools, documented, maintained |
| `$OSTYPE` detection | HIGH | Bash built-in, universally available |
| Fallback chain | HIGH | Proven pattern, worst-case reliable |
| VS Code's approach | HIGH | Documented, production-proven |
| Docker workarounds | MEDIUM | Works but requires user configuration |
| Pre-spawn detection | MEDIUM | Works but may not match wt.exe profile |

---

## 8. Sources

### Official Documentation
- [MSYS2 Filesystem Paths](https://www.msys2.org/docs/filesystem-paths/)
- [Cygwin cygpath Manual](https://cygwin.com/cygwin-ug-net/cygpath.html)
- [VS Code WSL Documentation](https://code.visualstudio.com/docs/remote/wsl)
- [VS Code Terminal Profiles](https://code.visualstudio.com/docs/terminal/profiles)
- [Windows Terminal Profile Settings](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-general)
- [JetBrains WSL Documentation](https://www.jetbrains.com/help/idea/how-to-use-wsl-development-environment-in-product.html)
- [Docker Troubleshooting](https://docs.docker.com/desktop/troubleshoot-and-support/troubleshoot/topics/)

### GitHub Issues and Discussions
- [Windows Terminal Path Translation Request (Issue #1772)](https://github.com/microsoft/terminal/issues/1772)
- [WSL Detection (Issue #844)](https://github.com/microsoft/WSL/issues/844)
- [OpenAI Codex MSYS2/WSL Issue #3159](https://github.com/openai/codex/issues/3159)
- [wslpath Repository](https://github.com/MiffOttah/wslpath)

### Community Resources
- [Docker Git Bash Path Workaround](https://gist.github.com/borekb/cb1536a3685ca6fc0ad9a028e6a959e3)
- [OS Detection in Bash (Gist)](https://gist.github.com/prabirshrestha/3080525)
- [Guide to Shells on Windows](https://blog.codefarm.me/2024/08/29/guide-to-shells-on-windows-git-bash-cygwin-wsl/)
