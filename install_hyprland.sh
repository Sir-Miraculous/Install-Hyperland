#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Ensure the script is run with superuser privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Update and install reflector
pacman -Syu --noconfirm reflector

# Configure reflector to update mirrorlist with the fastest HTTPS mirrors (run once now)
reflector --latest 20 --protocol https --sort rate --threads 5 --save /etc/pacman.d/mirrorlist

# Step 1: Install Paru
pacman -Syu --noconfirm git base-devel

if ! command -v paru &> /dev/null; then
  if [ ! -d "paru" ]; then
    git clone https://aur.archlinux.org/paru.git
  fi
  cd paru
  makepkg -si --noconfirm
  cd ..
fi

# Step 2: Install Required Dependencies
paru -S --needed --noconfirm cmake ninja
paru -S --noconfirm glfw-wayland g++ libx11 libxcb xcb-util-keysyms xcb-util-wm \
xcb-util-xrm xorg-server-xwayland libxfixes libxrandr libxcomposite \
pixman libinput xcb-util-image xcb-util-renderutil mesa wayland-protocols \
wayland libegl libxcursor vulkan-headers vulkan-icd-loader pango

# Step 3: Clone the Hyprland Repository
if [ ! -d "Hyprland" ]; then
  git clone https://github.com/hyprwm/Hyprland
  cd Hyprland
else
  cd Hyprland
  git pull
fi

# Step 4: Build and Install Hyprland
git submodule update --init --recursive
cmake -S . -B build -GNinja
cd build
ninja
ninja install

# Step 5: Install Additional Applications for Hyprland
paru -S --noconfirm swaync pipewire wireplumber pipewire-alsa pipewire-jack pipewire-pulse xdg-desktop-portal-hyprland polkit-kde-agent qt5-wayland qt6-wayland hyprpaper hyprpicker hypridle hyprlock rofi clipman wl-clipboard firefox dolphin dolphin-plugins neovim alacritty gparted vlc sddm flatpak btrfs-progs exfat-utils f2fs-tools jfsutils nilfs-utils ntfs-3g reiserfsprogs xfsprogs

# Enable and start user services
services=(
  pipewire
  pipewire-pulse
  wireplumber
  swaync
  xdg-desktop-portal-hyprland
  polkit-kde-agent
)

for service in "${services[@]}"; do
  systemctl --user enable $service
  systemctl --user start $service

  if systemctl --user is-active --quiet $service; then
    echo "$service is running."
  else
    echo "Error: $service failed to start. Attempting to restart..."
    systemctl --user restart $service

    if systemctl --user is-active --quiet $service; then
      echo "$service is now running after restart."
    else
      echo "Error: $service failed to start after restart."
      exit 1
    fi
  fi
done

# Enable SDDM as the display manager
systemctl enable sddm
systemctl start sddm

if systemctl is-active --quiet sddm; then
  echo "SDDM is running."
else
  echo "Error: SDDM failed to start."
  exit 1
fi

# Enable and configure Flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
systemctl enable --now flatpak-system-helper.service || true

if systemctl is-active --quiet flatpak-system-helper; then
  echo "Flatpak system helper is running."
else
  echo "Warning: Flatpak system helper failed to start. Please check the service name."
fi

echo "Hyprland installation completed with additional applications."

# Step 6: Setup a cron job to update mirrors every Sunday at midnight
if ! command -v crontab &> /dev/null; then
  pacman -S --noconfirm cronie
  systemctl enable cronie
  systemctl start cronie
fi
(crontab -l 2>/dev/null; echo "0 0 * * SUN sudo reflector --latest 20 --protocol https --sort rate --threads 5 --save /etc/pacman.d/mirrorlist") | crontab -

# Step 7: Create systemd service to update mirrors on startup
tee /etc/systemd/system/update-mirrors.service > /dev/null <<EOF
[Unit]
Description=Update Arch Linux mirrors with reflector
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/reflector --latest 20 --protocol https --sort rate --threads 5 --save /etc/pacman.d/mirrorlist

[Install]
WantedBy=multi-user.target
EOF

# Enable the systemd service
systemctl enable update-mirrors.service
systemctl start update-mirrors.service

# Create systemd timer for updating mirrors weekly
tee /etc/systemd/system/update-mirrors.timer > /dev/null <<EOF
[Unit]
Description=Run update-mirrors.service weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start the systemd timer
systemctl enable update-mirrors.timer
systemctl start update-mirrors.timer

echo "Mirror update services configured."
