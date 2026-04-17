#!/bin/bash

set -euo pipefail

MAX_RETRIES=3
RETRY_DELAY=5

check_network() {
    # Verifica resolucion DNS hacia mirrors comunes de Debian/Ubuntu.
    getent hosts deb.debian.org >/dev/null 2>&1 || \
    getent hosts security.debian.org >/dev/null 2>&1 || \
    getent hosts archive.ubuntu.com >/dev/null 2>&1 || \
    getent hosts security.ubuntu.com >/dev/null 2>&1
}

run_with_retry() {
    local attempt=1
    local exit_code=0

    while (( attempt <= MAX_RETRIES )); do
        if "$@"; then
            return 0
        else
            exit_code=$?
        fi

        echo "Intento ${attempt}/${MAX_RETRIES} fallido (codigo ${exit_code}): $*"

        if ! check_network; then
            echo "Parece que hay un problema de red/DNS. Revisa tu conexion e intenta de nuevo."
        fi

        if (( attempt < MAX_RETRIES )); then
            echo "Reintentando en ${RETRY_DELAY}s..."
            sleep "${RETRY_DELAY}"
        fi

        attempt=$((attempt + 1))
    done

    return "${exit_code}"
}

apt_update() {
    run_with_retry sudo apt update -o Acquire::Retries=3 -o Acquire::http::Timeout=20
}

apt_install() {
    run_with_retry sudo apt install -y -o Acquire::Retries=3 -o Acquire::http::Timeout=20 "$@"
}

echo "Instalando dependencias necesarias para los sources..."
if ! apt_update; then
    echo "Error: no se pudo actualizar el indice de paquetes."
    exit 1
fi

# Base toolchain
if ! apt_install \
    build-essential cmake git wget pkg-config \
    ca-certificates; then
    echo "Error: fallo al instalar dependencias base."
    exit 1
fi

# Qt5 (UI)
echo "Instalando dependencias necesarias para la UI (Qt5)..."
if ! apt_install \
    qtbase5-dev qtdeclarative5-dev \
    qttools5-dev qttools5-dev-tools \
    qtwebengine5-dev \
    libqt5svg5-dev; then
    echo "Error: fallo al instalar dependencias de Qt5."
    exit 1
fi

# QML modules
if ! apt_install \
    qml-module-qtquick2 \
    qml-module-qtquick-layouts \
    qml-module-qtquick-controls \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-window2 \
    qml-module-qtquick-dialogs \
    qml-module-qtgraphicaleffects \
    qml-module-qt-labs-settings \
    qml-module-qt-labs-folderlistmodel \
    qml-module-qtwebengine; then
    echo "Error: fallo al instalar modulos QML."
    exit 1
fi

echo "Dependencias UI instaladas correctamente"

# Extractor APK (libzip)
echo "Instalando dependencias para el extractor de APK..."
if ! apt_install libzip-dev; then
    echo "Error: fallo al instalar dependencias del extractor APK."
    exit 1
fi
echo "Extractor listo"

# Launcher (runtime libs)
echo "Instalando dependencias para el launcher..."
if ! apt_install \
    libssl-dev libpng-dev libx11-dev libxi-dev \
    libcurl4-openssl-dev libudev-dev libevdev-dev \
    libegl1-mesa-dev libasound2 libpulse-dev; then
    echo "Error: fallo al instalar dependencias del launcher."
    exit 1
fi

echo "Launcher listo"

echo "Todas las dependencias instaladas correctamente"