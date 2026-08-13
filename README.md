Personal shell scripts for Linux system automation, theming, and maintenance. Written for an Arch Linux setup with Hyprland on Wayland; `debian.sh` and `nixos.sh` bootstrap a plain (non-Hyprland) Debian or NixOS box using the same dotfiles.

These scripts live in `~/.local/bin` and are installed as part of the dotfiles setup.

---

## Scripts

### `arch.sh` — Arch Linux Installer

A fully automated, three-stage Arch Linux installer for an Intel laptop with NVMe storage, with full-disk LUKS2 encryption.

**Stages:**
- **Part 1** (live ISO): Configures pacman, partitions the drive (EFI + root + home + swap), **LUKS2-encrypts root/home/swap** (`cryptsetup luksFormat`), formats and mounts everything, installs the base system via `pacstrap`, and chroots into the new installation.
- **Part 2** (chroot): Sets timezone (Asia/Kolkata), locale, hostname, sets up keyfile-based auto-unlock for the home/swap LUKS volumes (`/etc/cryptsetup-keys.d`, `/etc/crypttab`) so only the root volume prompts for a password at boot, configures GRUB (including `rd.luks.name=` for the encrypted root), installs the full package set (Hyprland, Waybar, PipeWire, NetworkManager, Bluetooth, Docker, dev tools, etc.), enables systemd services, creates the user, configures autologin via TTY1, sets up GNOME Keyring PAM integration, and installs the udev rule + cron entry for the battery notification scripts.
- **Part 3** (as user): Clones the `.dots` dotfiles repo and this scripts repo, stows the dotfiles, loads GNOME settings via `dconf`, installs Oh My Zsh with plugins, installs JetBrainsMono **and** Maple Mono Nerd Fonts, builds `paru` from the AUR, and installs a set of AUR packages (`hyprqt6engine`, `wlogout`, `google-chrome`, `brave-bin`).

> **Note:** Hardcoded for `anshul333y` username, `nvme0n1` disk, and Intel GPU. Edit variables at the top of each stage before use.
>
> **Security:** the disk-encryption password (`encrypt_pass`) is a plaintext placeholder in the script — always change it before running, and avoid committing a real password if this repo is public.

```bash
# Boot Arch ISO, then:
bash arch.sh
```

---

### `debian.sh` — Debian/Ubuntu Setup Script

Post-install setup for Debian-based systems. This is **not** a Hyprland setup — it configures a standard desktop stack: `kitty` as the terminal, Firefox (from Mozilla's official apt repo), VS Code, Docker, and the same dotfiles/Oh My Zsh/font pipeline used by the other scripts. It also grants the `sudo` group passwordless sudo and switches the default shell to zsh.

```bash
bash debian.sh
```

---

### `nixos.sh` — NixOS Installer

A fully automated, three-stage NixOS installer, structurally similar to `arch.sh`.

**Stages:**
- **Part 1** (live ISO): Partitions and formats the drive (`nvme0n1`, hardcoded), clones the `.dots` repo for its flake-based NixOS config, runs `nixos-install --flake`, then chroots in.
- **Part 2** (chroot): Sets root and user passwords (plaintext placeholders — change before running).
- **Part 3** (as user): Same dotfiles/Oh My Zsh/font setup as `arch.sh` and `debian.sh`.

```bash
# Boot NixOS ISO, then:
bash nixos.sh
```

---

### `update` — Universal System Updater

Detects the package manager(s) present and runs a full system update for all of them in sequence.

**Supports:** `apt`, `pacman` + `paru` (AUR), `nixos-rebuild` (flake), `nix profile`, `flatpak`

```bash
update
```

---

### `hyprstyle` — Wallpaper & Theme Switcher

Cycles through wallpapers in `~/pics/wall/`, applies pywal color generation (from a dedicated `~/.local/venvs/pywal` virtualenv), updates the GNOME color scheme, restarts `foot --server` and Waybar, and sets the wallpaper via `swww` (invoked through a custom `hyprctl dispatch` command, which requires a Hyprland build/patch that supports it).

Optionally accepts a specific wallpaper path as an argument.

```bash
hyprstyle               # cycle to next wallpaper
hyprstyle ~/pics/wall/foo.jpg   # set specific wallpaper
```

**Dependencies:** `pywal` (in `~/.local/venvs/pywal`), `swww`, `waybar`, `foot`, `hyprctl` (custom dispatch support), `gsettings`

---

### `wallhaven` — Wallhaven Batch Downloader

Downloads wallpapers from the [Wallhaven](https://wallhaven.cc) API. Prompts for a source — either a keyword **search** (with a sorting-method picker) or one of your Wallhaven **collections** — then downloads matching images with a progress bar and an `nsxiv` thumbnail preview before moving them into place.

```bash
wallhaven
```

**Prompts for:** source (search / collection); if search, a sorting method (date_added / relevance / random / views / favorites / toplist / hot) and an optional query

**Saves to:** `~/pics/save/` → previewed in `nsxiv` → moved to `~/pics/wall/`

**Requires:** `WALLHAVEN_API_KEY` set in `$XDG_DATA_HOME/envs/wallhaven`, `curl`, `jq`, `nsxiv`

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

All scripts here run under `dash`.

- **`notify-battery-charging`** — notifies on AC plug/unplug events, triggered by a udev rule. Runs under an X11 session context (`DISPLAY`/`XAUTHORITY` exported, invoked via `su`) — this is a holdover from an Xorg setup and may need adapting for a pure-Wayland session.
- **`notify-battery-alert`** — warns when battery is low or critical, and notifies when fully charged. Runs every 5 minutes via cron, debounced with state files in `/tmp`.
- **`notify-brightness`** — adjusts screen brightness up/down via `brightnessctl` and shows the new level with `dunstify`.
- **`notify-volume`** — adjusts or mutes volume via `wpctl` (PipeWire) and shows the new level with `dunstify`.
- **`notify-pacman-updates`** — Waybar custom-module script; outputs a JSON blob with the combined pacman + AUR update count for the status bar.

> `notify-brightness` and `notify-volume` use `dunstify`, which requires the `dunst` notification daemon specifically. `notify-battery-alert` and `notify-battery-charging` use the generic `notify-send` and will work with any `libnotify`-compatible daemon.

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
| `arch.sh` | Run from Arch ISO; uses `cryptsetup` for LUKS2 encryption |
| `debian.sh` | Run on a fresh Debian/Ubuntu install; `kitty`, Docker, VS Code |
| `nixos.sh` | Run from NixOS ISO; flake-based config in `.dots` |
| `update` | `pacman`, `paru`, `apt`, `nix`, `flatpak` (auto-detected) |
| `hyprstyle` | `pywal` (venv), `swww`, `waybar`, `foot`, patched `hyprctl`, `gsettings` |
| `wallhaven` | `curl`, `jq`, `nsxiv`, `WALLHAVEN_API_KEY` env var |
| `connect` | `nmcli`, `bluetoothctl` |
| `wifi` | `nmcli` |
| `notify/` | `dash`, `libnotify` or `dunst` (`dunstify`), `brightnessctl`, PipeWire (`wpctl`), `acpi`, `pacman-contrib` |
