FROM quay.io/fedora/fedora-bootc:44

# Set default hostname
RUN echo "tetra" > /etc/hostname && \
    echo "f+ /etc/hostname 0644 root root - tetra" > /usr/lib/tmpfiles.d/10-set-hostname.conf

# Mask unnecessary/broken services in container
RUN systemctl mask systemd-remount-fs.service packagekit.service packagekit-offline-update.service mcelog.service

# Set Timezone
RUN ln -fs /usr/share/zoneinfo/US/Eastern /etc/localtime

# Package installs and removals
# NOTE: pinned to download1 (master) instead of mirrors.rpmfusion.org because
# us.mirrors.cicku.me is serving stale 44-0.2 release packages with inverted
# enabled= flags (rawhide on, stable off). Revert to mirrors.rpmfusion.org once
# resolved upstream. See: https://bugzilla.rpmfusion.org/show_bug.cgi?id=7450
RUN dnf install -y \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    dnf install -y \
        @workstation-product-environment \
        breeze-cursor-theme \
        btrfs-assistant \
        cryptsetup \
        fastfetch \
        git \
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
RUN git clone https://github.com/OptimoSupreme/fastfetch_config /etc/skel/.config/fastfetch && \
    echo '[[ $- == *i* ]] && fastfetch' >> /etc/bashrc

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

# Configure Plymouth
COPY assets/trademark.png /usr/share/pixmaps/trademark.png
RUN if [ -d /usr/share/plymouth/themes/spinner ]; then \
    rm -f /usr/share/plymouth/themes/spinner/watermark.png && \
    for i in $(seq -w 1 30); do \
    cp /usr/share/pixmaps/trademark.png /usr/share/plymouth/themes/spinner/throbber-00$i.png || true; \
    done; \
    fi

# Configure Gnome
RUN rm -rf /usr/share/backgrounds/*
COPY assets/wallpaper.png /usr/share/backgrounds/default.png
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
COPY assets/20-gnome-software-polkit.rules /etc/polkit-1/rules.d/20-gnome-software-polkit.rules

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

# First-boot flatpak installation
COPY assets/tetra-flatpak-setup.service /usr/lib/systemd/system/tetra-flatpak-setup.service
RUN systemctl enable tetra-flatpak-setup.service

# Configure updates
COPY assets/bootc-update-service-override.conf /usr/lib/systemd/system/bootc-fetch-apply-updates.service.d/10-tetra.conf
COPY assets/bootc-update-timer-override.conf /usr/lib/systemd/system/bootc-fetch-apply-updates.timer.d/10-tetra.conf
COPY --chmod=0755 assets/tetra-update-notify /usr/libexec/tetra-update-notify
RUN systemctl enable bootc-fetch-apply-updates.timer

LABEL containers.bootc=1
LABEL org.opencontainers.image.source="https://github.com/OptimoSupreme/Tetra"
LABEL org.opencontainers.image.description="Tetra — Fedora bootc workstation"
LABEL org.opencontainers.image.licenses="MIT"