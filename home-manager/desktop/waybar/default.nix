{ pkgs, config, ... }:
{
  programs.waybar.enable = true;

  # Fcitx5 tray icon uses input-keyboard-symbolic from Adwaita.
  home.packages = [ pkgs.adwaita-icon-theme ];

  xdg.configFile."waybar/config.jsonc".source = ./config.jsonc;
  xdg.configFile."waybar/style.css".source = ./style.css;
}
