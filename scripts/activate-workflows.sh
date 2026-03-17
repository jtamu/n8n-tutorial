#!/bin/bash
# インポート後に、元々activeだったワークフローをn8n CLIで有効化する
# workflows/*.json から active: true のワークフローIDを取得し、CLIで有効化する

set -euo pipefail

# 元のJSONファイルからactive: trueのワークフローIDを収集
ACTIVE_IDS=$(jq -r 'select(.active == true) | .id' workflows/*.json)

if [ -z "$ACTIVE_IDS" ]; then
  echo "No workflows to activate."
  exit 0
fi

failed=0
for id in $ACTIVE_IDS; do
  echo "Activating workflow $id..."
  if docker compose exec -T n8n n8n update:workflow --id="$id" --active=true 2>&1; then
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
