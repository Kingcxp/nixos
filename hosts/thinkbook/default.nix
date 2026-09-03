{
  config,
  lib,
  pkgs,
  username,
  alien-pkgs,
  omp-pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./hardware

    ../../modules/hardware

    ../../modules/software/system/main.nix

    ../../modules/software/desktop/greetd.nix
    ../../modules/software/desktop/niri.nix
  ];

  networking.hostName = "thinkbook";

  # nix-ld
  programs.nix-ld.enable = true;

  environment.systemPackages = [
    # special environments
    alien-pkgs.nix-alien
    omp-pkgs.default
    pkgs.gh
  ];

  # NOPASSWD sudo for powertop + battery control (platform_profile / conservation_mode)
  # 注意：sudoers 中冒号是特殊字符，路径里的冒号必须用 \: 转义，
  # 否则 visudo 在构建时报 syntax error（build 阶段才触发）。
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "${pkgs.powertop}/bin/powertop";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/tee /sys/firmware/acpi/platform_profile";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/tee /sys/devices/pci0000\\:00/0000\\:00\\:1f.0/PNP0C09\\:00/VPC2004\\:00/conservation_mode";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
