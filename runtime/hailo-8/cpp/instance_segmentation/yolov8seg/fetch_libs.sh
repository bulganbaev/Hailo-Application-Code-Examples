#!/usr/bin/env bash
set -euo pipefail
# ---------------------------------------------------------
#   Устанавливает xtl-0.8.0, xtensor-0.26.0, xtensor-blas-0.22.0
#   в  /usr/local  (Raspberry Pi, gcc-12, cmake-4.x)
#   + раздаёт x*.hpp и делает симлинки core/views/… наверх
# ---------------------------------------------------------

declare -A VER=(
  [xtl]=0.8.0
  [xtensor]=0.26.0
  [xtensor-blas]=0.22.0
)

PREFIX=/usr/local
BUILD_TYPE=Release
SRC_DIR=~/external-libs

echo "🧹  Чистим прошлые установки из ${PREFIX}"
sudo rm -rf \
  ${PREFIX}/include/xtensor      ${PREFIX}/include/xtl \
  ${PREFIX}/lib/cmake/xtensor    ${PREFIX}/lib/cmake/xtl \
  ${PREFIX}/share/cmake/xtensor  ${PREFIX}/share/cmake/xtl \
  ${PREFIX}/share/pkgconfig/xtensor.pc || true

mkdir -p "${SRC_DIR}"
cd       "${SRC_DIR}"

# ─────────────────────────────  1. Сборка и install  ────────────────────────
for LIB in xtl xtensor xtensor-blas; do
  VER_TAG=${VER[$LIB]}
  ARCHIVE="${LIB}-${VER_TAG}.tar.gz"
  URL="https://github.com/xtensor-stack/${LIB}/archive/refs/tags/${VER_TAG}.tar.gz"

  [[ -f $ARCHIVE ]] || { echo "⬇️   ${ARCHIVE}"; wget -q "$URL" -O "$ARCHIVE"; }

  echo "📦  Распаковываем ${LIB}-${VER_TAG}"
  tar xf "$ARCHIVE"

  echo "🔧  CMake & install ${LIB}-${VER_TAG}"
  cd "${LIB}-${VER_TAG}"
  cmake -S . -B build \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
        -DBUILD_TESTS=OFF
  sudo cmake --install build
  cd ..
done

# ─────────────────────────────  2. Симлинки & обёртки  ───────────────────────
XT_ROOT=${PREFIX}/include/xtensor

echo "🔗  Создаём симлинки каталогов core/views/containers/…"
sudo find "$XT_ROOT" -mindepth 1 -maxdepth 1 -type d | while read -r d; do
  link="${PREFIX}/include/$(basename "$d")"
  [[ -e $link ]] || sudo ln -s "$d" "$link"
done

echo "🔗  Раздаём x*.hpp в корень xtensor/"
sudo find "$XT_ROOT" -mindepth 2 -maxdepth 2 -type f -name 'x*.hpp' | while read -r hdr; do
  dst="${XT_ROOT}/$(basename "$hdr")"
  [[ -e $dst ]] || sudo ln -s "$hdr" "$dst"
done

echo -e "\n✅  Установлено:"
printf "   • xtl            %s\n   • xtensor        %s\n   • xtensor-blas   %s\n" \
       "${VER[xtl]}" "${VER[xtensor]}" "${VER[xtensor-blas]}"
echo "   Все симлинки и x*.hpp-обёртки созданы в ${PREFIX}/include"
