# Tetra

This repository contains the configuration and Containerfiles for building Tetra, an atomic Fedora based Linux distribution using `bootc` (ostree + containers).

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

### 3. Move & rename the ISO

```bash
sudo chown -R "$USER":"$USER" output
mv output/bootiso/install.iso ~/iso/"tetra-$(date +%Y%m%d)-x86_64.iso"
rm -rf ./output/*
```