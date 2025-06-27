#!/usr/bin/env bash
set -e
# ---------------------------------------------------------
#   xtl-0.8.0, xtensor-0.26.0, xtensor-blas-0.22.0 → /usr/local
#   + раздача x*.hpp  + симлинки core/views/… (Raspberry Pi, gcc-12)
# ---------------------------------------------------------

VER_XTL=0.8.0
VER_XTENSOR=0.26.0
VER_BLAS=0.22.0

PREFIX=/usr/local
BUILD_TYPE=Release

# ── 1. очистка прошлых установок ─────────────────────────
sudo rm -rf \
  ${PREFIX}/include/xtensor      ${PREFIX}/include/xtl \
  ${PREFIX}/lib/cmake/xtensor    ${PREFIX}/lib/cmake/xtl \
  ${PREFIX}/share/cmake/xtensor  ${PREFIX}/share/cmake/xtl \
  ${PREFIX}/share/pkgconfig/xtensor.pc || true

mkdir -p ~/src && cd ~/src

# ── 2-a. xtl / xtensor / xtensor-blas ─────────────────────
for LIB in xtl xtensor xtensor-blas; do
  VER_VAR=VER_${LIB^^/*-/}
  VER=${!VER_VAR}
  FILE=${LIB}.tar.gz
  wget -q "https://github.com/xtensor-stack/${LIB}/archive/refs/tags/${VER}.tar.gz" -O $FILE
  tar xf $FILE && cd "${LIB}-${VER}"
  cmake -S . -B build -DCMAKE_INSTALL_PREFIX=${PREFIX} \
                      -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
                      -DBUILD_TESTS=OFF
  sudo cmake --install build
  cd ..
done

XT_ROOT=${PREFIX}/include/xtensor

# ── 2-b. каталоги core/views/containers/…  -> симлинки наверх ────────────
sudo find "${XT_ROOT}" -mindepth 1 -maxdepth 1 -type d | while read -r d; do
  base=$(basename "$d")
  link="${PREFIX}/include/${base}"
  [[ -e "$link" ]] || sudo ln -s "$d" "$link"
done

# ── 2-c. x*.hpp-обёртки в корень xtensor/ ───────────────────────────────
sudo find "${XT_ROOT}" -mindepth 2 -maxdepth 2 -type f -name 'x*.hpp' | while read -r hdr; do
  dst="${XT_ROOT}/$(basename "$hdr")"
  [[ -e "$dst" ]] || sudo ln -s "$hdr" "$dst"
done

echo -e "\n✅  xtl-${VER_XTL}  xtensor-${VER_XTENSOR}  xtensor-blas-${VER_BLAS} установлены"
echo "    Хедеры-обёртки и каталоги-симлинки созданы.\n"
