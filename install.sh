#!/usr/bin/env bash
set -euo pipefail

restart=false

usage() {
    cat <<USAGE
Usage: ./install.sh [--restart]

Installs mic-indicator-daemon to ~/.local/bin and creates the KDE autostart entry.

Options:
  --restart, -r   Stop any running installed daemon and start the updated one
  --help, -h      Show this help
USAGE
}

for arg in "$@"; do
    case "$arg" in
        --restart|-r)
            restart=true
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown option: $arg" >&2
            usage >&2
            exit 1
            ;;
    esac
done

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_path="$script_dir/mic-indicator-daemon"
bin_dir="${XDG_BIN_HOME:-$HOME/.local/bin}"
autostart_dir="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
target_path="$bin_dir/mic-indicator-daemon"
desktop_path="$autostart_dir/mic-indicator-daemon.desktop"
log_path="${TMPDIR:-/tmp}/mic-indicator-daemon.log"

if [[ ! -f "$source_path" ]]; then
    echo "Error: mic-indicator-daemon not found next to install.sh" >&2
    exit 1
fi

mkdir -p "$bin_dir" "$autostart_dir"
install -m 755 "$source_path" "$target_path"

cat > "$desktop_path" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Mic Indicator
Comment=Microphone status tray indicator
Exec=$target_path
Icon=audio-input-microphone
Terminal=false
Categories=Utility;
X-KDE-autostart-after=panel
DESKTOP

chmod 644 "$desktop_path"

if [[ "$restart" == true ]]; then
    mapfile -t daemon_pids < <(pgrep -f -- "$target_path" || true)

    for pid in "${daemon_pids[@]}"; do
        if [[ "$pid" != "$$" ]]; then
            kill "$pid" 2>/dev/null || true
        fi
    done

    for _ in {1..20}; do
        still_running=false
        for pid in "${daemon_pids[@]}"; do
            if [[ "$pid" != "$$" ]] && kill -0 "$pid" 2>/dev/null; then
                still_running=true
                break
            fi
        done

        if [[ "$still_running" == false ]]; then
            break
        fi

        sleep 0.1
    done

    setsid -f "$target_path" >"$log_path" 2>&1
fi

cat <<SUMMARY
Installed mic-indicator-daemon to:
  $target_path

Created autostart entry:
  $desktop_path
SUMMARY

if [[ "$restart" == true ]]; then
    cat <<SUMMARY

Restarted mic-indicator-daemon.
Log file:
  $log_path
SUMMARY
else
    cat <<SUMMARY

Start it now with:
  ./install.sh --restart
SUMMARY
fi
