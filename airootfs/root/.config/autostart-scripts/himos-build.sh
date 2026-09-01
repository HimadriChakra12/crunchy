set -euo pipefail

URL="https://github.com/HimadriChakra12"
HOMEDIR="${HOME}"
PKG="${HOMEDIR}/pkg"
SKEL="$HOME/himos/airootfs/etc/skel"

SIMPLE_TARGETS=(shot px sxat rsxiv few det wtf whot pw rot dtop baph appache lock fetch)

SXBAR_ONLY_BUILD=(sxbar)

RDFM_TARGET=(rdfm)

mkdir -p "$PKG"

clone_if_missing() {
  local name="$1"
  if [ -d "$PKG/$name" ]; then
    echo ">> $name already cloned, skipping clone"
  else
    echo ">> cloning $name"
    git clone "$URL/$name" "$PKG/$name"
  fi
}

build_install() {
  local name="$1"
  echo ">> building $name"
  ( cd "$PKG/$name" && make && sudo make install )
}

build_only() {
  local name="$1"
  echo ">> building $name (no install)"
  ( cd "$PKG/$name" && make )
}

for t in "${SIMPLE_TARGETS[@]}"; do
  clone_if_missing "$t"
  build_install "$t"
done

for t in "${SXBAR_ONLY_BUILD[@]}"; do
  clone_if_missing "$t"
  build_only "$t"
done

build_rdfm() {
  local name="$1"
  echo ">> building $name (config branch + install.bash)"
  ( cd "$PKG/$name" && \
    git checkout -b config 2>/dev/null || git checkout config && \
    bash install.bash )
}

for t in "${RDFM_TARGET[@]}"; do
  clone_if_missing "$t"
  build_rdfm "$t"
done

echo ">> done. built: ${SIMPLE_TARGETS[*]} ${SXBAR_ONLY_BUILD[*]} ${RDFM_TARGET[*]}"

mkdir -p "$SKEL/.config"
git clone https://github.com/HimadriChakra12/himstart.nvim "$SKEL/.config/nvim"
