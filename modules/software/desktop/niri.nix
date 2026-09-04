{
  pkgs,
  ...
}:
{
  # Wayland Desktop Environment Configuations.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.niri.enable = true;

  # xdg-desktop-portal：屏幕共享/录屏（OBS、浏览器、腾讯会议/Zoom 的共享功能）
  # niri 实现了 ScreenCast/Screenshot 接口，由 gnome portal 提供对话框
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk # FileChooser 等通用接口
    ];
    configPackages = [ pkgs.niri ];
  };

  systemd.user.services.niri.enableDefaultPath = false;

  security.polkit.enable = true; # polkit
  services.gnome.gnome-keyring.enable = true; # secret service
  security.pam.services.swaylock = { };

  environment.systemPackages = [
    pkgs.kdePackages.dolphin
    pkgs.file-roller
    pkgs.zoom-us # Zoom 会议（XWayland 运行，共享经 portal）
  ];
  services.gvfs.enable = true;
}
