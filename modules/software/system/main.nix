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

  # git（对齐本机 ~/.gitconfig，并按要求开启提交签名）
  programs.git = {
    enable = true;
    lfs.enable = true;
    config = {
      user.name = "Kingcq";
      user.email = "404291187@qq.com";
      init.defaultBranch = "main";
      # 保留登录凭据（~/.git-credentials），无需重复输入
      credential.helper = "store";
      # SSH 方式签名提交（密钥：~/.ssh/id_ed25519）
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";
      # 合并策略：merge（不 rebase）
      pull.rebase = false;
      merge.ff = true;
      push.autoSetupRemote = true;
    };
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
