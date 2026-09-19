{
  pkgs,
  ...
}:
# Zed 轻量编辑器：仅装默认不支持的语言扩展（Java/Vue）+ 基本外观设置
{
  home.packages = [ pkgs.zed-editor ];

  xdg.configFile."zed/settings.json".text = builtins.toJSON {
    # 语言扩展：Zed 内置 C/C++/Go/Rust/Python/HTML/CSS/JS/TS/JSON/YAML，
    # 只有 Java 与 Vue 需要扩展（auto_install_extensions 会自动安装）
    # catppuccin / catppuccin-icons：主题与图标（对齐 Arch 上已装的扩展）
    auto_install_extensions = {
      java = true;
      vue = true;
      catppuccin = true;
      catppuccin-icons = true;
    };
    # 外观：JetBrainsMono Nerd Font + Catppuccin Macchiato（对齐 Arch 的
    # ~/.config/zed/settings.json：VSCode 键位、常显 minimap、面板停靠、16/15 字号）
    theme = {
      mode = "dark";
      light = "Ayu Light";
      dark = "Catppuccin Macchiato";
    };
    icon_theme = "Catppuccin Macchiato";
    base_keymap = "VSCode";
    minimap.show = "always";
    project_panel.dock = "left";
    git_panel.dock = "left";
    outline_panel.dock = "left";
    agent.dock = "right";
    buffer_font_family = "JetBrainsMono Nerd Font";
    buffer_font_size = 15;
    ui_font_family = "JetBrainsMono Nerd Font";
    ui_font_size = 16;
    # 轻量使用：关闭不必要的提示
    telemetry = { diagnostics = false; metrics = false; };
    autosave = "on_focus_change";
    format_on_save = "on";
  };
}
