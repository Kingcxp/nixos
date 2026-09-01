#!/bin/bash
# Battery control for the waybar battery module.
#
#   strategy   (left click)  wofi menu of power strategy tiers, switchable
#   charge     (right click) battery protection control:
#                              - if the kernel exposes charge_control_end_threshold,
#                                show a 5%-snap slider (real percentage limit)
#                              - otherwise (this ThinkBook: only conservation_mode
#                                0/1, ~80% cap) offer the conservation toggle
#   optimize   (middle click) run powertop --auto-tune once
#
# Requires NOPASSWD sudo for:
#   powertop
#   tee  /sys/firmware/acpi/platform_profile
#   tee  .../conservation_mode
# On NixOS these rules are declared in hosts/thinkbook/default.nix;
# on Arch they belong in /etc/sudoers.d/.

PROFILE_SYS=/sys/firmware/acpi/platform_profile
CM_SYS=/sys/devices/pci0000:00/0000:00:1f.0/PNP0C09:00/VPC2004:00/conservation_mode
THRESH_SYS=/sys/class/power_supply/BAT0/charge_control_end_threshold
BAT=/sys/class/power_supply/BAT0

notify() { notify-send -u normal -i battery-good "电池" "$1"; }

apply_profile() {
    # $1 = platform profile name (low-power | balanced | performance)
    if [ -w "$PROFILE_SYS" ]; then
        echo "$1" > "$PROFILE_SYS"
    else
        echo "$1" | sudo tee "$PROFILE_SYS" >/dev/null
    fi
    notify "电源策略 → $1"
}

optimize_now() {
    sudo powertop --auto-tune && notify "powertop 一键优化完成"
}

strategy_menu() {
    local cur
    cur=$(cat "$PROFILE_SYS" 2>/dev/null)
    local choice
    choice=$(printf '省电 (low-power)\n平衡 (balanced)\n性能 (performance)\n一键 powertop 优化' |
        wofi --dmenu --prompt "电源策略 (当前: $cur)" -p "电源策略")
    case "$choice" in
        省电*) apply_profile low-power ;;
        平衡*) apply_profile balanced ;;
        性能*) apply_profile performance ;;
        *powertop*) optimize_now ;;
    esac
}

battery_status_text() {
    local cap status
    cap=$(cat "$BAT/capacity" 2>/dev/null)
    status=$(cat "$BAT/status" 2>/dev/null)
    local cm="关闭"; [ "$(cat "$CM_SYS" 2>/dev/null)" = "1" ] && cm="开启"
    printf '当前电量 %s%% (%s) | 养护模式: %s' "$cap" "$status" "$cm"
}

# --- right-click: battery protection ---
charge_control() {
    # Prefer a real percentage threshold if the kernel exposes it.
    if [ -w "$THRESH_SYS" ]; then
        local cur max=100 min=50
        cur=$(cat "$THRESH_SYS" 2>/dev/null)
        local val
        val=$(zenity --scale --text "最大充电量 (%)" \
            --min-value "$min" --max-value "$max" --step 5 --value "$cur" 2>/dev/null)
        [ -z "$val" ] && return 0
        echo "$val" | sudo tee "$THRESH_SYS" >/dev/null
        notify "最大充电量已设为 $val%"
        return 0
    fi

    # This ThinkBook exposes only conservation_mode (0/1, ~80% cap).
    local cur=0; [ -f "$CM_SYS" ] && cur=$(cat "$CM_SYS")
    local curlabel="关闭"
    [ "$cur" = "1" ] && curlabel="开启（限制充电 ~80%）"
    local choice
    choice=$(printf '开启电池养护（限制充电 ~80%%）\n关闭电池养护（可充至 100%%）' |
        wofi --dmenu --prompt "电池保护 (当前: $curlabel)" -p "电池保护")
    case "$choice" in
        开启*)
            if [ -w "$CM_SYS" ]; then echo 1 > "$CM_SYS"; else echo 1 | sudo tee "$CM_SYS" >/dev/null; fi
            notify "电池养护已开启（最大充电 ~80%）" ;;
        关闭*)
            if [ -w "$CM_SYS" ]; then echo 0 > "$CM_SYS"; else echo 0 | sudo tee "$CM_SYS" >/dev/null; fi
            notify "电池养护已关闭（可充至 100%）" ;;
    esac
}

case "${1:-strategy}" in
    strategy) strategy_menu ;;
    charge)   charge_control ;;
    optimize) optimize_now ;;
    status)   battery_status_text ;;
    *)        echo "Usage: $0 [strategy|charge|optimize|status]" ;;
esac
