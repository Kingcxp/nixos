{
  ...
}:
{
  # fcitx5 用户配置 —— 与 myconfig/fcitx5 一致（原样部署）
  # profile: 默认输入法 pinyin；config: Ctrl+Space 切换
  xdg.configFile."fcitx5/profile".source = ./profile;
  xdg.configFile."fcitx5/config".source = ./config;
  xdg.configFile."fcitx5/conf/pinyin.conf".source = ./conf/pinyin.conf;
  xdg.configFile."fcitx5/conf/punctuation.conf".source = ./conf/punctuation.conf;
}
