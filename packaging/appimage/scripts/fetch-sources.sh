#!/bin/bash

#Mensaje de Inicio
echo "Descargando fuentes necesarias para construir el AppImage"
echo "Clonando en: $(pwd)"

clone_repo() {
	local repo_url="$1"
	local repo_name="$2"

	echo "Clonando ${repo_name}..."
	if ! git clone --recurse-submodules "${repo_url}"; then
		echo "Error: no se pudo clonar ${repo_name}. Verifica tu conexion de red o la URL del repositorio." >&2
		exit 1
	fi
}

#Clonar UI para construir
clone_repo "https://github.com/Lazheart/UI-Kon-Launcher.git" "UI-Kon-Launcher"

#Clonar Extractor de APK
clone_repo "https://github.com/minecraft-linux/mcpelauncher-extract.git" "mcpelauncher-extract"

#Clonar Launcher del apk y sub modulos
clone_repo "https://github.com/minecraft-linux/mcpelauncher-manifest.git" "mcpelauncher-manifest"

echo "Fuentes descargadas correctamente"