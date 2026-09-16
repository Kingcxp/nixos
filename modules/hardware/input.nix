{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };
  # Input Method
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true; # niri 的 text-input-v3 代理（Wayland 原生输入）
    fcitx5.addons = with pkgs; [
      kdePackages.fcitx5-qt # Qt 应用
      fcitx5-gtk # GTK 应用（Firefox/GTK 系）
      kdePackages.fcitx5-configtool # fcitx5-configtool 图形配置
      kdePackages.fcitx5-chinese-addons # 拼音/双拼等中文引擎（含智能拼音）
      fcitx5-pinyin-zhwiki # 中文维基词库（强化智能拼音联想）
      fcitx5-pinyin-moegirl # 萌娘百科词库
    ];
  };


  # Fonts
  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    font-awesome # waybar 的 U+F5xx/U+F6xx 图标（NF v3 已移除这批旧 FA 字形）
  ];
  # 全局字体：JetBrainsMono Nerd Font 优先（含图标字形），
  # CJK/emoji 作为 fallback 保证中文与表情正常显示
  fonts.fontconfig.defaultFonts = {
    sansSerif = [
      "JetBrainsMono Nerd Font"
      "Noto Sans CJK SC"
      "Noto Sans"
      "DejaVu Sans"
    ];
    serif = [
      "JetBrainsMono Nerd Font"
      "Noto Serif CJK SC"
      "Noto Serif"
      "DejaVu Serif"
    ];
    monospace = [
      "JetBrainsMono Nerd Font"
      "JetBrains Mono"
      "Noto Sans Mono CJK SC"
      "DejaVu Sans Mono"
    ];
    emoji = [ "Noto Color Emoji" ];
  };

  # GTK/Qt 应用也统一用 JetBrainsMono Nerd Font（部分应用读 dconf 而非 fontconfig）
  environment.sessionVariables = {
    # 输入法（Wayland 会话 + XWayland 应用都需要）
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus";
    # 字体
    GTK_FONT_NAME = "JetBrainsMono Nerd Font 11";
    QT_FONT_DPI = "96";
  };

  console = {
    font = "Lat2-Terminus16";
    # keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };
  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  #services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;
}
