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
    auto_install_extensions = {
      java = true;
      vue = true;
    };
    # 外观：JetBrainsMono Nerd Font + Catppuccin Macchiato
    theme = "Catppuccin Macchiato";
    buffer_font_family = "JetBrainsMono Nerd Font";
    buffer_font_size = 14;
    ui_font_family = "JetBrainsMono Nerd Font";
    ui_font_size = 14;
    # 轻量使用：关闭不必要的提示
    telemetry = { diagnostics = false; metrics = false; };
    autosave = "on_focus_change";
    format_on_save = "on";
  };
}
