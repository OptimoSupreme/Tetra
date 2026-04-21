# Tetra

![Weekly Build](https://github.com/OptimoSupreme/Tetra/actions/workflows/build.yml/badge.svg)

This repository contains the configuration and Containerfiles for building Tetra, an atomic Fedora based Linux distribution using `bootc`.

## Bootc tools

Installed Tetra systems track `ghcr.io/optimosupreme/tetra:workstation` and pull updates on a weekly timer (`bootc-fetch-apply-updates.timer`, enabled by default).

```bash
bootc status                 # see what's installed and what's staged
sudo bootc upgrade           # force an update now
sudo systemctl reboot        # apply it
sudo bootc rollback          # revert to the previous deployment
```

To verify the running image's signature:

```bash
cosign verify \
  --certificate-identity-regexp 'https://github.com/OptimoSupreme/Tetra/.*' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  ghcr.io/optimosupreme/tetra:workstation
```

## Building an installer ISO

Build an anaconda installer ISO from the published GHCR image:

```bash
sudo podman run \
  --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v ./blueprint.toml:/config.toml:ro \
  -v ./output:/output \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type anaconda-iso \
  --rootfs btrfs \
  --use-librepo=True \
  ghcr.io/optimosupreme/tetra:workstation
sudo chown -R $USER:$USER ./output
```

The finished ISO lands at `output/bootiso/install.iso`.

## Development and testing

These recipes are for iterating on Tetra locally against uncommitted changes to the Containerfile. For a normal install, use the GHCR-based ISO build above. They require the git repo to be cloned locally, and the commands run from its root directory.

### Building the OS container locally

```bash
sudo podman build -t localhost/tetra:workstation .
```

### Building an installer ISO from the local container

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
sudo chown -R $USER:$USER ./output
```

### Building a qcow2 image for VM testing

Building a `.qcow2` disk image lets you boot Tetra directly in a VM without running through the Anaconda installer — useful for quick iteration.

```bash
sudo podman run \
  --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v ./output:/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type qcow2 \
  --rootfs btrfs \
  --use-librepo=True \
  localhost/tetra:workstation
sudo chown -R $USER:$USER ./output
```

The finished disk will land at `output/qcow2/disk.qcow2`.

Launch the VM:
```bash
qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -smp 4 \
  -m 8192 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -device virtio-vga-gl \
  -display gtk,gl=on \
  -device virtio-net-pci,netdev=n0 \
  -netdev user,id=n0,hostfwd=tcp::2222-:22 \
  -drive file=./output/qcow2/disk.qcow2,if=virtio,cache=writeback
```
