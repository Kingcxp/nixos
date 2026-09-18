{
  pkgs,
  ...
}:
let
  # 插件路径：需在 extraConfig 中按正确顺序手动加载（原因见下）
  catppuccinPlugin = "${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux";
  cpuPlugin = "${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux";
  batteryPlugin = "${pkgs.tmuxPlugins.battery}/share/tmux-plugins/battery/battery.tmux";
in
{
  # 注意：这里**不使用** programs.tmux.plugins。
  # home-manager 会把插件的 run 行写在 extraConfig 之前，导致两个问题：
  #   1) @catppuccin_flavor 在 catppuccin 插件加载之后才设置 → 主题停在默认 mocha
  #   2) status-right 里的 #{cpu_percentage}/#{battery_percentage} 占位符
  #      在插件做插值替换时还未出现 → CPU/电池栏永远空白
  # 因此照本地 ~/.tmux.conf 的顺序在 extraConfig 里手动加载：
  # 先设参数 → 加载 catppuccin → 设 status-right → 最后加载 cpu/battery 插件。
  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g mouse on
      set -g default-terminal "tmux-256color"

      # ---- 1. 主题参数（必须在 catppuccin 加载前设置）----
      set -g @catppuccin_flavor "macchiato"
      set -g @catppuccin_window_status_style "rounded"

      # uptime 模块：上游 sed 只匹配英文 "N users"，在 zh_CN locale 下
      # `uptime` 输出 "0 用户, 平均负载" 会残留 → 强制 C locale。
      # 注意：不要用 \1 之类反斜杠+数字（tmux 会当成八进制转义报错），
      # 这里用 uptime -p + cut/sed 的等价压缩写法。
      set -g @catppuccin_uptime_text " #(LC_ALL=C uptime -p | cut -c4- | sed 's/ days/d/g; s/ hours/h/g; s/ minutes/m/g; s/,//g')"

      # ---- 2. 加载 catppuccin（flavor 与 uptime 文案已就位）----
      run-shell ${catppuccinPlugin}

      # ---- 3. 状态栏 ----
      set -g status-right-length 100
      set -g status-left-length 100
      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_application}"
      set -agF status-right "#{E:@catppuccin_status_cpu}"
      set -ag status-right "#{E:@catppuccin_status_session}"
      set -ag status-right "#{E:@catppuccin_status_uptime}"
      set -agF status-right "#{E:@catppuccin_status_battery}"

      # ---- 4. 最后加载 cpu/battery 插件：它们负责把 status-right 中的
      #      #{cpu_percentage}/#{battery_percentage} 等占位符替换为脚本调用 ----
      run-shell ${cpuPlugin}
      run-shell ${batteryPlugin}
    '';
  };
}
