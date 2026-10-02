#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Construye el paquete de despliegue (deploy.zip) para Azure App Service.
#
# La idea central: el ZIP no es "el repositorio comprimido". Es el artefacto
# de ejecucion, y contiene exactamente lo que el proceso necesita para correr,
# ni un archivo mas:
#
#   SI entra  ->  src/, public/, package.json, package-lock.json, node_modules
#                 (solo dependencias de produccion)
#   NO entra  ->  tests/, coverage/, .git/, infra/, .github/, jest, supertest
#
# Ejecutar con:  bash scripts/empaquetar.sh
# ---------------------------------------------------------------------------
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"

echo "==> Limpiando artefactos anteriores"
rm -rf paquete deploy.zip

echo "==> Copiando solo lo que se ejecuta en produccion"
mkdir -p paquete
cp -r src public package.json package-lock.json paquete/

echo "==> Instalando dependencias de produccion dentro del paquete"
# --omit=dev deja fuera jest y supertest: no se prueba en produccion.
# npm ci exige package-lock.json e instala versiones exactas; npm install
# podria resolver versiones distintas a las que usted probo.
( cd paquete && npm ci --omit=dev --no-audit --no-fund )

echo "==> Comprimiendo"
( cd paquete && zip -rq ../deploy.zip . )

TAM=$(du -h deploy.zip | cut -f1)
ARCHIVOS=$(unzip -l deploy.zip | tail -1 | awk '{print $2}')
echo
echo "Paquete listo: deploy.zip  (${TAM}, ${ARCHIVOS} archivos)"
echo "Contenido de primer nivel:"
unzip -l deploy.zip | awk 'NR>3 && NF==4 {print $4}' | cut -d/ -f1 | sort -u | sed 's/^/   /'
