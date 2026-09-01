# NixOS Configuration — kingcq

A flake-based NixOS configuration for the ThinkBook laptop
(11th Gen Intel i7-1160G7 / Iris Xe / NVMe / UEFI), derived from a friend's
repo (`../nixos`) with the user's own preferences taking precedence wherever
the two overlapped.

## Quick Start

Point `/etc/nixos` at this repo and rebuild:

```bash
sudo rm -rf /etc/nixos
sudo ln -s /path/to/nixos_kingcq /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#thinkbook
```

> **Hardware UUIDs.** `hosts/thinkbook/hardware-configuration.nix` was written
> by hand from the previous install's layout. If this machine is freshly
> partitioned, **regenerate it** during install:
>
> ```bash
> nixos-generate-config --root /mnt
> cp /mnt/etc/nixos/hardware-configuration.nix hosts/thinkbook/hardware-configuration.nix
> ```

## Repository Layout

```text
flake.nix                          # inputs, mkHost helper, host registry
flake.lock                         # pinned versions (locked to the same revs
                                   #   as the friend's repo, proven to build)
hosts/thinkbook/                   # this laptop: Intel tuning, TLP, hardware
hm-profile/niri-desktop.nix        # the shared Home Manager desktop profile
modules/hardware/                  # bootloader, kernel, network, input, bluetooth, pipewire
modules/software/system/main.nix   # base system policy (user, fish, utils)
modules/software/desktop/          # greetd (password login) + niri
home-manager/                      # user apps and dotfiles
  core.nix                         # home state, keyring, dark theme
  applications.nix                 # firefox, dolphin, qq, … + mime defaults
  fish.nix                         # fish shell (user prefers fish over zsh)
  kitty/  micro/  btop/  yazi/     # user's app configs, deployed verbatim
  tmux/  nvim/                     # user's tmux + nvim (AstroNvim) configs
  powertop/                        # powertop-toggle.sh + waybar wiring
  desktop/
    niri/                          # niri config (migrated from Hyprland)
    waybar/  wofi/  wlogout/  dunst/
    swayidle/                      # never blank the screen (user requirement)
    swaylock/                      # catppuccin lock screen
    kanshi/                        # monitor profiles (built-in panel)
    wallpaper/                     # user's wallpaper
```

## Migration from the user's Hyprland setup

The desktop was migrated **Hyprland → niri** (niri has a stable config format
and is the desktop used in the reference repo):

| User (Hyprland) | This config (niri) |
| --- | --- |
| `hyprland.conf` | `home-manager/desktop/niri/config/*.kdl` |
| `$mainMod = SUPER` | `Mod` (Super on TTY) |
| SUPER+1..9 workspaces | Mod+1..9 `focus-workspace` |
| Alt+Tab `workspace previous` | Alt+Tab `focus-workspace-previous` (two most recent) |
| SUPER+Q kitty / R wofi / E dolphin / F firefox / M wlogout | same, `spawn …` |
| SUPER+C killactive | Mod+C `close-window` |
| SUPER+V togglefloating | Mod+V `toggle-window-floating` |
| SUPER+P hyprshot | Mod+P `screenshot` |
| hypridle (never blank) | swayidle — **only** lock-before-sleep, no idle timeout |
| hyprlock (catppuccin) | swaylock — catppuccin palette + same wallpaper |
| hyprpaper | swaybg via `wallpaper.kdl` |
| waybar hyprland/workspaces | waybar `niri/workspaces` |
| waybar hyprland/window | waybar `niri/window` |

### Overlap policy — the user's config wins

Where the user's and the friend's configs overlapped, the user's choices were
kept:

- **Terminal**: kitty (friend used alacritty)
- **Shell**: fish (friend used zsh)
- **Notifications**: dunst (friend used mako)
- **Launcher / logout**: wofi, wlogout (user's styles)
- **Editor**: the user's nvim config (AstroNvim-based)
- **File manager**: dolphin (`kdePackages.dolphin`; friend used nautilus)
- **Cursor / theme**: catppuccin-macchiato-lavender-cursors, Catppuccin Macchiato
- **Corner radius**: ~8px square-ish (user preference), applied via
  `windowrule.kdl` `geometry-corner-radius 8`

### Things deliberately NOT carried over

- **Friend's zsh / mako / alacritty / vscode / zed / opencode / kanshi for
  external monitors** — replaced by the user's equivalents or dropped.
- **Steam / Minecraft / Android Studio / Waydroid** — the reference repo's
  gaming/Android modules were dropped (not part of the user's setup).
- **v2raya proxy service** — removed from the base system module (not in the
  user's config; re-add via `modules/software/system/main.nix` if needed).

## Login

`modules/software/desktop/greetd.nix` shows a **password login** via the
`tuigreet` greeter before starting the niri session. No autologin is
configured — the user wants a password prompt at boot (security).

## Screen blanking

`home-manager/desktop/swayidle/default.nix` has **no idle timeout** — the
screen never dims or blanks on its own, even on battery. It only locks before
suspend/lid-close.

## Screen brightness

- Waybar `backlight` module uses **native scrolling** (`scroll-step: 1.0` +
  `smooth-scrolling-threshold`) instead of fixed 5% shell commands — 1% steps
  are precise and touchpad smooth-scroll is aggregated, so it is not twitchy.
- Both the waybar module (`min-brightness: 5`) and the niri brightness keys
  (`brightnessctl -n 4800`) are **clamped to a 5% floor**, so the backlight
  never drops to 0% (which would black out the screen).
- Note: `-n 4800` is hard-coded to this laptop's `intel_backlight` max
  (96000 × 5%). If the kernel/driver changes the max, recompute it with
  `brightnessctl --class=backlight max`.

## Verification

The configuration was **evaluated successfully** on this machine with
`nix eval .#nixosConfigurations.thinkbook.config.system.build.toplevel.drvPath`
→ `nixos-system-thinkbook-26.11.20260810.2fcb964.drv` (exit 0). All modules,
options and import paths are valid; spot-checks confirmed: no greetd
autologin, fish default shell, v2raya disabled, niri enabled, dolphin present
(nautilus removed).

To go further (download all packages / build the bootable system) before
installing:

```bash
nix flake check --flake /etc/nixos#thinkbook   # or
nixos-rebuild build --flake /etc/nixos#thinkbook
```

Version pinning is strict: `flake.lock` is locked to the exact revisions
(`nixpkgs` rev `2fcb964de67f`, home-manager rev `99e84ee7387f`) used by the
reference repo, which are proven to evaluate together. Do not bump inputs
without testing.

## State version

`system.stateVersion = "25.05"`; home-manager `home.stateVersion = "25.11"`.
