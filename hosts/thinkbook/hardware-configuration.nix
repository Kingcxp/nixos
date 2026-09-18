# ThinkBook 14s — Intel i7-1160G7 / Iris Xe / NVMe / BIOS+GRUB
# This hardware-configuration.nix was hand-written based on the
# previous Arch install's layout. Verify UUIDs against `lsblk -f`
# during installation; a fresh `nixos-generate-config` may be safer.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "uas"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/13cf9a6e-a715-4459-8fb8-9624506e5687";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/13cf9a6e-a715-4459-8fb8-9624506e5687";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/13cf9a6e-a715-4459-8fb8-9624506e5687";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
      "noatime"
    ];
  };

  # 注意：本配置用 BIOS + GRUB，不需要单独的 /boot 分区
  # （GRUB 直接读根文件系统上的 /boot 目录）。

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
