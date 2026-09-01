{ ... }: {
  # User's btop config + Catppuccin theme
  xdg.configFile."btop/btop.conf".source = ./btop.conf;
  xdg.configFile."btop/themes/catppuccin_macchiato.theme".source =
    ./themes/catppuccin_macchiato.theme;
}
