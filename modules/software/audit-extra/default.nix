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
    todesk # 远程桌面（nixpkgs 有官方包）
    wemeet # 腾讯会议
    microsoft-edge # 备用浏览器（unfree）
    clash-verge-rev # 代理客户端（unfree）
    netease-cloud-music-gtk # 网易云音乐（AUR 原版的 GTK 复刻）
    virt-manager # 虚拟机管理（替代 VirtualBox GUI 用途）
    mesa-demos # glxinfo（mesa-utils 已并入 mesa-demos）
    vulkan-tools # vkcube/vulkaninfo
    libva-utils # vainfo（Intel 视频加速验证）

    # ---------- 系统维护 / 关键时刻工具 ----------
    gparted # 图形分区编辑
    gnome-disk-utility # GNOME 磁盘（分区/格式化/镜像写入/SMART）
    woeusb # Windows ISO → U 盘（rufus 的 Linux 等价物；ventoy 被 nixpkgs 标记
    #   insecure（二进制 blob），未纳入，如需：nixpkgs.config.permittedInsecurePackages）
    usbimager # 简洁的镜像写入工具
    unetbootin # 多发行版 U 盘制作
    testdisk # 分区表/数据恢复
    ddrescue # 磁盘镜像救援
    smartmontools # smartctl 磁盘健康
    nvme-cli # NVMe 管理
    hdparm # 磁盘参数
    cryptsetup # LUKS 加密卷
    timeshift # 系统快照/还原
    parted # 命令行分区

    # ---------- TUI SQL 客户端（SQLite，可编辑行） ----------
    lazysql # TUI 数据库管理（SQLite/PG/MySQL，支持行编辑）
    visidata # TUI 表格多面手（可直接编辑 SQLite 单元格并写回）
    harlequin # 终端 SQL IDE（SQLite/DuckDB 等）

    # ---------- 磁盘空间分析（SpaceSniffer 类） ----------
    qdirstat # SpaceSniffer 的 Qt 复刻（树状图）
    baobab # GNOME 磁盘用量分析
    ncdu # 终端磁盘用量（TUI）
    dust # 终端磁盘用量（rust，快速）
    duf # df 的现代替代

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

    # ---------- oh-my-pi（omp.sh 编码 agent，can1357/oh-my-pi 官方二进制） ----------
    (pkgs.stdenv.mkDerivation {
      pname = "oh-my-pi";
      version = "18.1.10";
      src = pkgs.fetchurl {
        url = "https://github.com/can1357/oh-my-pi/releases/download/v18.1.10/omp-linux-x64";
        sha256 = "sha256-6R1VmO5H4dQJn9hobcn2HJt1Xy6gd9Xxd0q6EHIyH54=";
      };
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/omp
        chmod +x $out/bin/omp
      '';
      meta.platforms = [ "x86_64-linux" ];
    })
  ];

  # Godot + .NET
  environment.variables.DOTNET_ROOT = "${pkgs.dotnet-sdk}";

  # Homebrew on Linux：官方支持 /home/linuxbrew（brew 自更新，不走 nix）
  # 首次 rebuild 时自动执行官方 installer（幂等：已装则跳过）
  system.activationScripts.homebrew = lib.stringAfter [ "etc" ] ''
    if [ ! -d /home/linuxbrew/.linuxbrew ] && [ ! -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
      mkdir -p /home/linuxbrew
      ${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | ${pkgs.bash}/bin/bash -s -- --non-interactive || true
    fi
  '';

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
      "zoom"
      "hmcl"
      "microsoft-edge"
    ];
}
