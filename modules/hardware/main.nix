{
  config,
  lib,
  pkgs,
  ...
}:
{
  # BIOS GRUB（MBR 安装到 /dev/nvme0n1）
  # GRUB 主题由 catppuccin/nix 模块自动配置（catppuccin.grub.enable，见 default.nix）
  boot.loader.grub = {
    enable = lib.mkDefault true;
    device = lib.mkDefault "/dev/nvme0n1";
  };

  # catppuccin/nix 全局：macchiato + lavender
  # autoEnable 会自动接入支持的端口（GRUB 主题、指针、dunst、waybar、
  # wlogout、yazi、fish、fcitx5、tty 等 NixOS/home-manager 层）
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = lib.mkDefault "macchiato";
    accent = lib.mkDefault "lavender";
  };

  # Kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # 文件系统工具：btrfs（真机根分区用 btrfs 子卷，需 btrfs-progs）
  boot.supportedFilesystems.btrfs = lib.mkDefault true;
  # NTFS（Windows 移动硬盘读挂载）
  boot.supportedFilesystems.ntfs = lib.mkDefault true;

  # Firmware
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
