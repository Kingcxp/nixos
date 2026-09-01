{ pkgs, ... }: {
  # User prefers dunst (over friend's mako) — user's config wins.
  # The dunstrc is deployed verbatim; dunst is launched from niri startup.kdl.
  home.packages = [ pkgs.dunst ];

  xdg.configFile."dunst/dunstrc".source = ./dunstrc;
}
