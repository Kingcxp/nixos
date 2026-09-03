{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./main.nix
    ./virtualbox-guest.nix
    ./network.nix
    ./input.nix
    ./bluetooth.nix
    ./pipewire.nix
  ];
}
