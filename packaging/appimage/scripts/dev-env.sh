#!/bin/bash
echo "Configurando entorno de desarrollo para AppImage"
#Usar Linuxdeploy para generar el AppDir
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage
echo "Entorno de desarrollo configurado correctamente"