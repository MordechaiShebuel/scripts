# 1. Build (use all CPU cores)
# Debian
make -j$(nproc) deb-pkg  # Creates .deb packages (cleanest for Ubuntu/Debian)
# OR for non-deb systems:
# make -j$(nproc)

# Void
# make -j$(nproc)

sudo make modules_install install

# 2. Install from .deb
cd ..
sudo dpkg -i linux-image-*.deb linux-headers-*.deb

# 3. OR install traditional way
cd linux
sudo make modules_install install
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 4. Reboot and verify
sudo reboot
uname -r  # Should show your new kernel
grep CONFIG_DRM_HDCP /boot/config-$(uname -r)  # Should output: CONFIG_DRM_HDCP=y
