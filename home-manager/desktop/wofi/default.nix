{ pkgs, config, ... }: {
  xdg.configFile."wofi/style.css".source = ./style.css;

  home.packages = with pkgs; [
    wofi
  ];
}
