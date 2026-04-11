# Tetra

This repository contains the configuration and Containerfiles for building Tetra, an atomic Fedora based Linux distribution using `bootc` (ostree + containers).

## Building the Container Image

```bash
sudo podman build -t localhost/tetra:workstation .
```

> **Note:** Use `sudo podman build` so the image lands in root's storage, which is required by the ISO build container (see below).

---

## Building Installation Media

