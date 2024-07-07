#!/bin/bash

# Function to cleanup files
cleanup() {
    echo "Cleaning up..."
    rm -rf Hyprland paru
}

# Install Paru AUR helper
echo "Installing Paru AUR helper..."
git clone https://aur.archlinux.org/paru.git
cd paru || { echo "Failed to enter paru directory"; exit 1; }
makepkg -si --noconfirm
cd ..
rm -rf paru  # Separate cleanup for paru

# Update the system
echo "Updating the system..."
paru -Syu --noconfirm

# Install dependencies
echo "Installing dependencies..."
paru -S --needed base-devel git cmake ninja meson wayland wayland-protocols libx11 libxinerama libxfixes libxrandr cairo libinput xorg-xwayland vulkan-headers vulkan-icd-loader vulkan-validation-layers glew glm pango libpcre2 ffmpeg libdisplay-info jsoncpp libliftoff libdrm libseat swaync pipewire wireplumber pipewire-alsa pipewire-jack pipewire-pulse xdg-desktop-portal-hyprland hyprcursor hyprwayland-scanner xcb-util-errors polkit-kde-agent qt5-wayland qt6-wayland hyprpaper hyprpicker hypridle hyprlock rofi clipman wl-clipboard firefox dolphin dolphin-plugins neovim alacritty gparted vlc sddm flatpak btrfs-progs exfat-utils f2fs-tools jfsutils nilfs-utils ntfs-3g reiserfsprogs xfsprogs --noconfirm

# Build and install Hyprland from source
echo "Building and installing Hyprland from source..."
git clone https://github.com/vaxerski/Hyprland
cd Hyprland || { echo "Failed to enter Hyprland directory"; cleanup; exit 1; }
make
sudo make install
cd ..
cleanup

# Enable services
echo "Enabling services..."
sudo systemctl enable --now pipewire.service
sudo systemctl enable --now wireplumber.service
sudo systemctl enable --now xdg-desktop-portal-hyprland.service
sudo systemctl enable sddm.service

# Configure Flatpak
echo "Configuring Flatpak..."
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Create Hyprland configuration directory
echo "Creating Hyprland configuration directory..."
mkdir -p ~/.config/hypr

# Download configuration file from GitHub
echo "Downloading configuration file from GitHub..."
curl -o ~/.config/hypr/hyprland.conf https://raw.githubusercontent.com/Sir-Miraculous/Hyprland.conf/main/hyprland.conf

# Set environment variable for Hyprland
echo "Setting environment variables..."
echo 'export XDG_CURRENT_DESKTOP=Hyprland' >> ~/.profile

echo "Installation completed successfully! Make sure all the services are enabled and check the configuration in ~/.config/hypr/hyprland.conf."

