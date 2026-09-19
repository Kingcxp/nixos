# ThinkBook 14s — Intel i7-1160G7 / Iris Xe / NVMe / UEFI+GRUB
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

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0A51-499C";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # UEFI 布局：/boot 是 EFI 系统分区（ESP）。
  # 若改用 BIOS(Legacy) + GRUB（thinkbook-legacy-bios），则不需要该分区，
  # /boot 会落在根文件系统上——安装时用 nixos-generate-config 重新生成即可。

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
