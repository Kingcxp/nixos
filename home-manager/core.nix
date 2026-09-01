{ username, pkgs, ... }: {
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.11";
  };
  programs.home-manager.enable = true;

  # USB devices — user prefers Dolphin file manager
  services.udiskie = {
    enable = true;
    settings = {
      program_options = {
        file_manager = "${pkgs.kdePackages.dolphin}/bin/dolphin";
      };
    };
  };

  # Secure
  services.gnome-keyring.enable = true;
  home.packages = [ pkgs.gcr ];

  # Theme — Catppuccin Macchiato is the user's global color scheme
  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "Papirus-Dark";
    };
  };
}
