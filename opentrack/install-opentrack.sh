#!/usr/bin/env bash
#
# One-shot installer for opentrack + opentrack-launcher on SteamOS / Steam Machine
# (and any other Linux with the native, non-flatpak Steam).
#
# What it does:
#   1. Removes every old opentrack-launcher install (launcher script, downloaded
#      opentrack, generated per-game .bat scripts, manually added DLLs).
#   2. Installs the latest opentrack-launcher from GitHub and patches it so it
#      - re-adds icuuc.dll every time opentrack is (re)installed or updated
#        (opentrack 2026+ needs it, Proton doesn't ship it, see
#        https://github.com/markx86/opentrack-launcher/issues/14)
#      - can use a bundled 7-Zip if the system has none
#      - doesn't crash (and take the game with it) when GitHub is unreachable
#      - keeps opentrack running for games that start through a small launcher
#        (Farming Simulator: FarmingSimulator2025.exe -> x64/FarmingSimulator2025Game.exe)
#   3. Downloads the latest opentrack right away and checks icuuc.dll is in place.
#
# Usage (in Desktop Mode, open Konsole):
#   curl -fsSL https://raw.githubusercontent.com/tylerstyle/support/main/opentrack/install-opentrack.sh | bash
# or, after downloading it:
#   bash install-opentrack.sh        # asks before deleting anything
#   bash install-opentrack.sh -y     # no questions
#
# Game settings made inside opentrack live in each game's Proton prefix and are
# NOT touched by this script.

set -euo pipefail

LAUNCHER_URL="https://raw.githubusercontent.com/markx86/opentrack-launcher/master/opentrack-launcher"

# Microsoft-compatible ICU DLLs (icuuc.dll is a small forwarder to icu.dll, which Proton has).
ICU_URL="https://github.com/FaithLife-Community/icu/releases/download/72.1-custom%2B4/icu-win.tar.gz"
ICU_SHA256="2813ea1205fcf9d9a7930339dae181dc3e299b2391f2f4879c5e542be43f3a7f"

# Official 7-Zip for Linux, only used if the system has no 7z/7za.
SEVENZIP_URL="https://github.com/ip7z/7zip/releases/download/25.01/7z2501-linux-x64.tar.xz"
SEVENZIP_SHA256="4ca3b7c6f2f67866b92622818b58233dc70367be2f36b498eb0bdeaaa44b53f4"

LAUNCHER_HOME="$HOME/.local/share/opentrack-launcher"
LAUNCHER_BIN="$HOME/.local/bin/opentrack-launcher"
SETUP_BIN="$HOME/.local/bin/opentrack-setup"
SETUP_DESKTOP="$HOME/.local/share/applications/opentrack-setup.desktop"
SETUP_DESKTOP_ICON="$HOME/Desktop/opentrack-setup.desktop"

if [ -t 1 ]; then
    BOLD=$'\e[1m'; RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RESET=$'\e[0m'
else
    BOLD=""; RED=""; GREEN=""; YELLOW=""; RESET=""
fi

step() { echo; echo "${BOLD}==> $*${RESET}"; }
ok()   { echo "  ${GREEN}OK${RESET}  $*"; }
warn() { echo "  ${YELLOW}!!${RESET}  $*"; }
die()  { echo; echo "${RED}${BOLD}ERROR:${RESET} $*" >&2; echo "Fix the problem above (or ask for help with a screenshot of this window) and run this script again." >&2; exit 1; }

ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        -h|--help) echo "usage: install-opentrack.sh [-y|--yes]"; exit 0 ;;
        *) die "unknown option: $arg" ;;
    esac
done

confirm() {
    [ "$ASSUME_YES" = 1 ] && return 0
    local answer
    # read from the terminal so this also works with `curl ... | bash`
    if ! read -r -p "$1 [Y/n] " answer </dev/tty; then
        return 0
    fi
    case "$answer" in [nN]*) return 1 ;; *) return 0 ;; esac
}

download() { # url dest
    curl -fL --retry 3 --progress-bar -o "$2" "$1" || die "download failed: $1 (is the internet connected?)"
}

check_sha256() { # file expected
    local actual
    actual="$(sha256sum "$1" | cut -d' ' -f1)"
    [ "$actual" = "$2" ] || die "checksum mismatch for $(basename "$1") (got $actual), refusing to install it"
}

# --------------------------------------------------------------------------
step "Checking system"

[ "$(id -u)" -ne 0 ] || die "do not run this with sudo, run it as your normal user"
for cmd in python3 curl tar sha256sum; do
    command -v "$cmd" >/dev/null || die "'$cmd' is missing"
done
ok "python3, curl and tar found"

if [ -d "$HOME/.local/share/Steam" ] || [ -d "$HOME/.steam/steam" ]; then
    ok "Steam found"
elif [ -d "$HOME/.var/app/com.valvesoftware.Steam" ]; then
    die "only the flatpak version of Steam was found; this script is for the normal Steam (as on SteamOS). See the 'With Steam Flatpak' section of https://github.com/markx86/opentrack-launcher"
else
    die "Steam does not seem to be installed for this user ($USER)"
fi

if pgrep -f 'opentrack\.exe' >/dev/null 2>&1; then
    die "opentrack (or a game started with it) is running, close the game first"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --------------------------------------------------------------------------
step "Looking for old installs"

OLD=()
for p in "$LAUNCHER_HOME" "$LAUNCHER_BIN" "$SETUP_BIN" "$SETUP_DESKTOP" "$SETUP_DESKTOP_ICON"; do
    [ -e "$p" ] && OLD+=("$p")
done
if [ "${#OLD[@]}" -eq 0 ]; then
    ok "none found"
else
    for p in "${OLD[@]}"; do echo "  will delete: $p"; done
    confirm "Delete these and reinstall?" || die "cancelled"
    rm -rf -- "${OLD[@]}"
    ok "old install removed"
fi

if [ -e /usr/local/bin/opentrack-launcher ]; then
    warn "an old system-wide copy exists at /usr/local/bin/opentrack-launcher (needs sudo to remove):"
    warn "    sudo rm /usr/local/bin/opentrack-launcher"
    warn "games whose launch options say just 'opentrack-launcher %command%' still use that old copy!"
fi

mkdir -p "$LAUNCHER_HOME/bin" "$LAUNCHER_HOME/icu/x64" "$LAUNCHER_HOME/icu/x86" "$(dirname "$LAUNCHER_BIN")"

# --------------------------------------------------------------------------
step "Downloading icuuc.dll fix"

download "$ICU_URL" "$TMP/icu.tar.gz"
check_sha256 "$TMP/icu.tar.gz" "$ICU_SHA256"
mkdir "$TMP/icu"
tar -xzf "$TMP/icu.tar.gz" -C "$TMP/icu" \
    ./windows/system32/icuuc.dll ./windows/syswow64/icuuc.dll ./windows/globalization/ICU/LICENSE-ICU.txt
cp "$TMP/icu/windows/system32/icuuc.dll" "$LAUNCHER_HOME/icu/x64/icuuc.dll"
cp "$TMP/icu/windows/syswow64/icuuc.dll" "$LAUNCHER_HOME/icu/x86/icuuc.dll"
cp "$TMP/icu/windows/globalization/ICU/LICENSE-ICU.txt" "$LAUNCHER_HOME/icu/"
ok "icuuc.dll (32 and 64 bit) stored in $LAUNCHER_HOME/icu"

# --------------------------------------------------------------------------
step "Checking for 7-Zip (needed to unpack opentrack)"

if command -v 7z >/dev/null || command -v 7za >/dev/null; then
    ok "system 7-Zip found"
else
    download "$SEVENZIP_URL" "$TMP/7z.tar.xz"
    check_sha256 "$TMP/7z.tar.xz" "$SEVENZIP_SHA256"
    tar -xJf "$TMP/7z.tar.xz" -C "$LAUNCHER_HOME/bin" 7zzs License.txt
    chmod +x "$LAUNCHER_HOME/bin/7zzs"
    ok "no system 7-Zip, installed a private copy to $LAUNCHER_HOME/bin/7zzs"
fi

# --------------------------------------------------------------------------
step "Installing opentrack-launcher"

download "$LAUNCHER_URL" "$TMP/opentrack-launcher"

# Patch the launcher. Every anchor must match exactly once, otherwise upstream
# changed and we stop instead of installing something half-patched.
python3 -I - "$TMP/opentrack-launcher" <<'PATCH' || die "could not patch opentrack-launcher (upstream script changed?)"
import sys

path = sys.argv[1]
src = open(path).read()

FIXICUUC = '''# opentrack 2026+ needs icuuc.dll, which Proton does not ship (it only has icu.dll).
# Put a forwarder icuuc.dll (-> icu.dll) next to opentrack.exe, matching its architecture.
# See https://github.com/markx86/opentrack-launcher/issues/14
def fixicuuc():
    install = join(LAUNCHERHOME, "install")
    opentrackexec = join(install, "opentrack.exe")
    if not isfile(opentrackexec):
        return
    with open(opentrackexec, mode="rb") as f:
        header = f.read(4096)
    peoffset = int.from_bytes(header[0x3c:0x40], "little")
    machine = int.from_bytes(header[peoffset+4:peoffset+6], "little")
    arch = "x64" if machine == 0x8664 else "x86"
    icuuc = join(LAUNCHERHOME, "icu", arch, "icuuc.dll")
    dest = join(install, "icuuc.dll")
    if not isfile(icuuc):
        error("missing " + icuuc + ", opentrack might not start; run install-opentrack.sh again")
        return
    if not isfile(dest):
        info("adding " + arch + " icuuc.dll to opentrack install...")
    copyfile(icuuc, dest)

def getopentrack():
    dlopentrack()
    fixicuuc()
'''

WAITFORGAME = '''# Some games start through a small launcher that quits as soon as the real game runs
# (Farming Simulator: FarmingSimulator2025.exe -> x64/FarmingSimulator2025Game.exe).
# "start /wait" only waits for the launcher, so the .bat would close opentrack right away.
# For those games, also wait until the real game has exited.
def realgameexe(appexec):
    x64 = join(dirname(appexec), "x64")
    if not isdir(x64):
        return None
    wanted = splitext(basename(appexec))[0].lower() + "game.exe"
    return next((name for name in listdir(x64) if name.lower() == wanted), None)

def waitforgame(appexec):
    game = realgameexe(appexec)
    if not game:
        return []
    info("game starts through a launcher, also waiting for " + game + "...")
    # CSV, because tasklist's table cuts names after 25 characters (Wine's find has no /I)
    return [
        ":waitgame\\r\\n",
        "ping -n 3 127.0.0.1 >nul\\r\\n",
        "tasklist /FO CSV /NH | findstr /I /L /C:\\"" + game + "\\" >nul && goto waitgame\\r\\n",
    ]

def getlaunchscript(appid, opentrackexec):
'''

patches = [
    ("#!/usr/bin/env python3\n",
     "#!/usr/bin/env python3\n# Patched by install-opentrack.sh (icuuc.dll fix, bundled 7-Zip fallback, offline fix, launcher-game wait)\n"),
    ("from os.path import join, isfile, isdir, abspath\n",
     "from os.path import join, isfile, isdir, abspath, basename, dirname, splitext\n"),
    ("from os import makedirs, mkdir, environ, remove\n",
     "from os import makedirs, mkdir, environ, remove, listdir\n"),
    ("from shutil import which, rmtree\n",
     "from shutil import which, rmtree, copyfile\n"),
    ("def getlaunchscript(appid, opentrackexec):\n",
     WAITFORGAME),
    (r' + appargs + "\r\n",' + "\n",
     r' + appargs + "\r\n",' + "\n                *waitforgame(appexec),\n"),
    # upstream bug: NameError when GitHub can't be reached, which kills the game launch
    ("    except URLError:\n        error(msg)(",
     "    except URLError as e:\n        error("),
    ("def getopentrack():\n    dlopentrack()\n",
     FIXICUUC),
    ('    if not ZIPBINARY:\n        panic("7z is not installed")',
     '    if not ZIPBINARY and isfile(join(LAUNCHERHOME, "bin/7zzs")):\n'
     '        ZIPBINARY = join(LAUNCHERHOME, "bin/7zzs")\n'
     '    if not ZIPBINARY:\n        panic("7z is not installed")'),
]
for old, new in patches:
    count = src.count(old)
    if count != 1:
        sys.exit("anchor found %d times: %r" % (count, old[:60]))
    src = src.replace(old, new)

open(path, "w").write(src)
PATCH

install -m 755 "$TMP/opentrack-launcher" "$LAUNCHER_BIN"
ok "installed to $LAUNCHER_BIN"

# --------------------------------------------------------------------------
step "Installing opentrack Setup"

# While a game runs it captures all clicks, so opentrack can't be configured next to it.
# opentrack-setup opens opentrack alone, in the chosen game's Proton prefix (where its settings live).
cat > "$TMP/opentrack-setup" <<'SETUP'
#!/usr/bin/env python3
# opentrack Setup: opens opentrack WITHOUT the game, in that game's Proton prefix, so it can
# be configured (while a game runs, the game captures all clicks).
# Installed by install-opentrack.sh.

import os
import re
import subprocess
import sys
from os.path import isdir, isfile, join

HOME = os.environ["HOME"]
STEAM = join(HOME, ".local/share/Steam")
LAUNCHERHOME = join(HOME, ".local/share/opentrack-launcher")
OPENTRACKEXEC = join(LAUNCHERHOME, "install/opentrack.exe")
LOG = join(LAUNCHERHOME, "setup.log")

def dialog(*args):
    return subprocess.run(["kdialog", "--title", "opentrack Setup", *args], stdout=subprocess.PIPE, text=True)

def fail(msg):
    dialog("--error", msg)
    sys.exit(1)

def vdfvalue(path, key):
    with open(path, errors="replace") as f:
        m = re.search(r'"%s"\s+"([^"]*)"' % re.escape(key), f.read())
    return m.group(1) if m else None

def libraries():
    with open(join(STEAM, "steamapps/libraryfolders.vdf"), errors="replace") as f:
        paths = re.findall(r'"path"\s+"([^"]+)"', f.read())
    return [p.replace("\\\\", "\\") for p in paths] or [STEAM]

def installedapps():
    # appid -> library, from Steam's own index (manifests elsewhere can be stale leftovers)
    with open(join(STEAM, "steamapps/libraryfolders.vdf"), errors="replace") as f:
        text = f.read()
    paths = list(re.finditer(r'"path"\s+"([^"]+)"', text))
    apps = {}
    for i, m in enumerate(paths):
        end = paths[i + 1].start() if i + 1 < len(paths) else len(text)
        block = re.search(r'"apps"\s*\{([^}]*)\}', text[m.end():end])
        if block:
            for appid in re.findall(r'"(\d+)"\s+"\d+"', block.group(1)):
                apps.setdefault(appid, m.group(1).replace("\\\\", "\\"))
    return apps

def findapp(appid):
    for lib in libraries():
        acf = join(lib, "steamapps", "appmanifest_%s.acf" % appid)
        if isfile(acf):
            return lib, acf
    return None, None

def gameexe(appid):
    # the per-game .bat written by opentrack-launcher contains the game's .exe; if the game starts
    # through a launcher, the .bat also waits for the real game .exe, which is what game detection needs
    bat = join(LAUNCHERHOME, "scripts", appid + ".bat")
    if isfile(bat):
        with open(bat, errors="replace") as f:
            text = f.read()
        m = re.search(r'findstr /I /L /C:"([^"]+)"', text) or re.search(r'start /wait "" "([^"]+)"', text)
        if m:
            return m.group(1).split("\\")[-1]
    return None

def protoncommand(compatdata):
    # the Proton (and its Steam Linux Runtime) the game last ran with, or None
    proton = None
    if isfile(join(compatdata, "config_info")):
        with open(join(compatdata, "config_info"), errors="replace") as f:
            for line in f:
                line = line.strip()
                if line.endswith("/files/lib/"):
                    proton = line[:-len("/files/lib/")]
                    break
    if proton and not isfile(join(proton, "proton")):
        # Proton may have been moved to another library since the game last ran
        moved = [join(lib, "steamapps/common", os.path.basename(proton)) for lib in libraries()]
        proton = next((p for p in moved if isfile(join(p, "proton"))), None)
    if not proton:
        return None
    cmd = [join(proton, "proton"), "waitforexitandrun", OPENTRACKEXEC]
    manifest = join(proton, "toolmanifest.vdf")
    runtimeid = vdfvalue(manifest, "require_tool_appid") if isfile(manifest) else None
    if runtimeid:
        lib, acf = findapp(runtimeid)
        entry = acf and join(lib, "steamapps/common", vdfvalue(acf, "installdir") or "", "_v2-entry-point")
        if not entry or not isfile(entry):
            return None
        cmd = [entry, "--verb=waitforexitandrun", "--"] + cmd
    return cmd

def games():
    found = []
    libs = libraries()
    for appid, lib in installedapps().items():
        acf = join(lib, "steamapps", "appmanifest_%s.acf" % appid)
        name = isfile(acf) and vdfvalue(acf, "name")
        if not name or name.startswith(("Proton", "Steam Linux Runtime")):
            continue
        # the prefix is usually next to the game, but can be in another library (e.g. internal storage)
        for prefixlib in [lib] + [l for l in libs if l != lib]:
            compatdata = join(prefixlib, "steamapps/compatdata", appid)
            if isdir(join(compatdata, "pfx")):
                cmd = protoncommand(compatdata)
                if cmd:
                    found.append((appid, name, compatdata, cmd))
                break
    # games already started with opentrack-launcher first
    return sorted(found, key=lambda g: (gameexe(g[0]) is None, g[1].lower()))

if __name__ == "__main__":
    if not isfile(OPENTRACKEXEC):
        fail("opentrack is not installed. Run install-opentrack.sh again.")
    found = games()
    if not found:
        fail("No game found that ran with Proton.\nStart the game once from Steam, quit it and try again.")
    menu = []
    for appid, name, _, _ in found:
        menu += [appid, name + ("   (opentrack launch option set)" if gameexe(appid) else "")]
    choice = dialog("--menu", "Which game do you want to set up opentrack for?\n"
                    "(Game missing? Start it once from Steam, quit it and open opentrack Setup again.)", *menu)
    if choice.returncode != 0:
        sys.exit(0)
    appid = choice.stdout.strip()
    name, compatdata, cmd = next((n, c, x) for a, n, c, x in found if a == appid)
    if subprocess.run(["pgrep", "-f", "AppId=%s( |$)" % appid], stdout=subprocess.DEVNULL).returncode == 0:
        fail(name + " is running. Quit the game first, then start opentrack Setup again.")
    exe = gameexe(appid) or "the game's .exe"
    dialog("--msgbox",
        "opentrack opens now for %s, WITHOUT the game.\n\n"
        "Use the trackpad or a mouse, NOT the touchscreen (it makes opentrack close).\n\n"
        "1. Choose your tracker under Input and usually 'freetrack 2.0 Enhanced' under Output.\n"
        "2. Options > Game detection: tick 'Start profiles from game executable names in this list',\n"
        "    click +, enter %s and pick your profile.\n"
        "    Then tracking starts by itself whenever the game runs.\n"
        "3. Press Start to test it, then close opentrack. Done!" % (name, exe))
    env = dict(os.environ, STEAM_COMPAT_CLIENT_INSTALL_PATH=STEAM, STEAM_COMPAT_DATA_PATH=compatdata,
               SteamAppId=appid, SteamGameId=appid)
    with open(LOG, "w") as log:
        subprocess.run(cmd, env=env, stdout=log, stderr=subprocess.STDOUT)
SETUP
install -m 755 "$TMP/opentrack-setup" "$SETUP_BIN"

mkdir -p "$(dirname "$SETUP_DESKTOP")"
cat > "$SETUP_DESKTOP" <<DESKTOP
[Desktop Entry]
Type=Application
Name=opentrack Setup
Comment=Set up opentrack for a game (opens opentrack without the game)
Exec=$SETUP_BIN
Icon=input-gaming
Terminal=false
Categories=Game;
DESKTOP
chmod +x "$SETUP_DESKTOP"
if [ -d "$HOME/Desktop" ]; then
    cp "$SETUP_DESKTOP" "$SETUP_DESKTOP_ICON"
    ok "installed 'opentrack Setup' (desktop icon and app menu)"
else
    ok "installed 'opentrack Setup' (app menu)"
fi

# --------------------------------------------------------------------------
step "Downloading latest opentrack"

# Use the launcher's own code so the result is exactly what it expects at game start.
python3 -I - "$LAUNCHER_BIN" <<'RUN' || die "downloading/unpacking opentrack failed (see messages above)"
import sys
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader

loader = SourceFileLoader("opentrack_launcher", sys.argv[1])
launcher = module_from_spec(spec_from_loader(loader.name, loader))
loader.exec_module(launcher)
launcher.check7z()
launcher.makehome()
launcher.getopentrack()
RUN

# --------------------------------------------------------------------------
step "Verifying install"

[ -f "$LAUNCHER_HOME/install/opentrack.exe" ] || die "opentrack.exe is missing"
ok "opentrack $(cat "$LAUNCHER_HOME/version.txt" 2>/dev/null || echo '?') installed"

python3 -I - "$LAUNCHER_HOME/install" <<'VERIFY' || die "icuuc.dll check failed"
import sys
from os.path import join, isfile

def machine(path):
    with open(path, "rb") as f:
        header = f.read(4096)
    if header[:2] != b"MZ":
        return None
    pe = int.from_bytes(header[0x3c:0x40], "little")
    return int.from_bytes(header[pe+4:pe+6], "little")

install = sys.argv[1]
icuuc = join(install, "icuuc.dll")
if not isfile(icuuc):
    sys.exit("  icuuc.dll is NOT in " + install)
exe, dll = machine(join(install, "opentrack.exe")), machine(icuuc)
if exe != dll:
    sys.exit("  icuuc.dll architecture (%s) does not match opentrack.exe (%s)" % (hex(dll or 0), hex(exe or 0)))
print("  OK  icuuc.dll present and matches opentrack.exe (%s)" % ("64 bit" if exe == 0x8664 else "32 bit"))
VERIFY

# --------------------------------------------------------------------------
echo
echo "${GREEN}${BOLD}All done!${RESET}"
echo
echo "Now, for every game you want head tracking in:"
echo "  1. In Steam, open the game's ${BOLD}Properties${RESET} -> ${BOLD}General${RESET}"
echo "  2. Paste this into ${BOLD}LAUNCH OPTIONS${RESET} (replace anything opentrack-related that was there):"
echo
echo "       ${BOLD}$LAUNCHER_BIN %command%${RESET}"
echo
echo "  3. The game has to run with Proton (Properties -> Compatibility)."
echo
echo "Then set opentrack up ONCE per game, in Desktop Mode, with the game closed:"
echo "  double-click ${BOLD}opentrack Setup${RESET} on the desktop (or find it in the app menu)."
echo "While a game runs you can't click in opentrack, the game takes all clicks."
echo
echo "opentrack updates itself automatically, and the icuuc.dll fix is re-applied after every update."
echo "If anything breaks, just run this script again."
