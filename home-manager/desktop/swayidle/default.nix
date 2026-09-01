{ pkgs, ... }: {
  # User requirement: NEVER blank the screen, even on battery.
  # swayidle is configured with ONLY a lock-before-sleep event and
  # no idle timeout, so nothing dims/blanks on its own.
  services.swayidle = {
    enable = true;

    events = {
      # Lock before suspend/hibernate (systemctl suspend, lid close, etc.)
      before-sleep = "${pkgs.swaylock}/bin/swaylock -fF";
    };
  };
}
