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

  # 二进制缓存（系统级，避免每次 rebuild 弹信任确认）
  # 顺序即优先级；某一源不可达时 Nix 自动回退到下一个。
  # cernet 为大陆主力源，官方 cache.nixos.org 兜底。
  nix.settings.substituters = [
    "https://mirrors.cernet.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
