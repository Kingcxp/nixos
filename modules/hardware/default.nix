{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./main.nix
    ./network.nix
    ./input.nix
    ./bluetooth.nix
    ./pipewire.nix
  ];
}
