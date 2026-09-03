{
  config,
  lib,
  pkgs,
  ...
}:

{
  # VirtualBox Guest Additions 支持（仅在 VM 中启用时生效）。
  #
  # nixpkgs bug 回避：`virtualisation.virtualbox.guest.enable = true` 默认
  # 同时设置 `boot.supportedFilesystems = [ "vboxsf" ]`，而
  # `modules/tasks/filesystems/vboxsf.nix` 把 `mount.vboxsf` 硬编码为
  # `pkgs.linuxPackages.virtualboxGuestAdditions`（nixpkgs 默认内核）——
  # 与本仓库的 `boot.kernelPackages = linuxPackages_latest` 不一致时，
  # 6.18 内核上的 vboxvideo 编译失败（vbox_fb.c 调用已被移除的
  # drm_fb_helper_alloc_info），整个系统闭包构建失败。
  #
  # 修复：关闭内置 vboxsf 挂接（避免拉入默认内核的 GA），改用与本仓库
  # 内核一致的 Guest Additions 提供 mount.vboxsf。
  config = lib.mkIf config.virtualisation.virtualbox.guest.enable {
    # 阻断 nixpkgs vboxsf.nix 的默认内核路径
    virtualisation.virtualbox.guest.vboxsf = lib.mkForce false;

    # 用当前内核的 GA 补回 mount.vboxsf（共享文件夹仍可用）
    system.fsPackages = lib.mkAfter [
      (pkgs.runCommand "mount.vboxsf-latest" { } ''
        mkdir -p $out/bin
        cp ${config.boot.kernelPackages.virtualboxGuestAdditions}/bin/mount.vboxsf $out/bin
      '')
    ];

    # 注意：这里故意不再设置 boot.supportedFilesystems = [ "vboxsf" ]——
    # 它会触发 nixpkgs filesystems/vboxsf.nix 的坏路径（硬编码默认内核 GA）。
    # vboxsf.ko 模块已经随 guest 的 boot.extraModulePackages（7.1.8 GA）加载。
  };
}
