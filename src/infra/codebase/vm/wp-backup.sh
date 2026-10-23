#!/bin/bash
set -euo pipefail
: "${BUCKET:?}"
ts=$(date -u +%Y%m%dT%H%M%SZ)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd /opt/wordpress

docker compose exec -T mariadb sh -c 'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb-dump -uroot --single-transaction --routines --triggers wordpress' | gzip > "$tmp/db.sql.gz"
tar -czf "$tmp/uploads.tgz" -C /srv/wordpress/html/wp-content uploads plugins themes || [ $? -eq 1 ]

token=$(curl -fsS -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')
for f in db.sql.gz uploads.tgz; do
  curl -fsS -o /dev/null -X POST -H "Authorization: Bearer $token" -H 'Content-Type: application/gzip' \
    -T "$tmp/$f""https://storage.googleapis.com/upload/storage/v1/b/$BUCKET/o?uploadType=media&name=$ts/$f"
done
