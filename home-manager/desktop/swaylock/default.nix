{ config, ... }: {
  # Lock screen — Catppuccin Macchiato theme ported from user's hyprlock,
  # using swaylock (the niri-ecosystem standard) with the user's wallpaper.
  programs.swaylock = {
    enable = true;
    settings = {
      image = "${config.xdg.configHome}/wallpaper/wallpaper.jpg";
      scaling = "fill";

      # Catppuccin Macchiato palette
      color = "18192680";

      "font-size" = 12;
      "indicator-radius" = 60;
      "indicator-idle-visible" = true;
      "ring-color" = "b7bdf8"; # lavender
      "line-color" = "00000000";
      "text-color" = "cad3f5"; # text
      "key-hl-color" = "8aadf4"; # blue
      "separator-color" = "f5bde680"; # pink
      "inside-color" = "1e203000"; # mantle
      "bs-hl-color" = "ed8796"; # red
      "caps-lock-bs-hl-color" = "eed49f"; # yellow
      "caps-lock-key-hl-color" = "a6da95"; # green
      "show-failed-attempts" = true;
    };
  };
}
