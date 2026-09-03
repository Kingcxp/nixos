{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  # Unfree software
  nixpkgs.config.allowUnfree = true;

  # User
  users.users.${username} = {
    isNormalUser = true;
    # 初始密码，安装后请立即用 `passwd` 修改
    initialPassword = "123456";
    extraGroups = [
      "wheel" # sudo 权限（NixOS 默认 wheel 组可 sudo）
      "networkmanager"
    ];
  };

  # sudo
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = true;

  # git
  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  # Shell
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  environment.pathsToLink = [ "/share/fish" ];
  environment.shells = with pkgs; [ fish ];

  # Nix
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  system.stateVersion = "25.05";

  # Utils
  environment.systemPackages = with pkgs; [
    nano
    vim
    htop
    btop
    tree
    curl
    wget
    fastfetch
    s-tui
    unzip
    zip
    unar
    ntfs3g
    # toybox # Linux Utils
    pciutils
    usbutils
    nvtopPackages.full
    powertop

    nixd
  ];

  # USB devices
  services.udisks2.enable = true;

  # polkit
  security.polkit.enable = lib.mkDefault true;
  # Secure
  security.pam.services.login.enableGnomeKeyring = lib.mkDefault true;
}
