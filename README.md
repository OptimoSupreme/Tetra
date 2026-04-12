# Tetra

This repository contains the configuration and Containerfiles for building Tetra, an atomic Fedora based Linux distribution using `bootc` (ostree + containers).

## Building the Container Image

```bash
sudo podman build -t localhost/tetra:workstation .
```

> **Note:** Use `sudo podman build` so the image lands in root's storage, which is required by the ISO build container (see below).

---

## Building Installation Media

We use upstream [bootc-image-builder](https://github.com/osbuild/bootc-image-builder) to turn the local `localhost/tetra:workstation` container into a bootable Anaconda installer ISO. No separate installer container is needed — `bootc-image-builder` bundles Anaconda and embeds your bootc image as the payload.

> **Note:** Upstream is slowly merging `bootc-image-builder` and [image-builder-cli](https://github.com/osbuild/image-builder-cli) into a single tool, but as of today `quay.io/centos-bootc/bootc-image-builder` remains the recommended path for building installer ISOs from a bootc container locally.

### About `blueprint.toml`

[blueprint.toml](blueprint.toml) is still required, and it's what makes the installer **interactive**. By default `anaconda-iso` produces an *unattended* installer that wipes the first disk and installs automatically. The blueprint overrides that with a minimal kickstart:

```toml
[customizations.installer.kickstart]
contents = "graphical"
```

`bootc-image-builder` automatically appends the `ostreecontainer` command that installs Tetra, so the only thing we need to specify is `graphical` — this launches Anaconda in GUI mode so you can pick disks, create the user account, and configure the system interactively.

### 1. Build the OS container

If you haven't already:

```bash
sudo podman build -t localhost/tetra:workstation .
```

### 2. Build the installer ISO

```bash
sudo podman run \
  --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v ./blueprint.toml:/config.toml:ro \
  -v ./output:/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type anaconda-iso \
  --rootfs btrfs \
  --use-librepo=True \
  localhost/tetra:workstation
```

What each flag does:

| Flag | Purpose |
|---|---|
| `--privileged` + `label=type:unconfined_t` | Required for the builder to run `osbuild` stages and loop-mount images |
| `-v .../storage:/var/lib/containers/storage` | Lets the builder see your local `localhost/tetra:workstation` image in root's container storage |
| `-v ./blueprint.toml:/config.toml:ro` | Supplies the graphical-install kickstart |
| `-v ./output:/output` | Where the finished ISO lands on the host |
| `--type anaconda-iso` | Builds an Anaconda installer ISO |
| `--use-librepo=True` | Uses the newer librepo backend (recommended by upstream) |
| `localhost/tetra:workstation` | The bootc image to embed as the install payload |

### 3. Locate and (optionally) rename the ISO

```bash
sudo chown -R "$USER":"$USER" output
mv output/bootiso/install.iso "output/tetra-$(date +%Y%m%d)-x86_64.iso"
ls -lh output/tetra-*.iso
```

### 4. Test the ISO

Boot the ISO in a VM (or write it to a USB stick with `dd` / GNOME Disks) and you should land in the graphical Anaconda installer. Pick your disks, create your user, and install.