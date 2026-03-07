# Tetra

This repository contains the configuration and Containerfiles for building Tetra, an atomic Fedora based Linux distribution using `bootc` (ostree + containers).

## Building the Container Image

The Containerfile uses a build argument (`TAG`) to produce different variants from a single file. The default is `workstation`.

### Available Tags

| Tag | GPU Drivers | Use Case |
|---|---|---|
| `workstation` | Mesa freeworld + Intel media driver | Any AMD or Intel system |
| `workstation-nvidia` | Intel media driver + NVIDIA akmod | NVIDIA systems (requires certs in `assets/nvidia_assets/certs/`) |
| `server` | None | Headless server with Docker installed |
| `my-laptop` | Intel media driver only | Justin's laptop (Intel iGPU) |
| `my-desktop` | Mesa freeworld only | Justin's desktop (AMD RX 6600 XT) |

### Build Commands

```bash
# Build the :workstation variant (default)
sudo podman build -t localhost/tetra:workstation .

# Build the :workstation-nvidia variant
sudo podman build --build-arg TAG=workstation-nvidia -t localhost/tetra:workstation-nvidia .

# Build the :server variant
sudo podman build --build-arg TAG=server -t localhost/tetra:server .
# Build the :my-laptop variant
sudo podman build --build-arg TAG=my-laptop -t localhost/tetra:my-laptop .

# Build the :my-desktop variant
sudo podman build --build-arg TAG=my-desktop -t localhost/tetra:my-desktop .
```

> **Note:** Use `sudo podman build` so the image lands in root's storage, which is required by `bootc-image-builder` (see below).

---

## Building Installation Media

To build ISOs or other installation media from these images, we use the `bootc-image-builder` container in podman.

### 1. Setting up the Builder

`bootc-image-builder` strictly requires "rootful" execution because it performs low-level filesystem operations (like writing to raw disks or loopback interfaces).

Add this alias to your `~/.bashrc`:

```bash
alias bootc-image-builder='sudo podman run --rm -it --privileged --pull=newer --security-opt label=type:unconfined_t -v "$(pwd)":/output -v "$HOME/Downloads":/Downloads -v /var/lib/containers/storage:/var/lib/containers/storage quay.io/centos-bootc/bootc-image-builder:latest'
```

### 2. Building an ISO

Use the alias to build your preferred output format. To trigger the interactive Anaconda Web UI, we pass our custom `config.toml` file.

```bash
# Example using the :workstation image
bootc-image-builder build --type iso --rootfs btrfs --config assets/config.toml --output /Downloads --local localhost/tetra:workstation

# Example using the :workstation-nvidia image
bootc-image-builder build --type iso --rootfs btrfs --config assets/config.toml --output /Downloads --local localhost/tetra:workstation-nvidia

# Example using the :server image
bootc-image-builder build --type iso --rootfs btrfs --config assets/config.toml --output /Downloads --local localhost/tetra:server
```

The output will be placed in your `~/Downloads` directory.

**Available Image Types:**
You can change the `--type` flag to generate various formats:
- `qcow2` - QEMU Copy On Write (Ideal for KVM/libvirt/virt-manager testing)
- `iso` or `anaconda-iso` - Bootable installer ISO (Standard installation media)
- `raw` - Raw disk image
- `ami` - Amazon Machine Image (AWS)
- `vmdk` - VMware virtual disk
- `gce` - Google Compute Engine image

## Future Plans
- Set up automated builds.
- Define base packages, users, and systemd services.
- Decide on a project name.
