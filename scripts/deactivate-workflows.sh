#!/bin/bash
# インポート前に、現在activeな全ワークフローをn8n CLIで無効化する
# これにより import:workflow 時の FOREIGN KEY constraint エラーを回避する

set -euo pipefail

# n8nから現在activeなワークフローIDを取得
ACTIVE_IDS=$(docker compose exec -T n8n n8n export:workflow --all 2>/dev/null | jq -r '.[] | select(.active == true) | .id')

if [ -z "$ACTIVE_IDS" ]; then
  echo "No active workflows to deactivate."
  exit 0
fi

for id in $ACTIVE_IDS; do
  echo "Deactivating workflow $id..."
  if docker compose exec -T n8n n8n update:workflow --id="$id" --active=false 2>&1; then
    echo "  OK"
  else
    echo "  FAILED to deactivate $id (continuing...)"
  fi
done

echo "All workflows deactivated."
