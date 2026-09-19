{ username, pkgs, ... }: {
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.11";
  };
  programs.home-manager.enable = true;

  # catppuccin/nix 用户侧端口：本仓库的 kitty/btop/waybar 等主题均为手工
  # 对齐本机配置（文件原样部署），故显式关闭用户侧自动套用，避免被覆盖。
  # （NixOS 侧仍启用以提供 GRUB 主题与鼠标指针）
  catppuccin = {
    enable = false;
    autoEnable = false;
  };

  # USB devices — user prefers Dolphin file manager
  services.udiskie = {
    enable = true;
    settings = {
      program_options = {
        file_manager = "${pkgs.kdePackages.dolphin}/bin/dolphin";
      };
    };
  };

  # Secure
  services.gnome-keyring.enable = true;
  home.packages = [
    pkgs.gcr
    # 下面 dconf 的 icon-theme 引用了 Papirus-Dark，必须装上才有图标
    pkgs.papirus-icon-theme
  ];

  # 生成 ~/Documents、~/Downloads 等用户目录（Arch 上由 xdg-user-dirs 提供）
  xdg.userDirs.enable = true;
  # home.stateVersion 是 25.11，默认沿用旧行为（在会话里导出 XDG_*_DIR 变量，
  # 与 Arch 上的 xdg-user-dirs 一致）；显式写出来避免每次求值都出提示
  xdg.userDirs.setSessionVariables = true;

  # Theme — Catppuccin Macchiato is the user's global color scheme
  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Papirus-Dark";
    };
  };

  # GTK 应用（含 XWayland 里的）不读 niri 的 cursor 配置，而是读 dconf /
  # gtk-3.0/settings.ini —— 这里显式声明，对齐 Arch 的 dconf 值。
  # 注意：环境变量 GTK_FONT_NAME 并不被 GTK 读取，只有这个模块是有效的。
  gtk = {
    enable = true;
    cursorTheme = {
      name = "catppuccin-macchiato-lavender-cursors";
      size = 32;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
  };
}
