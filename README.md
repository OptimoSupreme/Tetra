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

> **Note:** Use `sudo podman build` so the image lands in root's storage, which is required by `image-builder` (see below).

---

## Building Installation Media

We use `image-builder` ([osbuild/image-builder-cli](https://github.com/osbuild/image-builder-cli)) to generate installable ISOs with the Anaconda WebUI. The process uses two containers: an **installer container** (includes Anaconda with the WebUI) and your **OS container** (Tetra itself) as the payload.

> **Note:** Currently targeting Fedora 44 (beta). The base image tags will be updated to `:latest` once Fedora 44 goes stable.

### 1. Build the OS container

See the build commands above for all available variants.

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
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  ghcr.io/osbuild/image-builder-cli:latest build'
```

### 4. Build the ISO

```bash
mkdir -p output

image-builder \
  --bootc-ref localhost/tetra-installer:latest \
  --bootc-installer-payload-ref localhost/tetra:workstation \
  --bootc-default-fs btrfs \
  bootc-installer
```

### 5. Rename and locate your ISO

```bash
mv output/bootiso/*.iso "output/tetra-$(date +%Y%m%d)-x86_64.iso"
ls -lh output/tetra-*.iso
```
