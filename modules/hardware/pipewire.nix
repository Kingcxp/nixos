{
  config,
  lib,
  pkgs,
  ...
}:

{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  environment.systemPackages = with pkgs; [
    alsa-ucm-conf
    alsa-utils
    pwvucontrol
  ];
}
