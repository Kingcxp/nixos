{
  pkgs,
  lib,
  config,
  ...
}:
# 迁移审计补充：Arch 显式安装包中剩余的应用与库
# （前批已迁：firefox/dolphin/kitty/btop/micro/tmux/yazi/dunst/wofi/wlogout、
#   开发工具链、字体、fcitx5、输入法、VirtualBox guest 等）
{
  environment.systemPackages = with pkgs; [
    # ---------- 图形 / 创作 ----------
    aseprite # 像素画
    blockbench
    krita
    libreoffice-fresh # 办公套件（中文界面由系统 locale 提供）
    neovide # neovim GUI
    obs-studio # 录屏/直播
    imagemagick
    jpegoptim
    optipng
    ghostscript
    djvulibre

    # ---------- 网络工具 / 远程 ----------
    sqlitebrowser
    pavucontrol # 音量控制
    rustdesk # 远程桌面
    wemeet # 腾讯会议
    clash-verge-rev # 代理客户端（unfree）
    netease-cloud-music-gtk # 网易云音乐（AUR 原版的 GTK 复刻）
    virt-manager # 虚拟机管理（替代 VirtualBox GUI 用途）
    mesa-demos # glxinfo（mesa-utils 已并入 mesa-demos）
    vulkan-tools # vkcube/vulkaninfo
    libva-utils # vainfo（Intel 视频加速验证）

    # ---------- 命令行 ----------
    unrar
    vim
    man-db
    bc
    bash-completion
    fastfetch
    tree
    wget

    # ---------- 开发补充 ----------
    deno
    dotnet-sdk # C#（godot-mono 使用）
    sqlite

    # ---------- Minecraft 启动器 ----------
    hmcl
  ];

  # Godot + .NET
  environment.variables.DOTNET_ROOT = "${pkgs.dotnet-sdk}";

  # Steam（unfree，wlroots/niri 下经 gamescope 或直接跑）
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # OBS 的虚拟摄像头（v4l2loopback）
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "clash-verge-rev"
      "steam"
      "steam-unwrapped"
      "wemeet"
      "hmcl"
    ];
}
