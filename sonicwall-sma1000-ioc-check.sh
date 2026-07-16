#!/usr/bin/env bash
#
# SonicWall SMA1000 Zero-Day IoC Check
#
# Unofficial community utility for defensive log review related to:
#   - CVE-2026-15409
#   - CVE-2026-15410
#   - SonicWall advisory SNWLID-2026-0008
#
# This project is not affiliated with or endorsed by SonicWall or the BSI.
# Review README.md and NOTICE.md before redistribution or production use.
#

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run with root privileges." >&2
    exit 2
fi

if ! command -v zgrep >/dev/null 2>&1; then
    echo "ERROR: zgrep is required but was not found." >&2
    exit 2
fi

readonly LOG_DIR="/var/log/aventail"

if [ ! -d "$LOG_DIR" ]; then
    echo "ERROR: Expected log directory not found: $LOG_DIR" >&2
    exit 2
fi

shopt -s nullglob
ACCESS_LOGS=("$LOG_DIR"/extraweb_access.log*)
CONTROL_LOGS=("$LOG_DIR"/ctrl-service.log*)
shopt -u nullglob

if [ "${#ACCESS_LOGS[@]}" -eq 0 ] && [ "${#CONTROL_LOGS[@]}" -eq 0 ]; then
    echo "ERROR: No supported SMA1000 log files were found in $LOG_DIR." >&2
    exit 2
fi

FOUND=0

matches_access_log() {
    local pattern="$1"
    [ "${#ACCESS_LOGS[@]}" -gt 0 ] && zgrep -qE -- "$pattern" "${ACCESS_LOGS[@]}" 2>/dev/null
}

matches_control_log() {
    local pattern="$1"
    [ "${#CONTROL_LOGS[@]}" -gt 0 ] && zgrep -qE -- "$pattern" "${CONTROL_LOGS[@]}" 2>/dev/null
}

matches_access_log 'POST /__api__/login HTTP.+" 200 ' && FOUND=1
matches_access_log 'POST /__api__/logout HTTP.+" 200 ' && FOUND=1
matches_access_log 'wsproxy.*host=0\.0\.0\.0.*" 101 ' && FOUND=1
matches_access_log 'wsproxy.*host=\[?::ffff:127.*" 101 ' && FOUND=1
matches_control_log 'hotfix removal for:.*\.\./' && FOUND=1

if [ "$FOUND" -eq 1 ]; then
    echo "WARNING: Potential SMA1000 indicators of compromise were detected."
    echo "Preserve evidence, isolate the appliance when appropriate, and follow current incident-response and vendor guidance."
    exit 1
fi

echo "No configured SMA1000 indicators of compromise were found."
echo "A clean result does not prove that the appliance is uncompromised."
exit 0
