#!/usr/bin/env bash
# customize_airootfs.sh
# Auto-run by mkarchiso INSIDE the build chroot (needs network access
# during the build — mkarchiso's chroot has it by default unless you
# pass --offline). Removed automatically before the final squashfs is
# sealed, so none of this lingers in the shipped image — only the
# compiled binaries do.
set -euo pipefail
URL="https://github.com/HimadriChakra12"
PKG="/root/pkg"
mkdir -p "$PKG"
# build deps (git, make, gcc) now come from packages.x86_64 directly —
# no need to pacman -S them here, saves a redundant ~230MB transaction
# mid-build that was the actual cause of the disk-space failure
SIMPLE_TARGETS=(rot shot px dtop baph lock fetch doi)
# doid builds/installs alongside doi from the same repo, not a separate clone
SH_ONLY=(rsxiv)
SXBAR_ONLY=(sxbar)
RDFM_TARGET=(rdfm)

for t in "${SIMPLE_TARGETS[@]}"; do
  echo ">> building $t"
  [ -d "$PKG/$t" ] || git clone "$URL/$t" "$PKG/$t" --depth 1
  ( cd "$PKG/$t" && make && make install )
done
for t in "${SH_ONLY[@]}"; do
  echo ">> building $t"
  [ -d "$PKG/$t" ] || git clone "$URL/$t" "$PKG/$t" --depth 1
  ( cd "$PKG/$t" && bash install.sh )
done
for t in "${SXBAR_ONLY[@]}"; do
  echo ">> building $t (no install)"
  [ -d "$PKG/$t" ] || git clone "https://github.com/uint23/$t" "$PKG/$t" --depth 1
  ( cd "$PKG/$t" && make && make install )
done
for t in "${RDFM_TARGET[@]}"; do
  echo ">> building $t"
  [ -d "$PKG/$t" ] || git clone "$URL/$t" "$PKG/$t" --depth 1
  ( cd "$PKG/$t" && \
    git checkout -b config 2>/dev/null || git checkout config && \
    bash install.bash )
done

rm -rf $PKG/*

[ -d /root/.config/nvim ] || git clone https://github.com/HimadriChakra12/himstart.nvim /root/.config/nvim

pacman -Scc --noconfirm

chsh -s /bin/bash root

systemctl enable NetworkManager.service

useradd -m -G wheel,audio,video,input,storage,power,network -s /bin/bash crunchy
echo "crunchy:crunchy" | chpasswd
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel-nopasswd
chmod 440 /etc/sudoers.d/wheel-nopasswd

# home/crunchy/* was committed straight into the profile (not via
# /etc/skel), so it lands owned by root when the airootfs overlay is
# applied — useradd -m won't fix ownership of files that already
# existed before it ran, only fresh skel copies. Fix explicitly:
chown -R crunchy:crunchy /home/crunchy
