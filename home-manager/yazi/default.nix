{ ... }: {
  # User's yazi config
  xdg.configFile."yazi/theme.toml".source = ./theme.toml;
  xdg.configFile."yazi/package.toml".source = ./package.toml;

  # theme.toml 里 `syntect_theme` 指向的语法高亮主题（原配置引用了这个路径，
  # 但两边的文件都不存在 → 预览高亮一直是 yazi 默认色）。
  # 文件取自官方仓库 catppuccin/bat: themes/Catppuccin Macchiato.tmTheme
  # （MIT，未改动；原样内置以避免依赖外部路径）。
  xdg.configFile."yazi/Catppuccin-macchiato.tmTheme".source =
    ./Catppuccin-macchiato.tmTheme;
}
