#!/bin/bash
# インポート前に、全ワークフローをn8n CLIで無効化する
# これにより import:workflow 時の FOREIGN KEY constraint エラーを回避する

set -euo pipefail

# n8nから全ワークフローIDを取得（list:workflowの出力形式: "ID|名前"）
ALL_IDS=$(docker compose exec -T n8n n8n list:workflow 2>/dev/null | cut -d'|' -f1)

if [ -z "$ALL_IDS" ]; then
  echo "No workflows to deactivate."
  exit 0
fi

for id in $ALL_IDS; do
  echo "Deactivating workflow $id..."
  if docker compose exec -T n8n n8n update:workflow --id="$id" --active=false 2>&1; then
    echo "  OK"
  else
    echo "  FAILED to deactivate $id (continuing...)"
  fi
done

echo "All workflows deactivated."
