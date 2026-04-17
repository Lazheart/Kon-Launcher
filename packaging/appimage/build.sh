#!/bin/bash
# Script principal para construir el AppImage de Kon-Launcher

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/sources"
BINARY_DIR="${SCRIPT_DIR}/binaries"
OUTPUT_DIR="${SCRIPT_DIR}/output"

UI_SOURCE_DIR="${SOURCE_DIR}/UI-Kon-Launcher"
UI_BUILD_DIR="${BINARY_DIR}/UI-Kon-Launcher-build"
APPDIR_PATH="${BINARY_DIR}/AppDir"
LINUXDEPLOY_BIN="${BINARY_DIR}/linuxdeploy"

mkdir -p "${SOURCE_DIR}" "${BINARY_DIR}" "${OUTPUT_DIR}"

# 1. Configurar entorno de desarrollo
source "${SCRIPT_DIR}/scripts/dev-env.sh"
# 2. Instalar dependencias necesarias
source "${SCRIPT_DIR}/scripts/build-deps.sh"
# 3. Descargar fuentes necesarias
source "${SCRIPT_DIR}/scripts/fetch-sources.sh"

# 4. Construir la UI con flags para binario portable
if [[ ! -d "${UI_SOURCE_DIR}" ]]; then
	echo "Error: no se encontro el source de UI en ${UI_SOURCE_DIR}" >&2
	exit 1
fi

echo "Construyendo la UI desde ${UI_SOURCE_DIR}..."
export CFLAGS="${CFLAGS:-} -O2 -fPIC"
export CXXFLAGS="${CXXFLAGS:-} -O2 -fPIC"

cmake -S "${UI_SOURCE_DIR}" -B "${UI_BUILD_DIR}" \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/usr
cmake --build "${UI_BUILD_DIR}" -- -j"$(nproc)"

rm -rf "${APPDIR_PATH}"
DESTDIR="${APPDIR_PATH}" cmake --install "${UI_BUILD_DIR}"

# Copiar metadata usada por linuxdeploy
mkdir -p "${APPDIR_PATH}/usr/share/applications" "${APPDIR_PATH}/usr/share/icons/hicolor/scalable/apps"
cp "${SCRIPT_DIR}/kon-launcher.desktop" "${APPDIR_PATH}/usr/share/applications/kon-launcher.desktop"
if [[ -f "${SCRIPT_DIR}/kon-launcher.svg" ]]; then
	cp "${SCRIPT_DIR}/kon-launcher.svg" "${APPDIR_PATH}/usr/share/icons/hicolor/scalable/apps/kon-launcher.svg"
fi

# 5. Generar el AppImage
echo "Lanzando linuxdeploy para generar el AppImage..."
pushd "${SCRIPT_DIR}" >/dev/null
"${LINUXDEPLOY_BIN}" --appdir="${APPDIR_PATH}" --output=appimage

# 6. Mover AppImage generado a output/
shopt -s nullglob
generated_appimages=( *.AppImage )
if (( ${#generated_appimages[@]} == 0 )); then
	echo "Error: no se genero ningun AppImage." >&2
	popd >/dev/null
	exit 1
fi

if (( ${#generated_appimages[@]} == 1 )); then
	mv "${generated_appimages[0]}" "${OUTPUT_DIR}/Kon-Launcher.AppImage"
	echo "AppImage renombrado a ${OUTPUT_DIR}/Kon-Launcher.AppImage"
else
	echo "Se generaron multiples AppImage; se conservan nombres originales."
	mv "${generated_appimages[@]}" "${OUTPUT_DIR}/"
fi

shopt -u nullglob
popd >/dev/null

echo "AppImage generado exitosamente en ${OUTPUT_DIR}"
