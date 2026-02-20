#!/usr/bin/env bash
# Script: scripts/create-and-seed-db.sh
# Descripción: Crea ./data si hace falta y aplica migraciones + seed al archivo SQLite local.
# Uso: ./scripts/create-and-seed-db.sh [PATH_TO_DB]
# Ejemplo: ./scripts/create-and-seed-db.sh ./data/sgr.sqlite

set -euo pipefail

# Determinar rutas relativas al repo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Ruta de DB por argumento o por defecto en repo/data/sgr.sqlite
DB_PATH="${1:-$REPO_ROOT/data/sgr.sqlite}"

# Archivos SQL a aplicar (ordenados)
MIGRATIONS=(
  "$REPO_ROOT/src/worker/migrations/001_init.sql"
  "$REPO_ROOT/scripts/seed_demo.sql"
)

echo "Repositorio: $REPO_ROOT"
echo "Archivo SQLite destino: $DB_PATH"

# Crear carpeta data si no existe
mkdir -p "$(dirname "$DB_PATH")"

# Comprobar sqlite3 CLI
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "Error: sqlite3 no encontrado. Instala sqlite3: sudo apt update && sudo apt install -y sqlite3" >&2
  exit 2
fi

# Verificar que los archivos SQL existan
for sql in "${MIGRATIONS[@]}"; do
  if [ ! -f "$sql" ]; then
    echo "Error: archivo SQL no encontrado: $sql" >&2
    exit 3
  fi
done

# Aplicar migraciones/seed
echo "Aplicando migraciones y seed al archivo SQLite..."
for sql in "${MIGRATIONS[@]}"; do
  echo "-> Ejecutando: $sql"
  sqlite3 "$DB_PATH" < "$sql"
done

# Asegurar foreign_keys ON
sqlite3 "$DB_PATH" "PRAGMA foreign_keys = ON;"

echo "Base de datos creada y poblada en: $DB_PATH"
echo "Listando tablas (resumen):"
sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;" | sed 's/^/  - /'
echo "Operación completada correctamente."
