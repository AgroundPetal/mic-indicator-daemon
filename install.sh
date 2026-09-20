#!/usr/bin/env bash
set -euo pipefail

restart=false
action=""

usage() {
    cat <<USAGE
Usage: ./install.sh [--restart | --start | --stop | --status | --enable | --disable | --uninstall]

Installs mic-indicator-daemon to ~/.local/bin and creates the KDE autostart entry.

Options:
  --restart, -r   Stop any running installed daemon and start the updated one
  --start         Start the installed daemon if it is not already running
  --stop          Stop the running daemon
  --status        Show whether the daemon is running and if autostart is set
  --enable        Recreate the autostart entry and start the daemon
  --disable       Stop the daemon and remove the autostart entry (keeps binary)
  --uninstall     Stop the daemon and remove the binary and autostart entry
  --help, -h      Show this help
USAGE
}

for arg in "$@"; do
    case "$arg" in
        --restart|-r)
            restart=true
            ;;
        --start|--stop|--status|--enable|--disable|--uninstall)
            if [[ -n "$action" ]]; then
                echo "Error: only one command at a time" >&2
                exit 1
            fi
            action="${arg#--}"
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

if [[ "$restart" == true && -n "$action" ]]; then
    echo "Error: --restart cannot be combined with other commands" >&2
    exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_path="$script_dir/mic-indicator-daemon"
bin_dir="${XDG_BIN_HOME:-$HOME/.local/bin}"
autostart_dir="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
target_path="$bin_dir/mic-indicator-daemon"
desktop_path="$autostart_dir/mic-indicator-daemon.desktop"
log_path="${TMPDIR:-/tmp}/mic-indicator-daemon.log"

# Stop any running installed daemon, skipping this script's own PID. Mirrors the
# inline restart logic below; used by the --stop/--disable/--uninstall commands.
stop_daemon() {
    mapfile -t daemon_pids < <(pgrep -f -- "$target_path" || true)

    for pid in "${daemon_pids[@]}"; do
        if [[ -n "$pid" && "$pid" != "$$" ]]; then
            kill "$pid" 2>/dev/null || true
        fi
    done

    for _ in {1..20}; do
        still_running=false
        for pid in "${daemon_pids[@]}"; do
            if [[ -n "$pid" && "$pid" != "$$" ]] && kill -0 "$pid" 2>/dev/null; then
                still_running=true
                break
            fi
        done

        if [[ "$still_running" == false ]]; then
            break
        fi

        sleep 0.1
    done
}

daemon_pid_list() {
    pgrep -f -- "$target_path" | grep -v "^$$\$" | paste -sd' ' - || true
}

write_autostart() {
    mkdir -p "$autostart_dir"

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
}

start_daemon() {
    local pids
    pids="$(daemon_pid_list)"
    if [[ -n "$pids" ]]; then
        echo "Already running (pid $pids)."
        return 0
    fi

    if [[ ! -x "$target_path" ]]; then
        echo "Error: not installed. Run ./install.sh first." >&2
        exit 1
    fi

    setsid -f "$target_path" >"$log_path" 2>&1
    echo "Started mic-indicator-daemon."
}

case "$action" in
    start)
        start_daemon
        exit 0
        ;;
    stop)
        if [[ -n "$(daemon_pid_list)" ]]; then
            stop_daemon
            echo "Stopped mic-indicator-daemon."
        else
            echo "mic-indicator-daemon is not running."
        fi
        exit 0
        ;;
    status)
        pids="$(daemon_pid_list)"
        if [[ -n "$pids" ]]; then
            echo "Running (pid $pids)."
        else
            echo "Not running."
        fi

        if [[ -f "$desktop_path" ]]; then
            echo "Autostart: enabled ($desktop_path)"
        else
            echo "Autostart: disabled"
        fi
        exit 0
        ;;
    enable)
        write_autostart
        echo "Autostart enabled."
        start_daemon
        exit 0
        ;;
    disable)
        stop_daemon
        rm -f "$desktop_path"
        echo "Stopped daemon and disabled autostart (binary kept at $target_path)."
        exit 0
        ;;
    uninstall)
        stop_daemon
        rm -f "$target_path" "$desktop_path"
        cat <<SUMMARY
Uninstalled mic-indicator-daemon.
Removed:
  $target_path
  $desktop_path
SUMMARY
        exit 0
        ;;
esac

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
