# Tetra

![Weekly Build](https://github.com/OptimoSupreme/Tetra/actions/workflows/build.yml/badge.svg)

This repository contains the configuration and Containerfiles for building Tetra, an atomic Fedora based Linux distribution using `bootc`.

## Bootc tools

Installed Tetra systems track `ghcr.io/optimosupreme/tetra:main` and pull updates on a weekly timer (`bootc-fetch-apply-updates.timer`, enabled by default).

```bash
sudo bootc status            # see what's installed and what's staged
sudo bootc upgrade           # force an update now
sudo systemctl reboot        # apply it
sudo bootc rollback          # revert to the previous deployment
```

## Building an installer ISO

Build an anaconda installer ISO from the published GHCR image. The following commands require the git repo to be cloned locally, and to be run run from its root directory.

```bash
sudo podman pull ghcr.io/optimosupreme/tetra:main
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
  ghcr.io/optimosupreme/tetra:main
sudo chown -R $USER:$USER ./output
mv ./output/bootiso/install.iso ./output/bootiso/tetra-$(date -u +%Y%m%d).iso
```

The finished ISO lands at `output/bootiso/tetra-main-YYYYMMDD.iso`.

## Development and testing

These recipes are for iterating on Tetra locally against uncommitted changes to the Containerfile. For a normal install, use the GHCR-based ISO build above. The following commands require the git repo to be cloned locally, and to be run run from its root directory.

### Building locally

```bash
# Switch to the Tetra directory
cd ~/git/Tetra

# Build the OS container
sudo podman build -t localhost/tetra:main .

# Build the qcow2 for VM testing
sudo podman run \
  --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v ./output:/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type qcow2 \
  --rootfs btrfs \
  --use-librepo=True \
  localhost/tetra:main
sudo chown -R $USER:$USER ./output

# Install the VM
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
  localhost/tetra:main
sudo chown -R $USER:$USER ./output
mv ./output/bootiso/install.iso ./output/bootiso/tetra-$(date -u +%Y%m%d).iso
```