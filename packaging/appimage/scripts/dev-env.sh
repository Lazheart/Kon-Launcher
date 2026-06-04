#!/bin/bash

set -euo pipefail

DEV_ENV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ENV_APPIMAGE_DIR="$(cd "${DEV_ENV_SCRIPT_DIR}/.." && pwd)"
DEV_ENV_BINARY_DIR="${DEV_ENV_APPIMAGE_DIR}/binaries"

DEV_ENV_LINUXDEPLOY_BIN="${DEV_ENV_BINARY_DIR}/linuxdeploy"
DEV_ENV_LINUXDEPLOY_QT_BIN="${DEV_ENV_BINARY_DIR}/linuxdeploy-plugin-qt"

mkdir -p "${DEV_ENV_BINARY_DIR}"

ARCH="$(uname -m)"

case "${ARCH}" in
    x86_64|amd64)
        APPIMAGE_ARCH="x86_64"
        ;;
    aarch64|arm64)
        APPIMAGE_ARCH="aarch64"
        ;;
    *)
        echo "Arquitectura no soportada: ${ARCH}"
        exit 1
        ;;
esac

DEV_ENV_LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${APPIMAGE_ARCH}.AppImage"
DEV_ENV_LINUXDEPLOY_QT_URL="https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-${APPIMAGE_ARCH}.AppImage"

echo "Configurando entorno de desarrollo para AppImage"

if [[ ! -x "${DEV_ENV_LINUXDEPLOY_BIN}" ]]; then
    echo "Descargando linuxdeploy..."
    wget -O "${DEV_ENV_LINUXDEPLOY_BIN}" "${DEV_ENV_LINUXDEPLOY_URL}"
    chmod +x "${DEV_ENV_LINUXDEPLOY_BIN}"
else
    echo "linuxdeploy ya existe"
fi

if [[ ! -x "${DEV_ENV_LINUXDEPLOY_QT_BIN}" ]]; then
    echo "Descargando linuxdeploy-plugin-qt..."
    wget -O "${DEV_ENV_LINUXDEPLOY_QT_BIN}" "${DEV_ENV_LINUXDEPLOY_QT_URL}"
    chmod +x "${DEV_ENV_LINUXDEPLOY_QT_BIN}"
else
    echo "linuxdeploy-plugin-qt ya existe"
fi

export PATH="${DEV_ENV_BINARY_DIR}:$PATH"

echo "Plugins disponibles:"
"${DEV_ENV_LINUXDEPLOY_BIN}" --list-plugins || true

echo "Entorno de desarrollo configurado correctamente"