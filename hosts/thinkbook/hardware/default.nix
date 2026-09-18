{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Intel CPU — microcode, temperature control, iGPU tuning
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.intel-gpu-tools.enable = lib.mkDefault true;
  services.thermald.enable = lib.mkDefault true;

  # 固件：Intel Tiger Lake 音频 DSP（sof-firmware，扬声器/麦克风必需）
  hardware.firmware = with pkgs; [ sof-firmware ];

  # Intel Tiger Lake iGPU：硬件视频解码/编码（VA-API，英伟达无独显）
  environment.systemPackages = with pkgs; [
    intel-media-driver # Broadwell+ 的 VA-API 驱动（浏览器/播放器硬解）
    libva-utils        # vainfo 验证
    vulkan-tools       # vkcube/vulkaninfo
    mesa-demos         # glxinfo
    fwupd              # 固件更新（BIOS/SSD/Thunderbolt）
  ];
  # VA-API 环境变量（iHD 驱动）
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32 位应用（Steam/部分游戏）的硬解
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt # QuickSync（Tiger Lake 用 intel-media-driver 即可，此包备用）
    ];
  };

  # 固件更新（BIOS/SSD/Thunderbolt/外设）
  # - fwupd 自带的 fwupd-refresh.timer 每小时刷新 LVFS 元数据（NixOS 模块已启用）
  # - 下面再加一个每周"自动安装"定时器：装完的 UEFI/BIOS 胶囊更新在下次重启时生效
  services.fwupd.enable = lib.mkDefault true;

  systemd.services.fwupd-auto-update = {
    description = "自动安装可用的固件更新（fwupd）";
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "fwupd.service"
    ];
    requires = [ "fwupd.service" ];
    path = [ pkgs.fwupd ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "fwupd-auto-update" ''
        set -u
        echo "=== $(date -Is) 检查固件更新 ==="
        fwupdmgr refresh --force || true
        fwupdmgr get-updates || true
        # -y 自动确认；--no-reboot-check 不阻塞等待重启确认，
        # 需要重启生效的胶囊更新会在下次开机自动应用
        fwupdmgr update -y --no-reboot-check || true
        echo "=== 完成（journalctl -u fwupd-auto-update 可回看） ==="
      '';
    };
  };

  systemd.timers.fwupd-auto-update = {
    description = "每周自动安装固件更新";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true; # 关机错过也补跑
      RandomizedDelaySec = "1h";
    };
  };

  # Power management + battery conservation (ThinkBook)
  powerManagement.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";

      PLATFORM_PROFILE_ON_AC = "balanced";
      PLATFORM_PROFILE_ON_BAT = "quiet";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 80;

      PCIE_ASPM_ON_AC = "powersave";
      PCIE_ASPM_ON_BAT = "powersupersave";

      SATA_LINKPWR_ON_BAT = "min_power";
      SOUND_POWER_SAVE_ON_BAT = 1;
      WIFI_PWR_ON_BAT = 1;
    };
  };

  # SSD
  services.fstrim.enable = lib.mkDefault true;

  boot.kernelParams = [
    "i915.enable_rc6=1" # Iris Xe render power management
    "i915.enable_fbc=1" # framebuffer compression
    "quiet"
  ];
}
