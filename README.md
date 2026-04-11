# Tetra

This repository contains the configuration and Containerfiles for building Tetra, an atomic Fedora based Linux distribution using `bootc` (ostree + containers).

## Building the Container Image

```bash
sudo podman build -t localhost/tetra:workstation .
```

> **Note:** Use `sudo podman build` so the image lands in root's storage, which is required by the ISO build container (see below).

---

## Building Installation Media

We use [ghcr.io/ublue-os/devcontainer:titanoboa](https://github.com/ublue-os/devcontainer) to generate installable ISOs. The process uses two containers: an **installer container** (includes Anaconda) and your **OS container** (Tetra itself) as the payload.

> **Note:** Currently targeting Fedora 43.

### 1. Build the OS container

```bash
sudo podman build -t localhost/tetra:workstation .
```

### 2. Build the installer container

```bash
sudo podman build -t localhost/tetra-installer:latest -f Containerfile.installer .
```

### 3. Set up the `image-builder` alias

```bash
alias image-builder='sudo podman run \
  --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v $(pwd)/output:/output \
  -v $(pwd)/blueprint.toml:/blueprint.toml:ro \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  ghcr.io/ublue-os/devcontainer:titanoboa \
  image-builder build'
```

### 4. Build the ISO

```bash
mkdir -p output

image-builder \
  --bootc-ref localhost/tetra-installer:latest \
  --bootc-installer-payload-ref localhost/tetra:workstation \
  --bootc-default-fs btrfs \
  --blueprint /blueprint.toml \
  bootc-installer
```

### 5. Rename and locate your ISO

```bash
mv output/*/*.iso "output/tetra-$(date +%Y%m%d)-x86_64.iso"
ls -lh output/tetra-*.iso
```
