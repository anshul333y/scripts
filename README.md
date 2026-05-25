# scripts

Personal shell scripts for Linux system automation, theming, and maintenance. Designed for an Arch Linux / NixOS setup with Hyprland on Wayland.

These scripts live in `~/.local/bin` and are installed as part of the dotfiles setup.

---

## Scripts

### `arch.sh` — Arch Linux Installer

A fully automated, three-stage Arch Linux installer for an Intel laptop with NVMe storage.

**Stages:**
- **Part 1** (live ISO): Configures pacman, partitions and formats drives (EFI + root + home + swap), installs the base system via `pacstrap`, and chroots into the new installation.
- **Part 2** (chroot): Sets timezone (Asia/Kolkata), locale, hostname, GRUB bootloader, installs the full package set (Hyprland, Waybar, PipeWire, NetworkManager, Bluetooth, Docker, dev tools, etc.), enables systemd services, creates the user, configures autologin via TTY1, and sets up GNOME Keyring PAM integration.
- **Part 3** (as user): Clones dotfiles and Neovim config, stows them, installs Oh My Zsh with plugins, installs Maple Mono Nerd Font, builds `paru` from the AUR, and installs AUR packages.

> **Note:** Hardcoded for `anshul333y` username, `nvme0n1` disk, and Intel GPU. Edit variables at the top of each stage before use.

```bash
# Boot Arch ISO, then:
bash arch.sh
```

---

### `debian.sh` — Debian/Ubuntu Setup Script

Equivalent post-install setup script for Debian-based systems. Mirrors the package selection and configuration from `arch.sh` for apt-based environments.

---

### `nixos.sh` — NixOS Setup Script

Bootstrap script for NixOS. Handles flake-based configuration setup and initial system generation.

---

### `update` — Universal System Updater

Detects the package manager(s) present and runs a full system update for all of them in sequence.

**Supports:** `apt`, `pacman` + `paru` (AUR), `nixos-rebuild` (flake), `nix profile`, `flatpak`

```bash
update
```

---

### `hyprstyle` — Wallpaper & Theme Switcher

Cycles through wallpapers in `~/pics/wall/`, applies pywal color generation, updates GNOME color scheme, and reloads Hyprpaper + Waybar + Hyprland config.

Optionally accepts a specific wallpaper path as an argument.

```bash
hyprstyle               # cycle to next wallpaper
hyprstyle ~/pics/wall/foo.jpg   # set specific wallpaper
```

**Dependencies:** `pywal`, `hyprpaper`, `waybar`, `hyprctl`, `gsettings`

---

### `wallhaven` — Wallhaven Batch Downloader

Downloads wallpapers from the [Wallhaven](https://wallhaven.cc) API with an interactive sorting picker, progress bar, and sxiv thumbnail preview.

```bash
wallhaven
```

**Prompts for:** sorting method (date_added / relevance / random / views / favorites / toplist / hot)

**Saves to:** `~/pics/save/` → previewed in sxiv → moved to `~/pics/wall/`

**Requires:** `API_KEY` environment variable set (e.g. in `~/.local/env/`), `curl`, `jq`, `sxiv`

---

### `connect` — Wi-Fi + Bluetooth One-liner

Scans and connects to a Wi-Fi network and a Bluetooth device simultaneously.

```bash
connect <SSID> <bluetooth-mac>
```

**Dependencies:** `nmcli`, `bluetoothctl`

---

### `wifi` — Wi-Fi Auto-Reconnect Daemon

Polls every 30 seconds and reconnects to `DTU-WiFIe` if the connection drops. Useful for unreliable campus networks.

```bash
wifi &   # or run via a systemd user service
```

> Edit the `SSID` variable to change the target network.

---

### `notify/` — Notification Scripts

Battery-related desktop notifications, triggered via udev rules and cron:

- **`notify-battery-charging`** — notifies on AC plug/unplug events (triggered by udev)
- **`notify-battery-alert`** — warns when battery is low (runs every 5 minutes via cron)

---

## Installation

These scripts are cloned directly into `~/.local/bin` as part of the dotfiles setup:

```bash
git clone https://github.com/anshul333y/scripts.git ~/.local/bin
```

Make sure `~/.local/bin` is in your `$PATH`.

---

## Dependencies Summary

| Script | Key Dependencies |
|---|---|
| `arch.sh` | Run from Arch ISO |
| `update` | `pacman`, `paru`, `apt`, `nix`, `flatpak` (auto-detected) |
| `hyprstyle` | `pywal`, `hyprctl`, `hyprpaper`, `waybar`, `gsettings` |
| `wallhaven` | `curl`, `jq`, `sxiv`, Wallhaven API key |
| `connect` | `nmcli`, `bluetoothctl` |
| `wifi` | `nmcli` |
| `notify/` | `libnotify` (`notify-send`) |
