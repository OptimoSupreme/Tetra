# Tetra

![Weekly Build](https://github.com/OptimoSupreme/Tetra/actions/workflows/build.yml/badge.svg)

This repository contains the configuration and Containerfiles for building Tetra, an atomic Fedora based Linux distribution using `bootc` (ostree + containers).

## Installing Tetra

Download the latest installer ISO from the [Releases page](https://github.com/OptimoSupreme/Tetra/releases/latest). Each release ships:

- `tetra-YYYYMMDD.iso` — the Anaconda installer
- `tetra-YYYYMMDD.iso.sha256` — checksum
- `tetra-YYYYMMDD.iso.cosign.bundle` — Sigstore signature bundle

Verify before flashing:

```bash
sha256sum -c tetra-YYYYMMDD.iso.sha256
cosign verify-blob \
  --bundle tetra-YYYYMMDD.iso.cosign.bundle \
  --certificate-identity-regexp 'https://github.com/OptimoSupreme/Tetra/.*' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  tetra-YYYYMMDD.iso
```

Flash to a USB stick (e.g. `sudo dd if=tetra-YYYYMMDD.iso of=/dev/sdX bs=4M status=progress oflag=sync`) and boot.

## Automatic updates

Installed Tetra systems track `ghcr.io/optimosupreme/tetra:workstation` and pull updates on a weekly timer (`bootc-fetch-apply-updates.timer`, enabled by default).

```bash
bootc status                 # see what's installed and what's staged
sudo bootc upgrade           # force an update now
sudo systemctl reboot        # apply it
sudo bootc rollback          # revert to the previous deployment
```

To pin to a specific dated build instead of rolling:

```bash
sudo bootc switch ghcr.io/optimosupreme/tetra:workstation-20260420
```

To verify the running image's signature:

```bash
cosign verify \
  --certificate-identity-regexp 'https://github.com/OptimoSupreme/Tetra/.*' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  ghcr.io/optimosupreme/tetra:workstation
```

## Migrating a locally-installed Tetra to GHCR updates

If your machine was installed from a locally-built ISO (pre-CI), point it at the published image once:

```bash
sudo bootc switch ghcr.io/optimosupreme/tetra:workstation
sudo systemctl enable --now bootc-fetch-apply-updates.timer
```

## Building the OS container

```bash
sudo podman build -t localhost/tetra:workstation .
```

## Building an installer ISO

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

## Building a qcow2 image for VM testing

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

The finished disk will land at `output/qcow2/disk.qcow2`. Because bootc-image-builder ran under `sudo`, the output is owned by root — hand it back to your user before launching QEMU unprivileged:

```bash
sudo chown -R "$USER:$USER" ./output
```

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