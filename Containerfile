FROM quay.io/fedora/fedora-bootc:44

# Build variant: "workstation" (default), "workstation-nvidia", "server", "my-laptop", "my-desktop"
ARG TAG=workstation

# Name OS in GRUB and Fastfetch and set default hostname
RUN sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Tetra"/; s/^NAME=.*/NAME="Tetra"/' /usr/lib/os-release
RUN echo "tetra" > /etc/hostname && \
    echo "f+ /etc/hostname 0644 root root - tetra" > /usr/lib/tmpfiles.d/10-set-hostname.conf

# Disable systemd-remount-fs.service
RUN systemctl mask systemd-remount-fs.service packagekit.service packagekit-offline-update.service

# Set Timezone
RUN ln -fs /usr/share/zoneinfo/US/Eastern /etc/localtime

# Core packages for all tags
RUN dnf install -y git dialog unzip fastfetch tpm2-tools cryptsetup

# Server setup (only when TAG=server)
RUN if [ "$TAG" = "server" ]; then \
    dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo && \
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    systemctl enable docker && \
    dnf remove -y plymouth; \
    fi

# Workstation packages (skip on server)
RUN if [ "$TAG" != "server" ]; then \
    dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    dnf install -y \
        @workstation-product-environment \
        breeze-cursor-theme \
        btrfs-assistant && \
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
        malcontent-control; \
    fi

# Multimedia codecs (common to all workstation tags)
RUN if [ "$TAG" != "server" ]; then \
    dnf swap -y ffmpeg-free ffmpeg --allowerasing && \
    dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin; \
    fi

# GPU drivers (tag-specific)
#   workstation:        mesa freeworld (AMD+Intel) + intel-media-driver
#   workstation-nvidia: intel-media-driver only (NVIDIA handled below)
#   my-laptop:      intel-media-driver only
#   my-desktop:     mesa freeworld (AMD) only
RUN if [ "$TAG" = "workstation" ]; then \
    dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld && \
    dnf install -y intel-media-driver; \
    elif [ "$TAG" = "workstation-nvidia" ] || [ "$TAG" = "my-laptop" ]; then \
    dnf install -y intel-media-driver; \
    elif [ "$TAG" = "my-desktop" ]; then \
    dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld; \
    fi

# Nvidia (only when TAG=workstation-nvidia)
RUN if [ "$TAG" = "workstation-nvidia" ]; then \
    dnf install -y kernel-devel akmods mokutil openssl; \
    fi
COPY assets/nvidia_assets/certs /tmp/certs
RUN if [ "$TAG" = "workstation-nvidia" ]; then \
    if [ -f "/tmp/certs/kmodcert.priv" ] && [ -f "/tmp/certs/kmodcert.der" ]; then \
        mkdir -p /etc/pki/akmods/certs && \
        cp /tmp/certs/kmodcert.priv /etc/pki/akmods/certs/private_key.priv && \
        cp /tmp/certs/kmodcert.der /etc/pki/akmods/certs/public_key.der && \
        dnf install -y akmod-nvidia && \
        akmods --force --kernels $(rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}') && \
        rm -f /etc/pki/akmods/certs/private_key.priv; \
    else \
        echo "Missing kmodcert.priv or kmodcert.der in assets/nvidia_assets/certs" >&2; \
        exit 1; \
    fi; \
    fi && \
    rm -rf /tmp/certs

# Terminal
RUN if [ "$TAG" != "server" ]; then \
    dnf remove ptyxis -y && \
    dnf copr enable -y scottames/ghostty && \
    dnf install -y ghostty ImageMagick; \
    fi
COPY assets/ghostty/config /etc/skel/.config/ghostty/config
RUN git clone https://github.com/OptimoSupreme/fastfetch_config /etc/skel/.config/fastfetch && \
    echo 'if [[ $- == *i* ]] && [[ -z "$FASTFETCH_HAS_RUN" ]]; then FASTFETCH_HAS_RUN=1; fastfetch; fi' >> /etc/bashrc

# Fonts
RUN if [ "$TAG" != "server" ]; then \
    curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/UbuntuSans.zip && \
    unzip UbuntuSans.zip -d /usr/share/fonts/ubuntu-sans && \
    rm UbuntuSans.zip; \
    fi

# Housekeeping
RUN dnf autoremove -y && \
    dnf clean all

# Configure Plymouth
COPY assets/trademark.png /usr/share/pixmaps/trademark.png
RUN if [ "$TAG" != "server" ] && [ -d /usr/share/plymouth/themes/spinner ]; then \
    rm -f /usr/share/plymouth/themes/spinner/watermark.png && \
    for i in $(seq -w 1 30); do \
    cp /usr/share/pixmaps/trademark.png /usr/share/plymouth/themes/spinner/throbber-00$i.png || true; \
    done; \
    fi

# Configure Gnome
RUN if [ "$TAG" != "server" ]; then \
    rm -rf /usr/share/backgrounds/*; \
    fi
COPY assets/wallpaper.png /usr/share/backgrounds/default.png
COPY assets/dconf-profile /etc/dconf/profile/user
COPY assets/dconf-settings /etc/dconf/db/local.d/00-custom
COPY assets/gdm-profile /etc/dconf/profile/gdm
COPY assets/gnome-initial-setup-profile /etc/dconf/profile/gnome-initial-setup
COPY assets/gnome-initial-setup-account /var/lib/AccountsService/users/gnome-initial-setup
COPY assets/gnome-initial-setup-account /var/lib/AccountsService/users/gdm
RUN if [ "$TAG" != "server" ]; then \
    echo 'LANG="en_US.UTF-8"' > /etc/locale.conf && \
    dconf update && \
    mkdir -p /usr/share/icons/default && \
    echo -e "[Icon Theme]\nInherits=Breeze_Light" > /usr/share/icons/default/index.theme && \
    cp /usr/share/pixmaps/trademark.png /usr/share/pixmaps/fedora_logo_med.png && \
    cp /usr/share/pixmaps/trademark.png /usr/share/pixmaps/fedora_whitelogo_med.png && \
    find /usr/share/icons -name "*fedora-logo-icon*" -exec cp /usr/share/pixmaps/trademark.png {} \;; \
    fi

# Polkit rules
COPY assets/20-gnome-software-polkit.rules /etc/polkit-1/rules.d/20-gnome-software-polkit.rules

# TPM Decryption Helper Script
COPY assets/enable-tpm-decryption /usr/local/bin/enable-tpm-decryption
RUN chmod +x /usr/local/bin/enable-tpm-decryption