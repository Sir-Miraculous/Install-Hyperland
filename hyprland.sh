#!/bin/bash

echo "Hyprland Installer"

# Update the system without prompting for confirmation
sudo pacman -Syu --noconfirm

# Install yay AUR helper
sudo pacman -S --needed git base-devel --noconfirm
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
rm -rf yay

# Generate yay database
yay -Y --gendb

# Update the system and AUR packages, including development packages
yay -Syu --devel --noconfirm

# Save the current development packages
yay -Y --devel --save

# Install Hyprland dependencies and additional packages
yay -S gdb ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms \
libxfixes libx11 libxcomposite xorg-xinput libxrender pixman wayland-protocols \
cairo pango seatd libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff \
libdisplay-info cpio tomlplusplus hyprlang hyprcursor hyprwayland-scanner \
xcb-util-errors hyprutils hyprpaper hyprpicker hyprlock hypridle  --noconfirm

# Enable and start seatd service
sudo systemctl enable seatd.service
sudo systemctl start seatd.service

# Compile and install Hyprland
git clone --recursive https://github.com/hyprwm/Hyprland
cd Hyprland
make all && sudo make install
cd ..
rm -rf Hyprland

echo "Thank you for using my script."
