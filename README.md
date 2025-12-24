# Wayn

Minimal post-install script for Arch Linux to provision a barebones Xfce Wayland session and a few convenience settings.

## Quick usage

```bash
cd /tmp/
sudo git clone https://github.com/Levitifox/wayn.git
sudo chown -R <username>:<username> wayn/
cd wayn/
chmod +x install.sh
sudo ./install.sh
```

## What the script changes

* Installs packages: minimal Xfce components, Wayland, `labwc`, XWayland, `libinput`, portals, and common Wayland plumbing.
* Detects GPU vendor (Intel / AMD / NVIDIA) using `lspci` and installs a reasonable default driver set (`mesa`, `vulkan-*`, or `nvidia` packages).
* Installs `yay` (AUR helper) if not already present.
* Creates a systemd getty override to autologin the target user on `tty1`.
* Sets default boot target to `multi-user.target` (console).
* Appends a `~/.profile` snippet for the autologin user that will `exec startxfce4 --wayland` on `tty1`.
* Adds the target user to the `wheel` group and writes `/etc/sudoers.d/99_nopasswd_wheel` to enable passwordless `sudo` for `wheel`.

## Security note (important)

Autologin plus passwordless `sudo` significantly reduces security. Only apply this configuration to machines you trust (e.g., disposable VMs, local test machines). Do **not** use this configuration on systems that require physical or network security.

## Quick customization

* Change autologin user: edit `TARGET_USER` at top of the script or run the script with `sudo` from the desired user.
* Boot to graphical target instead:

  ```bash
  systemctl set-default graphical.target
  ```

  Or enable and configure a display manager (GDM/SDDM/LightDM) instead of the getty override.
* NVIDIA DKMS or other variants: replace `nvidia` with `nvidia-dkms` in the GPU branch and ensure headers/dkms are present.
