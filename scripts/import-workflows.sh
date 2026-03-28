#!/bin/bash
# ワークフローをn8n REST API経由でインポートする
# CLIのimport:workflowはactiveVersionIdのFK制約エラーを起こすため、
# 既存ワークフローの更新にはAPIを使う
# 新規ワークフローはCLIでインポートする（IDを保持するため）

set -euo pipefail

N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_API_KEY="${N8N_API_KEY:-}"

if [ -z "$N8N_API_KEY" ]; then
  echo "ERROR: N8N_API_KEY is not set"
  exit 1
fi

API_HEADER=(-H "X-N8N-API-KEY: $N8N_API_KEY" -H "Content-Type: application/json")

# --- Import workflows via API ---
echo "=== Importing workflows ==="
failed=0
for f in workflows/*.json; do
  WORKFLOW_ID=$(jq -r '.id' "$f")
  WORKFLOW_NAME=$(jq -r '.name' "$f")

  # 既存ワークフローの存在確認
  EXISTING=$(curl -s -w "\n%{http_code}" "${API_HEADER[@]}" "$N8N_URL/api/v1/workflows/$WORKFLOW_ID")
  HTTP_CODE=$(echo "$EXISTING" | tail -1)
  EXISTING_BODY=$(echo "$EXISTING" | sed '$d')

  if [ "$HTTP_CODE" = "200" ]; then
    # アーカイブ済みワークフローはスキップ
    IS_ARCHIVED=$(echo "$EXISTING_BODY" | jq -r '.isArchived // false')
    if [ "$IS_ARCHIVED" = "true" ]; then
      echo "  Skipping (archived): $WORKFLOW_NAME ($WORKFLOW_ID)"
      continue
    fi
  fi

  if [ "$HTTP_CODE" = "200" ]; then
    # 既存ワークフローのcredentialsをノードに反映（サーバー側が正）
    PAYLOAD=$(jq '{name, nodes, connections, settings, staticData}' "$f")
    PAYLOAD=$(echo "$PAYLOAD" | jq --argjson existing "$EXISTING_BODY" '
      ($existing.nodes | map({key: .id, value: .credentials}) | from_entries) as $existing_creds |
      .nodes |= map(
        .id as $nid |
        if $existing_creds[$nid] then
          .credentials = $existing_creds[$nid]
        else
          del(.credentials)
        end
      )
    ')

    # 既存 → PUT で更新
    echo "  Updating: $WORKFLOW_NAME ($WORKFLOW_ID)..."
    RESULT=$(curl -s -w "\n%{http_code}" -X PUT "${API_HEADER[@]}" \
      -d "$PAYLOAD" "$N8N_URL/api/v1/workflows/$WORKFLOW_ID")
    RESULT_CODE=$(echo "$RESULT" | tail -1)
    if [ "$RESULT_CODE" = "200" ]; then
      echo "    OK"
    else
      RESULT_BODY=$(echo "$RESULT" | sed '$d')
      echo "    FAILED (HTTP $RESULT_CODE): $RESULT_BODY"
      failed=1
    fi
  else
    # 新規 → CLIでインポート（IDを保持するため）
    CONTAINER_PATH="/home/node/workflows/$(basename "$f")"
    echo "  Creating (CLI): $WORKFLOW_NAME ($WORKFLOW_ID)..."
    if docker exec n8n n8n import:workflow --input="$CONTAINER_PATH" 2>&1; then
      echo "    OK"
    else
      echo "    FAILED"
      failed=1
    fi
  fi
done

if [ $failed -eq 1 ]; then
  echo "WARNING: Some operations failed. Check the errors above."
  exit 1
fi

echo "=== Import completed successfully ==="
