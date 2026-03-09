# Building the Bootc ISO (Temporary Solution via Titanoboa)

Due to upstream issues with `bootc-image-builder` pulling in the older legacy Anaconda Web UI and failing to configure the live environment properly, we are temporarily using the [ublue-os/titanoboa](https://github.com/ublue-os/titanoboa) installer to generate our ISOs.

Titanoboa is an installer designed to create bootable LiveCD ISOs from customized `bootc` container images, giving us the modern Anaconda Web UI and a proper live environment out of the box.

## Instructions for Local ISO Generation

### 1. Build your proper `bootc` image first
Before generating the ISO, verify you have built your underlying OS container image and that it is present in your local podman storage:

```bash
# From the Tetra repository root
sudo podman build -t localhost/tetra:workstation .

# Or for a specific variant
sudo podman build --build-arg TAG=workstation-nvidia -t localhost/tetra:workstation-nvidia .
```

### 2. Clone the Titanoboa Repository
You need the Titanoboa repository locally to use its build scripts.

```bash
# Clone to a temporary directory or alongside your projects
git clone https://github.com/ublue-os/titanoboa.git /tmp/titanoboa
cd /tmp/titanoboa
```

### 3. Build the ISO using `just`
Titanoboa uses `just` to orchestrate the build process. You provide it the reference to your locally built container image.

```bash
# Example using the :workstation image
sudo just build localhost/tetra:workstation

# Example using the :workstation-nvidia image
sudo just build localhost/tetra:workstation-nvidia
```

**Note:** This process might take a while and requires about 20-30 GB of free space.

### 4. Locate your ISO
Once the build completes successfully, your custom bootable ISO will be generated in the current directory (e.g., `/tmp/titanoboa/`) and named `output.iso`.

```bash
ls -lh output.iso
```

### 5. (Optional) Test the ISO locally
Titanoboa includes a handy command to immediately test the built ISO using a QEMU virtual machine.

```bash
just vm ./output.iso
```

---

*Note: This process is a temporary workaround until `bootc-image-builder` officially supports these features upstream. We expect to revert to the standard supported tooling in the future.*
