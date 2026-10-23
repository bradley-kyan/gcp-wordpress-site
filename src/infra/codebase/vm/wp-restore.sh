#!/bin/bash
set -euo pipefail
src=${1:?usage: wp-restore DIR}
dbs=("$src"/*.sql.gz)
[ -f "${dbs[0]}" ] && [ -f "$src/uploads.tgz" ] || { echo "need *.sql.gz and uploads.tgz in $src" >&2; exit 1; }
cd /opt/wordpress

docker compose stop cloudflared wordpress
zcat "${dbs[0]}" | docker compose exec -T mariadb sh -c 'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb -uroot wordpress'
rm -rf /srv/wordpress/html/wp-content/uploads
tar -xzf "$src/uploads.tgz" -C /srv/wordpress/html/wp-content --no-same-owner --exclude='uploads/wp-file-manager-pro'
chown -R 33:33 /srv/wordpress/html/wp-content
echo "restored; start with: docker compose -f /opt/wordpress/compose.yaml up -d"
