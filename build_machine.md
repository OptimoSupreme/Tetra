## Building Tetra on bolg

```bash
ssh bolg
cd ~/git/Tetra
git pull

# Build the OS container (~5–10 GB layer cache)
sudo podman build -t localhost/tetra:workstation .

# Build the qcow2 for VM testing
sudo podman run \
  --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v ./output:/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type qcow2 --rootfs btrfs --use-librepo=True \
  localhost/tetra:workstation

sudo chown -R $USER:$USER ./output
```

The disk lands at `~/git/Tetra/output/qcow2/disk.qcow2` on bolg.

## Running a test VM on bolg, viewing it from the local laptop

On **bolg**, after the qcow2 build:

```bash
sudo cp ~/git/Tetra/output/qcow2/disk.qcow2 \
        /var/lib/libvirt/images/tetra.qcow2

virt-install --connect qemu:///system \
  --name tetra \
  --memory 8192 --vcpus 4 --cpu host-passthrough \
  --boot uefi \
  --disk path=/var/lib/libvirt/images/tetra.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice,listen=socket \
  --video virtio \
  --channel spicevmc \
  --osinfo fedora-unknown \
  --import --noautoconsole
```

## Building the installer ISO on bolg

```bash
ssh bolg
cd ~/git/Tetra

sudo podman pull ghcr.io/optimosupreme/tetra:workstation
sudo podman run \
  --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v ./blueprint.toml:/config.toml:ro \
  -v ./output:/output \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type anaconda-iso --rootfs btrfs --use-librepo=True \
  ghcr.io/optimosupreme/tetra:workstation

sudo chown -R $USER:$USER ./output
mv ./output/bootiso/install.iso \
   ./output/bootiso/tetra-workstation-$(date -u +%Y%m%d).iso
```

To pull the finished ISO to the local laptop:

```bash
scp bolg:git/Tetra/output/bootiso/tetra-workstation-*.iso ./
```