{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # NTFS
  boot.supportedFilesystems.ntfs = lib.mkDefault true;

  # Firmware
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
