# Upstream Roadmap: Anaconda WebUI, Live Env, Persistent USB for bootc installers

## Context

Tetra now uses `quay.io/centos-bootc/bootc-image-builder` to produce an interactive graphical Anaconda installer ISO (see [README.md](/home/justin/git/Tetra/README.md) "Building Installation Media"). The user wants to stay on upstream tooling and not fall back to downstream projects like [titanoboa](https://github.com/ublue-os/titanoboa), but is watching for three features to land upstream:

1. **Anaconda WebUI** in the installer ISO (replacing classic GTK Anaconda)
2. **Live environment** — boot to a working desktop before installing
3. **Persistent USB installer storage** — writable USB installer media

This document records what upstream is actually shipping today so we know what to watch for and what to change in [README.md](/home/justin/git/Tetra/README.md) when each feature lands.

---

## 1. Anaconda WebUI

**Status: Actively being unblocked upstream. Not available in `bootc-image-builder` today.**

- **bootc-image-builder tracking issue**: [osbuild/bootc-image-builder#722](https://github.com/osbuild/bootc-image-builder/issues/722) — closed as "not planned" in Jan 2026. Maintainer Ondřej Budai: *"It's not something on our short-term roadmap, because webui is targeting only workstation for Fedora 42 … when it's ready also for bootc, we will definitely switch to it."*
- **Core blockers (from that issue)**: Anaconda WebUI currently
  - raises `NotImplementedError` for automated / non-interactive installs
  - doesn't handle kickstart files — which is exactly how `bootc-image-builder` drives the installer today (our [blueprint.toml](/home/justin/git/Tetra/blueprint.toml) works via `[customizations.installer.kickstart]`)
- **Unblock work in flight**: [rhinstaller/anaconda#6980](https://github.com/rhinstaller/anaconda/pull/6980) (**Draft**, opened Mar 2026) — "modules: runtime: Expose AutomatedInstall and InteractiveMode on Runtime UserInterface". Exposes the D-Bus flags WebUI needs to know it's in an automated flow. Labeled `f44`/`f45`. This is the key blocker being actively worked.
- **Related plumbing that already merged**: [rhinstaller/anaconda#6838](https://github.com/rhinstaller/anaconda/pull/6838) (Jan 2026, merged) — allows `/boot/efi` mount point in bootc installations. Other merged PRs (#6982, #6957, #6956, #6945) address WebUI `boot.iso` builds. [rhinstaller/anaconda#6989](https://github.com/rhinstaller/anaconda/pull/6989) hides the network screen on Workstation Live ISO.
- **Workaround available today** (per #722): derive a container image from `bootc-image-builder` and override config files to use `anaconda-webui` instead of classic Anaconda. We are not doing this — we're waiting for upstream.

**Signal to watch**: `rhinstaller/anaconda#6980` merging, then `bootc-image-builder#722` (or a successor) reopening. Once it lands, we likely just re-pull `quay.io/centos-bootc/bootc-image-builder:latest` and our existing [blueprint.toml](/home/justin/git/Tetra/blueprint.toml) keeps working — `contents = "graphical"` should still select the graphical (web) installer.

---

## 2. Live environment (boot-to-desktop installer)

**Status: On long-term roadmap. A generic-ISO escape hatch just landed.**

- **bootc-image-builder tracking issue**: [osbuild/bootc-image-builder#1012](https://github.com/osbuild/bootc-image-builder/issues/1012) ("LiveOS support") — **Open**. Maintainer confirmed "on our long-term roadmap" but "haven't figured out the details yet."
- **Related open issues**: [#433](https://github.com/osbuild/bootc-image-builder/issues/433) (generic `iso` support), [#1167](https://github.com/osbuild/bootc-image-builder/issues/1167) (Live PXE artifact).
- **Current titanoboa-style workaround** (per #1012 discussion): dump image to disk → install live-OS components → pull image again → wrap in squashfs→ISO. Produces ~5 GB ISOs with two copies of the image because "layering live stuff onto the image … doesn't seem possible right now." This is exactly what we're avoiding.
- **Newly-available upstream path**: a `bootc-generic-iso` image type landed in the `images` tool (Jan 2026). Per the maintainer, "it is entirely up to the container what sort of ISO gets created (live media, payload installer)." This is the hook a future upstream live environment would plug into — and it could eventually let us emit both an interactive Anaconda installer *and* a live desktop from one build.

**Signal to watch**: `bootc-image-builder#1012` getting an assignee / linked PR, or `bootc-generic-iso` documentation appearing in the bootc-image-builder README. When either happens, the [README.md](/home/justin/git/Tetra/README.md) "Building Installation Media" section will likely grow a second `--type` option.

---

## 3. Persistent USB installer storage

**Status: Not an upstream bootc-image-builder concern. No tracking issues.**

- No matching issues in `osbuild/bootc-image-builder` (searched `persistent usb`, `usb`). The 10 USB-tangential results are all bug reports unrelated to persistent writable media.
- This is really a Fedora Workstation / Anaconda-ISO media feature (analogous to live-usb-creator persistent overlays), not something `bootc-image-builder` itself would implement. If it comes upstream, it'll most likely come via the Anaconda Live ISO path (see §2) + a Fedora media-writer change — not a new `bootc-image-builder` flag.
- No action needed here. If the user hears about this landing somewhere (e.g. Fedora release notes), we can revisit.

---

## 4. Tool-merge status (`bootc-image-builder` vs `image-builder-cli`)

- Upstream [image-builder-cli README](https://github.com/osbuild/image-builder-cli) FAQ still says: *"Both projects are very close. The bootc-image-builder focuses on providing image-based artifacts while image-builder works with traditional package-based inputs."* Merge is stated as a goal but no date.
- For bootc container → installer ISO **today**, `quay.io/centos-bootc/bootc-image-builder:latest` remains correct. The README.md note already reflects this.

**Signal to watch**: `image-builder-cli` gaining a `--type anaconda-iso` (currently only has `bootc-installer`, which requires a separate installer container — what 31ab475 used before cleanup). If/when that happens the two workflows unify and we might switch to the `ghcr.io/osbuild/image-builder-cli` image.

---

## Actions when features land

These are the concrete edits the user would eventually make to [README.md](/home/justin/git/Tetra/README.md) — staged here so we don't have to re-derive them later.

| Upstream signal | README action |
|---|---|
| `bootc-image-builder#722` reopens / changelog mentions WebUI | No command change expected. Update the "What each flag does" table and the intro paragraph to say the installer is now WebUI-based. Re-test that `contents = "graphical"` still triggers graphical mode (may need to drop or change the directive). |
| `bootc-image-builder#1012` lands or `bootc-generic-iso` type is documented for live boot | Add a second build command block for `--type bootc-generic-iso` (or whatever live type ships), and a short "Live vs installer" blurb. Keep the existing `anaconda-iso` block. |
| `image-builder-cli` gains `anaconda-iso` support | Switch the `podman run` block from `quay.io/centos-bootc/bootc-image-builder:latest` to `ghcr.io/osbuild/image-builder-cli:latest`, verify blueprint schema unchanged, retest. |
| Persistent USB storage shows up somewhere | Likely no README change (out of scope for image build). Maybe a one-line "To write with persistence, see Fedora Media Writer …" pointer. |