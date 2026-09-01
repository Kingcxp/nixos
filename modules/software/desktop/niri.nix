{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Wayland Desktop Environment Configuations.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # services.greetd = {
  #   enable = true;
  #   settings = {
  #     default_session = {
  #       command = "${config.programs.niri.package}/bin/niri-session";
  #       user = "myuser";
  #     };
  #   };
  # };

  programs.niri.enable = true;

  # xdg.portal.config.niri = {
  #   "org.freedesktop.impl.portal.FileChooser" = [ "kde" ]; # or "kde"
  # };
  systemd.user.services.niri.enableDefaultPath = false;

  security.polkit.enable = true; # polkit
  services.gnome.gnome-keyring.enable = true; # secret service
  security.pam.services.swaylock = { };

  environment.systemPackages = [
    pkgs.kdePackages.dolphin
    pkgs.file-roller
  ];
  services.gvfs.enable = true;
}
