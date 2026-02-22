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

`bootc-image-builder` strictly requires "rootful" execution because it performs low-level filesystem operations (like writing to raw disks or loopback interfaces).

Add this alias to your `~/.bashrc`:

```bash
alias bootc-image-builder='sudo podman run --rm -it --privileged --pull=newer --security-opt label=type:unconfined_t -v "$(pwd)":/output -v /var/lib/containers/storage:/var/lib/containers/storage quay.io/centos-bootc/bootc-image-builder:latest'
```

### 2. Building an Image

Because the builder must run as root, your local container image must exist in **root's** podman storage. If you've been building your images as a regular user, use `sudo podman build` instead:

```bash
sudo podman build -t localhost/workstation:latest -f personal/Containerfile.desktop
```

Then, use the alias to build your preferred output format. We frequently need to specify the root filesystem type (e.g., `--rootfs ext4`, `btrfs`, or `xfs`) depending on the base image:
```bash
bootc-image-builder build --type qcow2 --rootfs ext4 --local localhost/personal-desktop:latest
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
