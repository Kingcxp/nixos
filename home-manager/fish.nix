{
  pkgs,
  lib,
  ...
}:
{
  # Shell — user prefers fish over zsh (friend uses zsh; user's config wins).
  # home-manager's programs.fish owns ~/.config/fish/config.fish, so the
  # user's lines + NixOS aliases are merged via shellInit (no file conflict).
  programs.fish = {
    enable = true;
    shellInit = ''
      # From the user's original config.fish
      export MICRO_TRUECOLOR=1
      export EDITOR=nvim

      # NixOS convenience aliases (ported from the friend's zsh setup)
      alias update="sudo nixos-rebuild switch"
    '';
  };
}
