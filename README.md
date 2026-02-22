# Custom Fedora bootc Images

This repository contains the configuration and Containerfiles for building custom, bootable, atomic Fedora Linux images using `bootc` (ostree + containers).

## Available Images

Our goal is to build and maintain three distinct images:

### 1. Workstation Image (`workstation/Containerfile`)
- **Description:** A customized workstation image tailored specifically for my personal use, development environment, and my own computers.
- **Features:** *(To be defined)*
- **NVIDIA Variant:** `workstation/Containerfile.nvidia`

### 2. Server Image (`server/Containerfile`)
- **Description:** An optimized, headless image based on **Fedora CoreOS**, designed for running containerized workloads on the home server.
- **Features:** *(To be defined)*

### 3. Generic Desktop Image (`generic/Containerfile`)
- **Description:** A polished, user-friendly, and stable image aimed at non-technical users. It provides an out-of-the-box experience suitable for anyone's personal computer.
- **Features:** *(To be defined)*
- **NVIDIA Variant:** `generic/Containerfile.nvidia`

*(Note: The descriptions and feature lists will be updated as we build out the respective Containerfiles.)*

## Building Installation Media

To build ISOs or other installation media from these images, we use the `bootc-image-builder` container in podman.

### 1. Setting up the Builder

Podman is required because it can easily access your local container storage when building images locally. To make running the builder easy, add this alias to your `~/.bashrc`:

```bash
alias bootc-image-builder='sudo podman run --rm -it --privileged --pull=newer --security-opt label=type:unconfined_t -v "$(pwd)":/output -v /var/lib/containers/storage:/var/lib/containers/storage quay.io/centos-bootc/bootc-image-builder:latest'
```

### 2. Building an Image

Before building the disk image, you first need to build your Containerfile into a local image (if you haven't published it to a registry yet):
```bash
podman build -t localhost/workstation:latest -f workstation/Containerfile .
```

Then, use the alias to build your preferred output format. The `--local` flag tells the builder to pull the image from your local Podman storage:
```bash
bootc-image-builder build --type qcow2 --local localhost/workstation:latest
```

The output will be placed in an `output/` directory in your current path.

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
