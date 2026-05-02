# Tetra

![Weekly Build](https://github.com/OptimoSupreme/Tetra/actions/workflows/build.yml/badge.svg)

This repository contains the configuration and Containerfiles for building Tetra, an atomic Fedora based Linux distribution using `bootc`.

## Bootc tools

Installed Tetra systems track `ghcr.io/optimosupreme/tetra:workstation` and pull updates on a weekly timer (`bootc-fetch-apply-updates.timer`, enabled by default).

```bash
sudo bootc status            # see what's installed and what's staged
sudo bootc upgrade           # force an update now
sudo systemctl reboot        # apply it
sudo bootc rollback          # revert to the previous deployment
```

## Building an installer ISO

Build an anaconda installer ISO from the published GHCR image. The following commands require the git repo to be cloned locally, and to be run run from its root directory.

```bash
sudo podman pull ghcr.io/optimosupreme/tetra:workstation
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
  ghcr.io/optimosupreme/tetra:workstation
sudo chown -R $USER:$USER ./output
mv ./output/bootiso/install.iso ./output/bootiso/tetra-workstation-$(date -u +%Y%m%d).iso
```

The finished ISO lands at `output/bootiso/tetra-workstation-YYYYMMDD.iso`.

## Development and testing

These recipes are for iterating on Tetra locally against uncommitted changes to the Containerfile. For a normal install, use the GHCR-based ISO build above. The following commands require the git repo to be cloned locally, and to be run run from its root directory.

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
mv ./output/bootiso/install.iso ./output/bootiso/tetra-workstation-$(date -u +%Y%m%d).iso
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

Launch the VM via libvirt's user session (no root, no SELinux issues, full
SPICE clipboard support). Requires `virt-manager` and `libvirt-daemon`
installed on the host:

```bash
virt-install --connect qemu:///session \
  --name tetra \
  --memory 8192 --vcpus 6 --cpu host-passthrough \
  --boot uefi \
  --disk path="$PWD/output/qcow2/disk.qcow2",bus=virtio \
  --network user,model=virtio \
  --graphics spice,gl=on,listen=none \
  --video virtio \
  --channel spicevmc \
  --osinfo fedora-unknown \
  --import --noautoconsole
```

Then open **virt-manager**. The first time only, add the user-session
connection: **File → Add Connection → QEMU/KVM User session → Connect**.
Double-click `tetra` under that connection to view the VM with clipboard
sharing enabled.

To rebuild and re-import: in virt-manager, right-click `tetra` → **Delete**
(leave **Delete associated storage files** unchecked so the qcow2 path stays
free for the new build). Then re-run the build and `virt-install` commands.