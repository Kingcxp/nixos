{ pkgs, ... }:
{
  services.kanshi.enable = true;

  # This machine: single built-in panel (eDP-1). Profiles for hotplug
  # can be added once external monitors are known (via `niri msg outputs`).
  xdg.configFile."kanshi/config".text = ''
    profile builtin {
      output eDP-1 enable
    }
  '';
}
