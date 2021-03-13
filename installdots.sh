#!/bin/bash

# Add option for different user name
[ -z "$1" ] && name="bilge" || (echo "User Name?: " ; read -r name)

# Permissions for installation
chown "$name":wheel "/home/$name"
sed -i "/$name/d" /etc/sudoers
echo -e "%wheel ALL=(ALL) NOPASSWD: ALL # Edited by $name" >> /etc/sudoers

# Pacman conf adjustments
sed -i "s/#Color/Color/" /etc/pacman.conf
sed -i "s/#TotalDownload/TotalDownload/" /etc/pacman.conf
sed -i "s/#VerbosePkgLists/ILoveCandy/" /etc/pacman.conf
grep -q "# Edited by $name" /etc/pacman.conf || printf "\n# Edited by %s\n%s\n%s" "$name" "[multilib]" "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

# Refresh keyrings
pacman --noconfirm -Sy archlinux-keyring

aur_helper="yay"
# AUR helper install
pacman --noconfirm --needed -S git curl base-devel
pacman -Qq | grep -q "$aur_helper" ||
(sudo -u "$name" git clone "https://aur.archlinux.org/$aur_helper.git" &&
cd $aur_helper &&
sudo -u "$name" makepkg --noconfirm -si)

# Install packages (non-AUR)
pac=$(curl -s "https://raw.githubusercontent.com/bilgehankaya/dotins/github/pacman.txt")
pacman --noconfirm --needed -S $(echo $pac)

# Install AUR packages
aurall=$(pacman -Qqm)
curl -s "https://raw.githubusercontent.com/bilgehankaya/dotins/github/aur.txt" | while read line;
do
    echo "$aurall" | grep -q "^$line$" && echo "$line is already installed!" && continue
    sudo -u "$name" "$aur_helper" -S --noconfirm "$line"
done

# Make install suckless builds (dwm, dwmblock, dmenu, st)
for dir in $(ls -d /home/$name/.local/src/*)
do
    make -C $dir && make -C $dir install
done

# System beep off
rmmod pcspkr
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

# Zsh is the default shell now
chsh -s /bin/zsh "$name"
sudo -u "$name" mkdir -p "/home/$name/.cache/zsh/"

# Start/restart PulseAudio.
killall pulseaudio ; sudo -u "$name" pulseaudio --start

# Journal limit
[ ! -d /etc/systemd/journald.conf.d ] && mkdir /etc/systemd/journald.conf.d
printf "%s\n%s" "[Journal]" "SystemMaxUse=50M" > /etc/systemd/journald.conf.d/00-journal-size.conf

# Tap to click
[ ! -f /etc/X11/xorg.conf.d/40-libinput.conf ] && printf 'Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
	# Enable left mouse button by tapping
	Option "Tapping" "on"
EndSection' > /etc/X11/xorg.conf.d/40-libinput.conf

# Declutter home
echo "export ZDOTDIR=\"/home/$name/.config/zsh\"" > /etc/zsh/zshenv

# Unblock wifi, bluetooth
rfkill unblock all

# Start services
systemctl enable bluetooth.service
systemctl start bluetooth.service
systemctl enable cronie.service
systemctl start cronie.service

# Remove libxft amnd install libxft-bgra-git
pacman -Qq | grep -q "^libxft$" && pacman --noconfirm -Rdd libxft
pacman -Qqm | grep -q "^libxft-bgra-git$" || sudo -u "$name" "$aur_helper" -S --noconfirm libxft-bgra-git

# Change permissions
sed -i "/$name/d" /etc/sudoers
echo -e "%wheel ALL=(ALL) ALL # Edited by $name\n%wheel ALL=(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/packer -Syu,/usr/bin/packer -Syyu,/usr/bin/systemctl restart NetworkManager,/usr/bin/rc-service NetworkManager restart,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/$aur_helper,/usr/bin/pacman -Syyuw --noconfirm # Edited by $name" >> /etc/sudoers

# Last message
echo "Installation is completed for user $name!"
