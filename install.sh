#!/usr/bin/env bash

set -euo pipefail

TARGET_USER="${SUDO_USER:-${USER}}"
USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

pacman -Syu --noconfirm

# Core packages
PKGS=(xfce4 xfce4-session xorg-xwayland wayland wayland-protocols libinput 
      xdg-desktop-portal xdg-desktop-portal-wlr dbus polkit labwc util-linux)
pacman -S --needed --noconfirm "${PKGS[@]}"

# GPU Drivers
GPU_INFO="$(lspci -nnk | grep -E "VGA|3D" -m1)"
if echo "$GPU_INFO" | grep -qi 'NVIDIA'; then
    pacman -S --needed --noconfirm nvidia nvidia-utils
elif echo "$GPU_INFO" | grep -Eqi 'AMD|ATI'; then
    pacman -S --needed --noconfirm mesa libva-mesa-driver vulkan-radeon
elif echo "$GPU_INFO" | grep -qi 'Intel'; then
    pacman -S --needed --noconfirm mesa libva-mesa-driver vulkan-intel
else
    pacman -S --needed --noconfirm mesa
fi

# Passwordless sudo
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99_nopasswd_wheel
chmod 0440 /etc/sudoers.d/99_nopasswd_wheel
usermod -aG wheel "$TARGET_USER"

# Install yay
if ! command -v yay >/dev/null 2>&1; then
    pacman -S --needed --noconfirm base-devel git
    TMP=$(mktemp -d)
    chown "$TARGET_USER":"$TARGET_USER" "$TMP"
    su - "$TARGET_USER" -c "git clone --depth 1 https://aur.archlinux.org/yay.git $TMP/yay && cd $TMP/yay && makepkg -si --noconfirm"
    rm -rf "$TMP"
fi

# Optional System Packages
read -p "Install additional system packages (plugins, bluetooth, thumbnails)? [y/N]: " install_sys
if [[ "$install_sys" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    pacman -S --needed --noconfirm xfce4-goodies pavucontrol network-manager-applet \
    blueman gvfs gvfs-mtp gvfs-smb tumbler ffmpegthumbnailer
fi

# Optional User Packages
read -p "Install essential work packages (Office, Chrome, VS Code)? [y/N]: " install_user
if [[ "$install_user" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    pacman -S --needed --noconfirm thunar thunar-archive-plugin thunar-volman \
    thunar-media-tags-plugin libreoffice-fresh remmina vlc gimp git
    su - "$TARGET_USER" -c "yay -S --needed --noconfirm google-chrome visual-studio-code-bin"
fi

# TTY Autologin
GETTY_DIR="/etc/systemd/system/getty@tty1.service.d"
mkdir -p "$GETTY_DIR"
cat > "$GETTY_DIR/override.conf" <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $TARGET_USER --noclear %I \$TERM
Type=simple
EOF

systemctl set-default multi-user.target
systemctl daemon-reload

# Labwc configuration for Xfce
CONF_DIR="$USER_HOME/.config/labwc"
mkdir -p "$CONF_DIR"
echo "xfce4-session &" > "$CONF_DIR/autostart"
chown -R "$TARGET_USER":"$TARGET_USER" "$USER_HOME/.config"

# Startup logic
BASH_PROF="$USER_HOME/.bash_profile"
touch "$BASH_PROF"
sed -i '/labwc/d' "$BASH_PROF"
cat >> "$BASH_PROF" <<EOF
if [[ -z \$DISPLAY && \$(tty) == /dev/tty1 ]]; then
  export XDG_SESSION_TYPE=wayland
  exec labwc
fi
EOF
chown "$TARGET_USER":"$TARGET_USER" "$BASH_PROF"

echo "Done. Reboot to start Xfce Wayland."