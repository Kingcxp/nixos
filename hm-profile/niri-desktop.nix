{ ... }:
{
  imports = [
    ../home-manager/core.nix
    ../home-manager/applications.nix
    ../home-manager/fish.nix

    ../home-manager/kitty
    ../home-manager/micro
    ../home-manager/btop
    ../home-manager/yazi
    ../home-manager/tmux
    ../home-manager/nvim
    ../home-manager/powertop
    ../home-manager/vscode
    ../home-manager/jetbrains
    ../home-manager/fcitx5

    ../home-manager/desktop/niri
    ../home-manager/desktop/waybar
    ../home-manager/desktop/wofi
    ../home-manager/desktop/wlogout
    ../home-manager/desktop/dunst
    ../home-manager/desktop/swayidle
    ../home-manager/desktop/swaylock
    ../home-manager/desktop/kanshi
    ../home-manager/desktop/wallpaper
  ];
}
