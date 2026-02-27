FROM quay.io/fedora/fedora-bootc:latest

# Name OS in GRUB and Fastfetch and set default hostname
RUN sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Tetra"/; s/^NAME=.*/NAME="Tetra"/' /usr/lib/os-release
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
    btrfs-assistant \
    dialog \
    unzip

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
    yelp \
    malcontent-control

RUN dnf swap -y ffmpeg-free ffmpeg --allowerasing && \
    dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin && \
    dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld && \
    dnf install -y intel-media-driver

# Terminal
RUN dnf remove ptyxis -y && \
    dnf copr enable -y scottames/ghostty && \
    dnf install -y fastfetch ghostty ImageMagick
COPY assets/ghostty/config /etc/skel/.config/ghostty/config
RUN git clone https://github.com/OptimoSupreme/fastfetch_config /etc/skel/.config/fastfetch && \
    echo 'if [[ $- == *i* ]] && [[ -z "$FASTFETCH_HAS_RUN" ]]; then FASTFETCH_HAS_RUN=1; fastfetch; fi' >> /etc/bashrc

# Fonts
RUN curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/UbuntuSans.zip && \
    unzip UbuntuSans.zip -d /usr/share/fonts/ubuntu-sans && \
    rm UbuntuSans.zip

# Housekeeping
RUN dnf autoremove -y && \
    dnf clean all

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
COPY assets/gdm-settings /etc/dconf/db/gdm.d/01-custom-gdm
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

# Profile Script
COPY assets/firstboot-setup.sh /usr/local/bin/firstboot-setup.sh
COPY assets/generic-workstation.sh /usr/local/bin/generic-workstation.sh
COPY assets/firstboot-tui.desktop /etc/xdg/autostart/firstboot-tui.desktop
RUN chmod +x /usr/local/bin/firstboot-setup.sh /usr/local/bin/generic-workstation.sh