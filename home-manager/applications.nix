{
  pkgs,
  lib,
  username,
  ...
}:
{
  # User's application set (overlaps resolved in favor of user's choices)
  home.packages = with pkgs; [
    # Browser / file manager / terminal from user's hyprland config
    firefox
    kdePackages.dolphin

    # From user's myconfig
    btop
    yazi
    kitty
    micro
    tmux
    dunst

    # System helpers referenced by waybar & scripts
    brightnessctl
    playerctl
    powertop
    wl-clipboard
    wlogout
    wofi
    networkmanagerapplet
    blueman
    fcitx5

    # QQ：下面的 xdg.desktopEntries.qq 引用了它，这里装进 PATH 才一致
    qq
    # 压缩包默认用 ark 打开（见下方 xdg.mimeApps）
    kdePackages.ark
  ];

  # QQ under Wayland (fix from friend's config, kept)
  xdg.desktopEntries.qq = {
    name = "QQ";
    genericName = "Instant Messaging";
    exec = "${pkgs.qq}/bin/qq --ozone-platform=wayland --enable-features=UseOzonePlatform --enable-features=WaylandWindowDecorations --enable-wayland-ime=true --wayland-text-input-version=3 %U";
    terminal = false;
    categories = [ "Network" "InstantMessaging" ];
    icon = "qq";
    comment = "QQ for Linux";
  };

  # Clash Verge Rev（代理客户端）：不随会话自动启动。
  # 用 XDG autostart 的 Hidden=true 显式屏蔽（即使应用内开启"开机自启"也无效），
  # 需要时手动 `clash-verge` 启动。
  xdg.configFile."autostart/clash-verge.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Clash Verge
    Exec=clash-verge
    Hidden=true
  '';

  # Default applications — user prefers Dolphin + Firefox
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "org.kde.dolphin.desktop";
      "x-scheme-handler/file" = "org.kde.dolphin.desktop";
      "application/zip" = "org.kde.ark.desktop";

      "text/plain" = [ "code.desktop" ];
      "application/pdf" = "firefox.desktop";

      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };
}
