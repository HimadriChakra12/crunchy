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
  ( cd "$PKG/$t" && bash install.bash )
done

rm -rf $PKG/*

pacman -Scc --noconfirm

chsh -s /bin/bash root

systemctl enable NetworkManager.service
