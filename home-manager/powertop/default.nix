{
  pkgs,
  ...
}:
{
  # Waybar battery module calls this script (toggle / optimize / menu).
  # The NOPASSWD sudo rule lives at the SYSTEM level (hosts/thinkbook/default.nix),
  # since `security.sudo` is a NixOS option, not a home-manager one.
  home.file.".config/waybar/scripts/powertop-toggle.sh" = {
    source = ./powertop-toggle.sh;
    executable = true;
  };
}
