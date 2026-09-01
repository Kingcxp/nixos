{
  config,
  lib,
  pkgs,
  ...
}:

{
  # bluetooth
  hardware.bluetooth.enable = lib.mkDefault true;
  hardware.bluetooth.powerOnBoot = lib.mkDefault true;

  services.blueman.enable = lib.mkDefault true;
  hardware.bluetooth.settings = lib.mkDefault {
    General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
    };
  };
}
