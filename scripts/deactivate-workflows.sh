#!/bin/bash
# インポート前に、全activeワークフローをn8n REST API経由で無効化する
# CLI(unpublish:workflow)はn8n再起動まで反映されないため、APIを使う

set -euo pipefail

N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_API_KEY="${N8N_API_KEY:-}"

if [ -z "$N8N_API_KEY" ]; then
  echo "ERROR: N8N_API_KEY is not set"
  exit 1
fi

# APIからactiveなワークフロー一覧を取得
ACTIVE_IDS=$(curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" "$N8N_URL/api/v1/workflows?active=true&limit=250" | jq -r '.data[].id')

if [ -z "$ACTIVE_IDS" ]; then
  echo "No active workflows to deactivate."
  exit 0
fi

for id in $ACTIVE_IDS; do
  echo "Deactivating workflow $id..."
  if curl -s -X PATCH -H "X-N8N-API-KEY: $N8N_API_KEY" -H "Content-Type: application/json" \
    -d '{"active": false}' "$N8N_URL/api/v1/workflows/$id" > /dev/null; then
    echo "  OK"
  else
    echo "  FAILED to deactivate $id (continuing...)"
  fi
done

echo "All workflows deactivated."
