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
