# Tetra

This repository contains the configuration and Containerfiles for building Tetra, an atomic Fedora based Linux distribution using `bootc` (ostree + containers).

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