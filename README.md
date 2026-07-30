# Tetra

![Daily Build](https://github.com/OptimoSupreme/Tetra/actions/workflows/build.yml/badge.svg)

This repository contains the configuration and Containerfiles for building Tetra, an atomic Fedora based Linux distribution using `bootc`.

## Bootc tools

Installed Tetra systems track `ghcr.io/optimosupreme/tetra:main`, which is rebuilt daily at 07:00 UTC. `bootc-fetch-apply-updates.timer` is enabled by default and checks once a day at 10:00 local time, after the daily build has published. If the machine is off or asleep at 10:00, the check runs once it is awake again (`Persistent=true`).

Unlike upstream bootc, Tetra runs `bootc upgrade` **without** `--apply`: updates are staged but never applied automatically, so the system will not reboot on its own interupting work. When a deployment is staged, a notification in your session offers to restart.

```bash
sudo bootc status            # see what's installed and what's staged
sudo bootc upgrade           # force an update now
sudo systemctl reboot        # apply it
sudo bootc rollback          # revert to the previous deployment
```

## Building an installer ISO

Build an anaconda installer ISO from the published GHCR image. The following commands require the git repo to be cloned locally, and to be run run from its root directory.

```bash
# Build the ISO
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

# Rename the ISO
mv ./output/bootiso/install.iso ./output/bootiso/tetra-$(date -u +%Y%m%d).iso
```

The finished ISO lands at `output/bootiso/tetra-YYYYMMDD.iso`.

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

# Resize the qcow2 to a 30G disk
qemu-img resize ./output/qcow2/disk.qcow2 30G

# Install the VM
sudo cp ~/git/Tetra/output/qcow2/disk.qcow2 \
        /var/lib/libvirt/images/tetra.qcow2

virt-install --connect qemu:///system \
  --name tetra \
  --memory 8192 --vcpus 6 --cpu host-passthrough \
  --boot uefi \
  --disk path=/var/lib/libvirt/images/tetra.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice,listen=socket \
  --video virtio \
  --channel spicevmc \
  --osinfo fedora-unknown \
  --import --noautoconsole
```

### Building an installer ISO from the local container

```bash
# Build the ISO
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

# Rename the ISO
mv ./output/bootiso/install.iso ./output/bootiso/tetra-$(date -u +%Y%m%d).iso
```