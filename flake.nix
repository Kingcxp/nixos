{
  description = "NixOS flake for kingcq's ThinkBook (migrated from Hyprland/Arch to Niri)";

  # Inputs kept identical to the reference repo (RandomLemon/nixos) so the
  # vendored flake.lock stays a valid, verified version set. Only the
  # outputs differ (single x86_64 host, user `kingcq`).
  nixConfig = {
    extra-substituters = [
      "https://mirrors.cernet.edu.cn/nix-channels/store"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.url = "github:thiagokokada/nix-alien";
    omp-nix.url = "github:yuxqiu/omp-nix";
    omp-nix.inputs.nixpkgs.follows = "nixpkgs";
    x1e-nixos-config.url = "github:kuruczgy/x1e-nixos-config";
    x1e-nixos-config.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-alien,
      omp-nix,
      x1e-nixos-config,
      ...
    }@inputs:
    let
      username = "kingcq";

      mkHost =
        {
          system,
          hostModule,
          homeModules ? [ ],
          extraSpecialArgs ? { },
          extraModules ? [ ],
        }:
        let
          specialArgs = {
            inherit
              self
              username
              system
              inputs
              ;
          }
          // extraSpecialArgs;
        in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            { nix.settings.trusted-users = [ username ]; }
            hostModule
          ]
          ++ (
            if homeModules != [ ] then
              [
                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.backupFileExtension = "hm.bak";
                  home-manager.extraSpecialArgs = inputs // specialArgs;
                  home-manager.users.${username} = {
                    imports = homeModules;
                  };
                }
              ]
            else
              [ ]
          )
          ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        thinkbook = mkHost {
          system = "x86_64-linux";
          hostModule = ./hosts/thinkbook;
          homeModules = [ ./hm-profile/niri-desktop.nix ];
          extraSpecialArgs = {
            alien-pkgs = nix-alien.packages.x86_64-linux;
            omp-pkgs = omp-nix.packages.x86_64-linux;
          };
        };
      };
    };
}
