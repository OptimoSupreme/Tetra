FROM quay.io/fedora/fedora-bootc:43

# Set default hostname
RUN echo "tetra" > /etc/hostname && \
    echo "f+ /etc/hostname 0644 root root - tetra" > /usr/lib/tmpfiles.d/10-set-hostname.conf

# Mask unnecessary/broken services in container
RUN systemctl mask systemd-remount-fs.service packagekit.service packagekit-offline-update.service mcelog.service

# Set Timezone
RUN ln -fs /usr/share/zoneinfo/US/Eastern /etc/localtime

# Core Packages
RUN dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    dnf install -y \
        @workstation-product-environment \
        git \
        unzip \
        fastfetch \
        tpm2-tools \
        cryptsetup \
        breeze-cursor-theme \
        btrfs-assistant \
        langpacks-en && \
    dnf remove -y \
        gnome-contacts \
        gnome-weather \
        gnome-clocks \
        mediawriter \
        gnome-maps \
        libreoffice* \
        gnome-boxes \
        gnome-connections \
        snapshot \
        gnome-characters \
        gnome-font-viewer \
        gnome-logs \
        gnome-tour \
        yelp \
        malcontent-control

# Multimedia codecs
RUN dnf swap -y ffmpeg-free ffmpeg --allowerasing && \
    dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

# GPU drivers (mesa freeworld + intel-media-driver)
RUN dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld && \
    dnf install -y intel-media-driver

# Fastfetch
RUN git clone https://github.com/OptimoSupreme/fastfetch_config /etc/skel/.config/fastfetch && \
    echo 'fastfetch' >> /etc/bashrc

# Housekeeping
RUN dnf autoremove -y && \
    dnf clean all

# Name OS
RUN sed -i \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="Tetra"/' \
    -e 's/^NAME=.*/NAME="Tetra"/' \
    -e 's/^ID=.*/ID=tetra/' \
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

# Btrfs Snapshots
COPY assets/btrfs-assistant.conf /etc/btrfs-assistant.conf
COPY assets/snapper-home-config /etc/snapper/configs/home
COPY assets/snapper-sysconfig /etc/sysconfig/snapper
RUN systemctl enable snapper-timeline.timer snapper-cleanup.timer

# TPM Decryption Helper Script
COPY assets/enable-tpm-decryption /usr/local/bin/enable-tpm-decryption
RUN chmod +x /usr/local/bin/enable-tpm-decryption