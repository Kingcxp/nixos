#!/bin/bash
# PowerTOP control for waybar battery module
#   toggle   - enable/disable auto-tune (state tracked in /tmp)
#   optimize - run powertop --auto-tune right away (one-shot)
#   menu     - wofi picker with the above options
#
# Notes:
#   - powertop has NO official CLI to *undo* auto-tune; settings persist
#     until reboot. "Disable" therefore records the state and explains this.
#   - NOPASSWD sudo for /usr/bin/powertop is required (already configured).

STATE_FILE="/tmp/powertop-autotune-active"

is_on() {
    [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "1" ]
}

auto_tune() {
    sudo /usr/bin/powertop --auto-tune
    echo "1" > "$STATE_FILE"
    notify-send -u normal -i battery-full-charging "PowerTOP" "Auto-tune 已开启（省电优化已应用）"
}

disable() {
    echo "0" > "$STATE_FILE"
    notify-send -u normal -i battery-good "PowerTOP" "省电优化已关闭（现有内核参数在重启后恢复系统默认）"
}

toggle_autotune() {
    if is_on; then
        disable
    else
        auto_tune
    fi
}

optimize_now() {
    if auto_tune; then
        notify-send -u normal -i battery-full-charging "PowerTOP" "一键省电优化完成"
    fi
}

menu() {
    local choice
    choice=$(printf '一键省电优化 (auto-tune)\n开启省电优化\n关闭省电优化' | wofi --dmenu --prompt "PowerTOP" -p "PowerTOP")
    case "$choice" in
        *auto-tune*) optimize_now ;;
        开启省电优化) auto_tune ;;
        关闭省电优化) disable ;;
    esac
}

case "${1:-menu}" in
    toggle)   toggle_autotune ;;
    optimize) optimize_now ;;
    menu)     menu ;;
    *)        echo "Usage: $0 [toggle|optimize|menu]" ;;
esac