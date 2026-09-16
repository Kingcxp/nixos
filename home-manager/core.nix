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
  home.packages = [ pkgs.gcr ];

  # Theme — Catppuccin Macchiato is the user's global color scheme
  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Papirus-Dark";
    };
  };
}
