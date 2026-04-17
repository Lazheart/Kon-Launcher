#!/bin/bash
# Script principal para construir el AppImage de Kon-Launcher
set -e

# 1. Configurar entorno de desarrollo
source "$(dirname "$0")/scripts/dev-env.sh"
# 2. Instalar dependencias necesarias
source "$(dirname "$0")/scripts/build-deps.sh"
# 3. Descargar fuentes necesarias
source "$(dirname "$0")/scripts/fetch-sources.sh"
# 4. Construir el AppImage
echo "Construyendo el AppImage..."
cd "$(dirname "$0")/.."
echo "Compilando UI..."
cd UI-Kon-Launcher
#Usando las flags correspondientes para generar un binario compatible con AppImage

# Usar Linux deploy para generar el AppDir
echo "Lanzando linuxdeploy para generar el AppDir..."
linuxdeploy --appdir=AppDir --output=appimage
# 5. Mover el AppImage generado a la carpeta de salida
mv Kon-Launcher*.AppImage output/
echo "AppImage generado exitosamente en output/"
