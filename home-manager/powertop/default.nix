{
  pkgs,
  ...
}:
{
  # Waybar battery module calls this script (strategy / charge / optimize).
  # Deployed to ~/.local/bin (on PATH) so the on-click commands in
  # waybar/config.jsonc (~/.local/bin/battery-control.sh) resolve.
  # The NOPASSWD sudo rule lives at the SYSTEM level (hosts/thinkbook/default.nix),
  # since `security.sudo` is a NixOS option, not a home-manager one.
  home.file.".local/bin/battery-control.sh" = {
    source = ./battery-control.sh;
    executable = true;
  };
}
