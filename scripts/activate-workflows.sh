#!/bin/bash
# インポート後に、元々activeだったワークフローをn8n REST API経由で有効化する
# workflows/*.json から active: true のワークフローIDを取得し、APIで有効化する

set -euo pipefail

N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_API_KEY="${N8N_API_KEY:-}"

if [ -z "$N8N_API_KEY" ]; then
  echo "ERROR: N8N_API_KEY is not set"
  exit 1
fi

# 元のJSONファイルからactive: trueのワークフローIDを収集
ACTIVE_IDS=$(jq -r 'select(.active == true) | .id' workflows/*.json)

if [ -z "$ACTIVE_IDS" ]; then
  echo "No workflows to activate."
  exit 0
fi

failed=0
for id in $ACTIVE_IDS; do
  echo "Activating workflow $id..."
  if curl -s -X PATCH -H "X-N8N-API-KEY: $N8N_API_KEY" -H "Content-Type: application/json" \
    -d '{"active": true}' "$N8N_URL/api/v1/workflows/$id" > /dev/null; then
    echo "  OK"
  else
    echo "  FAILED to activate $id"
    failed=1
  fi
done

if [ $failed -eq 1 ]; then
  echo "WARNING: Some workflows failed to activate. Check the errors above."
  exit 1
fi
