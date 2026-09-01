{
  config,
  lib,
  pkgs,
  ...
}:
{
  # greetd
  services.greetd = {
    enable = true;
    settings = {
      # Password login via the tuigreet greeter. No autologin: the user
      # explicitly wants a password prompt at boot (security).
      default_session = {
        command = "tuigreet --time --remember --cmd niri-session";
        user = "greeter";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    tuigreet
  ];

  # this is a life saver.
  # literally no documentation about this anywhere.
  # might be good to write about this...
  # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
}
