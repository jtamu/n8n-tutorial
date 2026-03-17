#!/bin/bash
# インポート前に、全ワークフローをn8n CLIで無効化する
# これにより import:workflow 時の FOREIGN KEY constraint エラーを回避する

set -euo pipefail

# n8nからactiveなワークフローIDのみ取得
# n8n CLIはstdoutにログメッセージを混入するため、ワークフローID形式の行のみ抽出する
ALL_IDS=$(docker compose exec -T n8n n8n list:workflow --active=true --onlyId 2>/dev/null | grep -E '^[a-zA-Z0-9_-]+$' || true)

if [ -z "$ALL_IDS" ]; then
  echo "No workflows to deactivate."
  exit 0
fi

for id in $ALL_IDS; do
  echo "Deactivating workflow $id..."
  if docker compose exec -T n8n n8n unpublish:workflow --id="$id" 2>&1; then
    echo "  OK"
  else
    echo "  FAILED to deactivate $id (continuing...)"
  fi
done

echo "All workflows deactivated."
