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
        # --theme：tuigreet 0.9.1 的内联配色 spec（component=color;…），
        # 只能用终端支持的 ANSI 颜色名。取值按 Catppuccin Macchiato 近似：
        #   container=base、border/title/greet/button=lavender、
        #   prompt=blue、action=teal、time=overlay0
        command = "tuigreet --time --remember --theme 'container=black;text=white;border=lightmagenta;title=lightmagenta;greet=lightmagenta;prompt=lightblue;input=white;action=lightcyan;button=lightmagenta;time=darkgray' --cmd niri-session";
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
