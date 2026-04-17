#!/bin/bash
# Script principal para construir el AppImage de Kon-Launcher

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/sources"
BINARY_DIR="${SCRIPT_DIR}/binaries"
OUTPUT_DIR="${SCRIPT_DIR}/output"

UI_SOURCE_DIR="${SOURCE_DIR}/UI-Kon-Launcher"
EXTRACT_SOURCE_DIR="${SOURCE_DIR}/mcpelauncher-extract"
CLIENT_SOURCE_DIR="${SOURCE_DIR}/mcpelauncher-manifest"

UI_BUILD_DIR="${BINARY_DIR}/UI-Kon-Launcher-build"
EXTRACT_BUILD_DIR="${BINARY_DIR}/mcpelauncher-extract-build"
CLIENT_BUILD_DIR="${BINARY_DIR}/mcpelauncher-client-build"

APPDIR_PATH="${BINARY_DIR}/AppDir"
LINUXDEPLOY_BIN="${BINARY_DIR}/linuxdeploy"
CPU_COUNT="$(nproc 2>/dev/null || echo 1)"

mkdir -p "${SOURCE_DIR}" "${BINARY_DIR}" "${OUTPUT_DIR}"

# 1. Configurar entorno de desarrollo
source "${SCRIPT_DIR}/scripts/dev-env.sh"
# 2. Instalar dependencias necesarias
source "${SCRIPT_DIR}/scripts/build-deps.sh"
# 3. Descargar fuentes necesarias
source "${SCRIPT_DIR}/scripts/fetch-sources.sh"

# 4. Validar fuentes requeridas
if [[ ! -d "${UI_SOURCE_DIR}" || ! -d "${EXTRACT_SOURCE_DIR}" || ! -d "${CLIENT_SOURCE_DIR}" ]]; then
	echo "Error: faltan sources requeridos en ${SOURCE_DIR}" >&2
	exit 1
fi

# Limpiar AppDir antes de instalar componentes
rm -rf "${APPDIR_PATH}"
mkdir -p "${APPDIR_PATH}"

if ! command -v clang >/dev/null 2>&1 || ! command -v clang++ >/dev/null 2>&1; then
	echo "Error: clang/clang++ no estan disponibles en el sistema." >&2
	exit 1
fi

export CFLAGS="${CFLAGS:-} -O2 -fPIC"
export CXXFLAGS="${CXXFLAGS:-} -O2 -fPIC"

# 5. Construir mcpelauncher-extract
echo "Construyendo mcpelauncher-extract desde ${EXTRACT_SOURCE_DIR}..."
git -C "${EXTRACT_SOURCE_DIR}" submodule update --init --recursive

cmake -S "${EXTRACT_SOURCE_DIR}" -B "${EXTRACT_BUILD_DIR}" \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DCMAKE_C_COMPILER=clang \
	-DCMAKE_CXX_COMPILER=clang++
cmake --build "${EXTRACT_BUILD_DIR}" -- -j"${CPU_COUNT}"
DESTDIR="${APPDIR_PATH}" cmake --install "${EXTRACT_BUILD_DIR}"

# 6. Construir mcpelauncher-manifest (cliente)
echo "Construyendo mcpelauncher-manifest desde ${CLIENT_SOURCE_DIR}..."
git -C "${CLIENT_SOURCE_DIR}" submodule update --init --recursive

cmake -S "${CLIENT_SOURCE_DIR}" -B "${CLIENT_BUILD_DIR}" \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DENABLE_DEV_PATHS=OFF \
	-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DCMAKE_PREFIX_PATH="/usr/lib/qt5/lib/cmake:/usr/lib/x86_64-linux-gnu/cmake:/usr/lib/cmake" \
	-DCMAKE_INCLUDE_PATH=/usr/include \
	-DCMAKE_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:/usr/lib" \
	-DUSE_OWN_CURL=OFF \
	-DCURL_INCLUDE_DIR=/usr/include \
	-DCURL_LIBRARY=/usr/lib/x86_64-linux-gnu/libcurl.so \
	-DBUILD_CLIENT=ON \
	-DBUILD_UI=OFF \
	-DCMAKE_C_COMPILER=clang \
	-DCMAKE_CXX_COMPILER=clang++
cmake --build "${CLIENT_BUILD_DIR}" -- -j"${CPU_COUNT}"
DESTDIR="${APPDIR_PATH}" cmake --install "${CLIENT_BUILD_DIR}"

# 7. Construir UI
echo "Construyendo la UI desde ${UI_SOURCE_DIR}..."

cmake -S "${UI_SOURCE_DIR}" -B "${UI_BUILD_DIR}" \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DCMAKE_C_COMPILER=clang \
	-DCMAKE_CXX_COMPILER=clang++
cmake --build "${UI_BUILD_DIR}" -- -j"${CPU_COUNT}"

DESTDIR="${APPDIR_PATH}" cmake --install "${UI_BUILD_DIR}"

# Copiar metadata usada por linuxdeploy
mkdir -p "${APPDIR_PATH}/usr/share/applications" "${APPDIR_PATH}/usr/share/icons/hicolor/scalable/apps"
cp "${SCRIPT_DIR}/kon-launcher.desktop" "${APPDIR_PATH}/usr/share/applications/kon-launcher.desktop"
if [[ -f "${SCRIPT_DIR}/kon-launcher.svg" ]]; then
	cp "${SCRIPT_DIR}/kon-launcher.svg" "${APPDIR_PATH}/usr/share/icons/hicolor/scalable/apps/kon-launcher.svg"
fi

# 8. Generar el AppImage
echo "Lanzando linuxdeploy para generar el AppImage..."
pushd "${SCRIPT_DIR}" >/dev/null

APPIMAGE_ARCH_RAW="$(uname -m)"
case "${APPIMAGE_ARCH_RAW}" in
	x86_64|amd64)
		APPIMAGE_ARCH="x86_64"
		;;
	aarch64|arm64)
		APPIMAGE_ARCH="aarch64"
		;;
	armv7l|armhf)
		APPIMAGE_ARCH="armhf"
		;;
	i386|i486|i586|i686)
		APPIMAGE_ARCH="i686"
		;;
	*)
		APPIMAGE_ARCH="${APPIMAGE_ARCH_RAW}"
		;;
esac

DESKTOP_FILE_PATH="${APPDIR_PATH}/usr/share/applications/org.lazheart.minecraft-launcher.desktop"
if [[ ! -f "${DESKTOP_FILE_PATH}" ]]; then
	DESKTOP_FILE_PATH="${APPDIR_PATH}/usr/share/applications/kon-launcher.desktop"
fi

ICON_FILE_PATH="${APPDIR_PATH}/usr/share/icons/hicolor/scalable/apps/org.lazheart.minecraft-launcher.svg"
if [[ ! -f "${ICON_FILE_PATH}" ]]; then
	ICON_FILE_PATH="${APPDIR_PATH}/usr/share/icons/hicolor/scalable/apps/kon-launcher.svg"
fi

EXECUTABLE_PATH="${APPDIR_PATH}/usr/bin/minecraft-launcher-gui"

if [[ ! -f "${DESKTOP_FILE_PATH}" ]]; then
	echo "Error: no se encontro desktop file en AppDir." >&2
	popd >/dev/null
	exit 1
fi

if [[ ! -f "${ICON_FILE_PATH}" ]]; then
	echo "Error: no se encontro icono en AppDir." >&2
	popd >/dev/null
	exit 1
fi

if [[ ! -x "${EXECUTABLE_PATH}" ]]; then
	echo "Error: no se encontro ejecutable minecraft-launcher-gui en AppDir." >&2
	popd >/dev/null
	exit 1
fi

ARCH="${APPIMAGE_ARCH}" "${LINUXDEPLOY_BIN}" \
	--appdir="${APPDIR_PATH}" \
	--desktop-file="${DESKTOP_FILE_PATH}" \
	--icon-file="${ICON_FILE_PATH}" \
	--executable="${EXECUTABLE_PATH}" \
	--output=appimage

# 9. Mover AppImage generado a output/
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
