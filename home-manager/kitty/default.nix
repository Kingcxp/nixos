{
  pkgs,
  config,
  ...
}:
{
  # Ship the user's kitty config verbatim. `programs.kitty` would generate its
  # own kitty.conf and conflict with the user's file, so we install the package
  # and deploy the config directly.
  home.packages = [ pkgs.kitty ];

  xdg.configFile."kitty/kitty.conf".source = ./kitty.conf;
  xdg.configFile."kitty/current-theme.conf".source = ./current-theme.conf;
  xdg.configFile."kitty/theme.conf".source = ./theme.conf;
  xdg.configFile."kitty/launch.conf".source = ./launch.conf;
}
