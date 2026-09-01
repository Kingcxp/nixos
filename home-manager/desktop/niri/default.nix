{ pkgs, config, ... }:
{
  # programs.niri.enable is set at the SYSTEM level (modules/software/desktop/niri.nix),
  # not here. This module only configures the user session + ships the kdl files.
  programs.fuzzel.enable = true; # fallback launcher
  programs.waybar.enable = true;
  services.polkit-gnome.enable = true; # polkit

  home.packages = with pkgs; [
    swaybg # wallpaper
    xwayland-satellite # xwayland support
    wl-clipboard
    bibata-cursors
    catppuccin-cursors.macchiatoLavender # user's cursor theme

    networkmanagerapplet
    brightnessctl
  ];

  xdg.configFile."niri/config.kdl".source = ./config/niri.kdl;
  xdg.configFile."niri/input.kdl".source = ./config/input.kdl;
  xdg.configFile."niri/output.kdl".source = ./config/output.kdl;
  xdg.configFile."niri/bind.kdl".source = ./config/bind.kdl;
  xdg.configFile."niri/layout.kdl".source = ./config/layout.kdl;
  xdg.configFile."niri/startup.kdl".source = ./config/startup.kdl;
  xdg.configFile."niri/wallpaper.kdl".source = ./config/wallpaper.kdl;
  xdg.configFile."niri/windowrule.kdl".source = ./config/windowrule.kdl;
  xdg.configFile."niri/misc.kdl".source = ./config/misc.kdl;
  xdg.configFile."niri/workspace.kdl".source = ./config/workspace.kdl;
}
