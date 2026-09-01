{
  pkgs,
  ...
}:
{
  # Waybar battery module calls this script (toggle / optimize / menu).
  # The NOPASSWD sudo rule lives at the SYSTEM level (hosts/thinkbook/default.nix),
  # since `security.sudo` is a NixOS option, not a home-manager one.
  home.file.".config/waybar/scripts/battery-control.sh" = {
    source = ./battery-control.sh;
    executable = true;
  };
}
