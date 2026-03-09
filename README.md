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

Due to current upstream limitations with `bootc-image-builder` missing the modern Anaconda WebUI and Live environment support, we are temporarily using `titanoboa` to generate our installation media.

Please see the [BUILDING_ISO_TEMP.md](BUILDING_ISO_TEMP.md) guide for instructions on generating an installable Live ISO from your locally built container image. 

> **Note:** We plan to revert to the upstream `bootc-image-builder` tooling once these features are officially supported (expected in less than 6 months).
