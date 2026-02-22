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

To build ISOs or other installation media from these images, we use `bootc-image-builder`. 

First, ensure you have it installed:
```bash
sudo dnf install bootc-image-builder
```

Then, you can build an image (e.g., an ISO) by running:
```bash
sudo bootc-image-builder build --type iso docker://<your-registry>/<your-image>:latest
```
*(Replace `<your-registry>/<your-image>:latest` with the actual pushed image URL once we have an automated build/publish pipeline set up. Alternatively, you can build directly from a local container storage if supported).*

## Future Plans
- Set up automated builds.
- Define base packages, users, and systemd services.
- Decide on a project name.
