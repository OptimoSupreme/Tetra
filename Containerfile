FROM quay.io/fedora/fedora-bootc:44

# Set default hostname
RUN echo "tetra" > /etc/hostname && \
    echo "f+ /etc/hostname 0644 root root - tetra" > /usr/lib/tmpfiles.d/10-set-hostname.conf

# Mask unwanted/broken services in container
RUN systemctl mask systemd-remount-fs.service packagekit.service packagekit-offline-update.service mcelog.service flatpak-add-fedora-repos.service

# Set Timezone
RUN ln -fs /usr/share/zoneinfo/US/Eastern /etc/localtime

# Package installs and removals
RUN dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    dnf install -y \
        @workstation-product-environment \
        breeze-cursor-theme \
        btrfs-assistant \
        cryptsetup \
        fastfetch \
        git \
        gnome-firmware \
        gnome-shell-extension-appindicator \
        gnome-shell-extension-blur-my-shell \
        gnome-shell-extension-caffeine \
        gnome-shell-extension-dash-to-panel \
        langpacks-en \
        qemu-guest-agent \
        spice-vdagent \
        tpm2-tools \
        unzip && \
    dnf remove -y \
        gnome-boxes \
        gnome-characters \
        gnome-clocks \
        gnome-connections \
        gnome-contacts \
        gnome-extensions-app \
        gnome-font-viewer \
        gnome-logs \
        gnome-maps \
        gnome-shell-extension-apps-menu \
        gnome-shell-extension-background-logo \
        gnome-shell-extension-launch-new-instance \
        gnome-shell-extension-places-menu \
        gnome-shell-extension-window-list \
        gnome-software \
        gnome-system-monitor \
        gnome-tour \
        gnome-weather \
        libreoffice* \
        malcontent-control \
        mediawriter \
        snapshot \
        toolbox \
        yelp

# Multimedia codecs
RUN dnf swap -y ffmpeg-free ffmpeg --allowerasing && \
    dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

# GPU drivers (mesa freeworld + intel-media-driver)
RUN dnf install -y mesa-va-drivers-freeworld intel-media-driver

# Fastfetch
COPY assets/fastfetch/config.jsonc /etc/xdg/fastfetch/config.jsonc
COPY assets/fastfetch/logo.txt /etc/xdg/fastfetch/logo.txt
RUN echo '[[ $- == *i* ]] && fastfetch' >> /etc/bashrc

# Housekeeping
RUN dnf autoremove -y && \
    dnf clean all

# Name OS
RUN sed -i \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="Tetra"/' \
    -e 's/^NAME=.*/NAME="Tetra"/' \
    -e '/^ANSI_COLOR=/d' \
    -e '/^LOGO=/d' \
    -e '/^CPE_NAME=/d' \
    -e 's/^DEFAULT_HOSTNAME=.*/DEFAULT_HOSTNAME=tetra/' \
    -e 's|^HOME_URL=.*|HOME_URL=https://github.com/OptimoSupreme/Tetra|' \
    -e '/^DOCUMENTATION_URL=/d' \
    -e '/^SUPPORT_URL=/d' \
    -e '/^BUG_REPORT_URL=/d' \
    -e '/^REDHAT_BUGZILLA_PRODUCT_VERSION=/d' \
    -e '/^REDHAT_BUGZILLA_PRODUCT=/d' \
    -e '/^REDHAT_SUPPORT_PRODUCT_VERSION=/d' \
    -e '/^REDHAT_SUPPORT_PRODUCT=/d' \
    -e '/^SUPPORT_END=/d' \
    /usr/lib/os-release

# Configure Plymouth & rebuild initramfs
COPY assets/trademark.png /usr/share/pixmaps/trademark.png
COPY assets/plymouth/tetra.plymouth /usr/share/plymouth/themes/tetra/tetra.plymouth
COPY assets/trademark.png /usr/share/plymouth/themes/tetra/watermark.png
COPY assets/plymouth/plymouthd.conf /etc/plymouth/plymouthd.conf
RUN cp /usr/share/plymouth/themes/spinner/throbber-*.png \
       /usr/share/plymouth/themes/spinner/entry.png \
       /usr/share/plymouth/themes/spinner/lock.png \
       /usr/share/plymouth/themes/spinner/bullet.png \
       /usr/share/plymouth/themes/spinner/capslock.png \
       /usr/share/plymouth/themes/spinner/keyboard.png \
       /usr/share/plymouth/themes/spinner/keymap-render.png \
       /usr/share/plymouth/themes/tetra/ && \
    plymouth-set-default-theme --list | grep -qx tetra && \
    [ "$(plymouth-set-default-theme)" = "tetra" ]
RUN kver=$(basename /usr/lib/modules/*) && \
    dracut --force --reproducible --no-hostonly --add ostree \
        /usr/lib/modules/"$kver"/initramfs.img "$kver" && \
    lsinitrd /usr/lib/modules/"$kver"/initramfs.img | grep -q 'plymouthd$' && \
    lsinitrd /usr/lib/modules/"$kver"/initramfs.img | grep -q 'plymouth/themes/tetra/tetra.plymouth'

# Configure Gnome
RUN rm -rf /usr/share/backgrounds/* /usr/share/gnome-background-properties/*
COPY assets/wallpaper.png /usr/share/backgrounds/default.png
COPY assets/wallpaper.xml /usr/share/gnome-background-properties/tetra.xml
COPY assets/dconf-profile /etc/dconf/profile/user
COPY assets/dconf-settings /etc/dconf/db/local.d/00-custom
COPY assets/gdm-profile /etc/dconf/profile/gdm
COPY assets/gnome-initial-setup-profile /etc/dconf/profile/gnome-initial-setup
COPY assets/gnome-initial-setup-account /var/lib/AccountsService/users/gnome-initial-setup
COPY assets/gnome-initial-setup-account /var/lib/AccountsService/users/gdm
RUN echo 'LANG="en_US.UTF-8"' > /etc/locale.conf && \
    dconf update && \
    mkdir -p /usr/share/icons/default && \
    echo -e "[Icon Theme]\nInherits=Breeze_Light" > /usr/share/icons/default/index.theme && \
    cp /usr/share/pixmaps/trademark.png /usr/share/pixmaps/fedora_logo_med.png && \
    cp /usr/share/pixmaps/trademark.png /usr/share/pixmaps/fedora_whitelogo_med.png && \
    find /usr/share/icons -name "*fedora-logo-icon*" -exec cp /usr/share/pixmaps/trademark.png {} \;

# Polkit rules
COPY assets/20-flatpak-polkit.rules /etc/polkit-1/rules.d/20-flatpak-polkit.rules

# Add pam_fprintd to the PAM stack so GDM offers fingerprint auth on machines with a reader
RUN authselect enable-feature with-fingerprint

# Firefox configuration
COPY assets/firefox/autoconfig.js /usr/lib64/firefox/defaults/pref/autoconfig.js
COPY assets/firefox/mozilla.cfg /usr/lib64/firefox/mozilla.cfg
COPY assets/firefox/policies.json /etc/firefox/policies/policies.json

# Btrfs Snapshots
COPY assets/btrfs-assistant.conf /etc/btrfs-assistant.conf
COPY --chmod=0640 assets/snapper-home-config /etc/snapper/configs/home
COPY assets/snapper-sysconfig /etc/sysconfig/snapper
COPY assets/snapper-home-setup.service /usr/lib/systemd/system/snapper-home-setup.service
RUN systemctl enable snapper-home-setup.service snapper-timeline.timer snapper-cleanup.timer

# TPM Decryption Helper Script
COPY assets/enable-tpm-decryption /usr/local/bin/enable-tpm-decryption
RUN chmod +x /usr/local/bin/enable-tpm-decryption

# Setup Service
COPY assets/tetra-setup.service /usr/lib/systemd/system/tetra-setup.service
RUN systemctl enable tetra-setup.service

# Configure updates and notifications
COPY assets/bootc-update-service-override.conf /usr/lib/systemd/system/bootc-fetch-apply-updates.service.d/10-tetra.conf
COPY assets/rpm-ostree-countme-override.conf /usr/lib/systemd/system/rpm-ostree-countme.service.d/10-tetra.conf
COPY assets/bootc-update-timer-override.conf /usr/lib/systemd/system/bootc-fetch-apply-updates.timer.d/10-tetra.conf
COPY --chmod=0755 assets/tetra-update-notify /usr/libexec/tetra-update-notify
COPY assets/tetra-update-notify.service /usr/lib/systemd/user/tetra-update-notify.service
COPY assets/tetra-update-notify.timer /usr/lib/systemd/user/tetra-update-notify.timer
RUN systemctl --global enable tetra-update-notify.timer
RUN systemctl enable bootc-fetch-apply-updates.timer

COPY assets/tetra-flatpak-update.service /usr/lib/systemd/system/tetra-flatpak-update.service
COPY assets/tetra-flatpak-update.timer /usr/lib/systemd/system/tetra-flatpak-update.timer
RUN systemctl enable tetra-flatpak-update.timer

# Image Metadata Labels
LABEL containers.bootc=1
LABEL org.opencontainers.image.source="https://github.com/OptimoSupreme/Tetra"
LABEL org.opencontainers.image.description="Tetra — Fedora bootc workstation"
LABEL org.opencontainers.image.licenses="MIT"