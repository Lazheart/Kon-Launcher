#!/bin/bash

set -euo pipefail

DEV_ENV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ENV_APPIMAGE_DIR="$(cd "${DEV_ENV_SCRIPT_DIR}/.." && pwd)"
DEV_ENV_BINARY_DIR="${DEV_ENV_APPIMAGE_DIR}/binaries"
DEV_ENV_LINUXDEPLOY_BIN="${DEV_ENV_BINARY_DIR}/linuxdeploy"
DEV_ENV_LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"

echo "Configurando entorno de desarrollo para AppImage"
mkdir -p "${DEV_ENV_BINARY_DIR}"

if [[ ! -x "${DEV_ENV_LINUXDEPLOY_BIN}" ]]; then
	echo "Descargando linuxdeploy en ${DEV_ENV_LINUXDEPLOY_BIN}..."
	wget -O "${DEV_ENV_LINUXDEPLOY_BIN}" "${DEV_ENV_LINUXDEPLOY_URL}"
	chmod +x "${DEV_ENV_LINUXDEPLOY_BIN}"
else
	echo "linuxdeploy ya existe en ${DEV_ENV_LINUXDEPLOY_BIN}"
fi

echo "Entorno de desarrollo configurado correctamente"
