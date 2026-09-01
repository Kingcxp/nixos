{ ... }: {
  xdg.configFile."micro/settings.json".source = ./settings.json;
  xdg.configFile."micro/bindings.json".source = ./bindings.json;
  xdg.configFile."micro/colorschemes/catppuccin-macchiato.micro".source =
    ./colorschemes/catppuccin-macchiato.micro;
  xdg.configFile."micro/colorschemes/catppuccin-macchiato-transparent.micro".source =
    ./colorschemes/catppuccin-macchiato-transparent.micro;
}
