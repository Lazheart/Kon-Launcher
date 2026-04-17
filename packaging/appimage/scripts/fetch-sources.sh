#!/bin/bash

set -euo pipefail

FETCH_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FETCH_APPIMAGE_DIR="$(cd "${FETCH_SCRIPT_DIR}/.." && pwd)"
FETCH_SOURCE_DIR="${FETCH_APPIMAGE_DIR}/sources"

echo "Descargando fuentes necesarias para construir el AppImage"
mkdir -p "${FETCH_SOURCE_DIR}"
echo "Clonando en: ${FETCH_SOURCE_DIR}"

clone_repo() {
	local repo_url="$1"
	local repo_name="$2"
	local repo_branch="${3:-}"
	local destination="${FETCH_SOURCE_DIR}/${repo_name}"

	if [[ -d "${destination}/.git" ]]; then
		echo "${repo_name} ya existe en ${destination}. Se omite clonacion."
		return 0
	fi

	echo "Clonando ${repo_name}..."
	if [[ -n "${repo_branch}" ]]; then
		if ! git clone --recurse-submodules --branch "${repo_branch}" "${repo_url}" "${destination}"; then
			echo "Error: no se pudo clonar ${repo_name}. Verifica tu conexion de red o la URL del repositorio." >&2
			exit 1
		fi
	else
		if ! git clone --recurse-submodules "${repo_url}" "${destination}"; then
			echo "Error: no se pudo clonar ${repo_name}. Verifica tu conexion de red o la URL del repositorio." >&2
			exit 1
		fi
	fi
}

# Clonar UI para construir
clone_repo "https://github.com/Lazheart/UI-Kon-Launcher.git" "UI-Kon-Launcher"

# Clonar extractor de APK (branch ng)
clone_repo "https://github.com/minecraft-linux/mcpelauncher-extract.git" "mcpelauncher-extract" "ng"

# Clonar launcher del APK y submodulos (branch ng)
clone_repo "https://github.com/minecraft-linux/mcpelauncher-manifest.git" "mcpelauncher-manifest" "ng"

echo "Fuentes descargadas correctamente"
