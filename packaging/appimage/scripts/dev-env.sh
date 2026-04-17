#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPIMAGE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BINARY_DIR="${APPIMAGE_DIR}/binaries"
LINUXDEPLOY_BIN="${BINARY_DIR}/linuxdeploy"
LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"

echo "Configurando entorno de desarrollo para AppImage"
mkdir -p "${BINARY_DIR}"

if [[ ! -x "${LINUXDEPLOY_BIN}" ]]; then
	echo "Descargando linuxdeploy en ${LINUXDEPLOY_BIN}..."
	wget -O "${LINUXDEPLOY_BIN}" "${LINUXDEPLOY_URL}"
	chmod +x "${LINUXDEPLOY_BIN}"
else
	echo "linuxdeploy ya existe en ${LINUXDEPLOY_BIN}"
fi

echo "Entorno de desarrollo configurado correctamente"
