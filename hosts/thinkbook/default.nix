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

  # NOPASSWD sudo for powertop so the waybar battery menu works without a prompt
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "${pkgs.powertop}/bin/powertop";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
