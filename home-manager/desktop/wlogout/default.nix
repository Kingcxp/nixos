{ pkgs, config, ... }: {
  xdg.configFile."wlogout/layout".source = ./layout;
  xdg.configFile."wlogout/style.css".source = ./style.css;

  xdg.configFile."wlogout/icons/hibernate.png".source = ./icons/hibernate.png;
  xdg.configFile."wlogout/icons/logout.png".source = ./icons/logout.png;
  xdg.configFile."wlogout/icons/reboot.png".source = ./icons/reboot.png;
  xdg.configFile."wlogout/icons/shutdown.png".source = ./icons/shutdown.png;
  xdg.configFile."wlogout/icons/suspend.png".source = ./icons/suspend.png;
  xdg.configFile."wlogout/icons/lock.png".source = ./icons/lock.png;

  home.packages = with pkgs; [
    wlogout
  ];
}
