#!/usr/bin/env bash
# Build a runnable .AppImage from a Flutter Linux release bundle.
#
# The bundle is copied verbatim into the AppDir's usr/bin so its $ORIGIN/lib
# rpath keeps working. appimagetool is downloaded in CI (never vendored) and
# extracted before use, so neither this script nor the runner needs FUSE.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: tool/build_linux_appimage.sh --bundle DIR --version VERSION --output FILE
                                    [--appimagetool PATH]

  --bundle        Flutter Linux release bundle (contains `keyel`, `data`, `lib`).
  --version       Version name used in the AppImage metadata.
  --output        Destination .AppImage file.
  --appimagetool  Optional local appimagetool binary/AppImage. When omitted the
                  continuous x86_64 build is downloaded and extracted.
EOF
}

bundle=''
version=''
output=''
appimagetool=''

while (( $# > 0 )); do
  case "$1" in
    --bundle) bundle="${2:?--bundle needs a value}"; shift 2 ;;
    --version) version="${2:?--version needs a value}"; shift 2 ;;
    --output) output="${2:?--output needs a value}"; shift 2 ;;
    --appimagetool) appimagetool="${2:?--appimagetool needs a value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$bundle" || -z "$version" || -z "$output" ]]; then
  echo "--bundle, --version and --output are required" >&2
  usage >&2
  exit 2
fi
if [[ ! -x "$bundle/keyel" || ! -d "$bundle/lib" ]]; then
  echo "Not a Flutter Linux bundle: $bundle" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Never wrap a bundle that glibc will refuse to start on an older CPU. A runner
# can contribute a stale ISA note even when our own code was compiled baseline,
# so normalize first and let the guard verify the result. Both steps are cheap
# and protect local builds as well as CI.
bash "$repo_root/tool/normalize_cpu_baseline.sh" --bundle "$bundle" --platform linux
bash "$repo_root/tool/check_cpu_baseline.sh" --bundle "$bundle" --platform linux

icon_source="$repo_root/design/icon/play_store_512.png"
if [[ ! -f "$icon_source" ]]; then
  echo "Missing app icon: $icon_source" >&2
  exit 2
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
appdir="$work/keyel.AppDir"
mkdir -p "$appdir/usr/bin" "$appdir/usr/share/icons/hicolor/512x512/apps"

cp -a "$bundle/." "$appdir/usr/bin/"
cp "$icon_source" "$appdir/keyel.png"
cp "$icon_source" "$appdir/usr/share/icons/hicolor/512x512/apps/keyel.png"
ln -s keyel.png "$appdir/.DirIcon"

cat > "$appdir/keyel.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Keyel
GenericName=Password Manager
Comment=Offline-first, privacy-first password manager
Exec=keyel
Icon=keyel
Terminal=false
Categories=Utility;
StartupWMClass=com.freesoftware.keyel
EOF

cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
export PATH="$HERE/usr/bin:$PATH"
exec "$HERE/usr/bin/keyel" "$@"
EOF
chmod 755 "$appdir/AppRun"
chmod 644 "$appdir/keyel.desktop" "$appdir/keyel.png"
chmod -R a+rX "$appdir"

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$appdir/keyel.desktop"
fi

if [[ -z "$appimagetool" ]]; then
  url='https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage'
  echo "Downloading appimagetool from $url"
  curl -fsSL -o "$work/appimagetool" "$url"
  chmod +x "$work/appimagetool"
  (cd "$work" && ./appimagetool --appimage-extract >/dev/null)
  appimagetool="$work/squashfs-root/AppRun"
fi

mkdir -p "$(dirname "$output")"
echo "Building $(basename "$output") from ${bundle}"
ARCH=x86_64 VERSION="$version" "$appimagetool" --no-appstream "$appdir" "$output"
echo "Wrote $output"
