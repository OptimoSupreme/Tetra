FROM quay.io/fedora/fedora-bootc:latest

# Name OS in GRUB and Fastfetch and set default hostname
RUN sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Tetra"/; s/^NAME=.*/NAME="Tetra"/; s/^LOGO=.*/LOGO="trademark"/' /usr/lib/os-release
RUN echo "tetra" > /etc/hostname && \
    echo "f+ /etc/hostname 0644 root root - tetra" > /usr/lib/tmpfiles.d/10-set-hostname.conf

# Disable systemd-remount-fs.service
RUN systemctl mask systemd-remount-fs.service packagekit.service packagekit-offline-update.service

# Set Timezone
RUN ln -fs /usr/share/zoneinfo/US/Eastern /etc/localtime

# Install repos and non-configured packages, remove unneeded packages
RUN dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

RUN dnf install -y \
    @workstation-product-environment \
    git \
    breeze-cursor-theme \
    btrfs-assistant

RUN dnf remove -y \
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
    yelp

RUN dnf swap -y ffmpeg-free ffmpeg --allowerasing && \
    dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin && \
    dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld && \
    dnf install -y intel-media-driver

# Terminal
RUN dnf remove ptyxis -y && \
    dnf copr enable -y scottames/ghostty && \
    dnf install -y fastfetch ghostty ImageMagick
COPY assets/ghostty/config /etc/xdg/ghostty/config
RUN git clone https://github.com/OptimoSupreme/fastfetch_config /etc/skel/.config/fastfetch && \
    echo 'if [[ $- == *i* ]] && [[ -z "$FASTFETCH_HAS_RUN" ]]; then FASTFETCH_HAS_RUN=1; fastfetch; fi' >> /etc/bashrc

# Housekeeping
RUN dnf autoremove -y && \
    dnf clean all

# Configure Plymouth
COPY assets/trademark.png /usr/share/pixmaps/trademark.png
RUN cp /usr/share/pixmaps/trademark.png /usr/share/fedora-logos/fedora_lightbackground.svg && \
    cp /usr/share/pixmaps/trademark.png /usr/share/fedora-logos/fedora_darkbackground.svg && \
    cp /usr/share/pixmaps/trademark.png /usr/share/fedora-logos/fedora_logo.svg && \
    cp /usr/share/pixmaps/trademark.png /usr/share/fedora-logos/fedora_logo_darkbackground.svg && \
    cp /usr/share/pixmaps/trademark.png /usr/share/pixmaps/fedora-gdm-logo.png && \
    cp /usr/share/pixmaps/trademark.png /usr/share/pixmaps/system-logo-white.png && \
    cp /usr/share/pixmaps/trademark.png /usr/share/pixmaps/fedora-logo-icon.png && \
    if [ -d /usr/share/plymouth/themes/spinner ]; then \
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
RUN dconf update && \
    mkdir -p /usr/share/icons/default && \
    echo -e "[Icon Theme]\nInherits=Breeze_Light" > /usr/share/icons/default/index.theme

# Profile Script