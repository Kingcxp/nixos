{
  description = "NixOS flake for kingcq's ThinkBook (migrated from Hyprland/Arch to Niri)";

  # Vendored flake.lock pins a verified, buildable version set of all inputs.
  # nix-community cache is used for extra packages (nix-alien, omp-nix, etc.).
  nixConfig = {
    # 二进制缓存（按顺序尝试，前一个不可达会自动回退到下一个）：
    #   1. cernet（大陆主力源，校园网/国内速度最好）
    #   2. cache.nixos.org（Nix 内置官方源，始终兜底）
    #   3. nix-community.cachix.org（nix-alien / omp-nix 等包必需）
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
    catppuccin.url = "github:catppuccin/nix";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs";
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
      catppuccin,
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
          isVM ? false,
        }:
        let
          specialArgs = {
            inherit
              self
              username
              system
              inputs
              isVM
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
                  home-manager.sharedModules = [ catppuccin.homeModules.default ];
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
          extraModules = [ catppuccin.nixosModules.default ];
          extraSpecialArgs = {
            alien-pkgs = nix-alien.packages.x86_64-linux;
            omp-pkgs = omp-nix.packages.x86_64-linux;
          };
        };

        # VirtualBox 试装变体：BIOS GRUB 目标盘 /dev/sda、niri 自动检测输出。
        # hardware-configuration.nix 用 VM 内 nixos-generate-config 的产物
        # （含自动的 virtualbox guest.enable，经 modules/hardware/virtualbox-guest.nix 修复可构建）。
        thinkbook-vm = mkHost {
          system = "x86_64-linux";
          hostModule = ./hosts/thinkbook;
          homeModules = [ ./hm-profile/niri-desktop.nix ];
          extraModules = [
            catppuccin.nixosModules.default
            {
              boot.loader.grub.device = "/dev/sda";
              virtualisation.virtualbox.guest.enable = true;
            }
          ];
          extraSpecialArgs = {
            isVM = true;
            alien-pkgs = nix-alien.packages.x86_64-linux;
            omp-pkgs = omp-nix.packages.x86_64-linux;
          };
        };
      };
    };
}
