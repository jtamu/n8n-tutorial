#!/bin/bash
# ワークフローをn8n REST API経由でインポートする
# CLIのimport:workflowはactiveVersionIdのFK制約エラーを起こすため、APIを使う
#
# 処理の流れ:
#   1. 全activeワークフローをdeactivate
#   2. 各ワークフローをPUT(既存)またはPOST(新規)でインポート
#   3. Step 1で無効化したワークフローを再度activate

set -euo pipefail

N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_API_KEY="${N8N_API_KEY:-}"

if [ -z "$N8N_API_KEY" ]; then
  echo "ERROR: N8N_API_KEY is not set"
  exit 1
fi

API_HEADER=(-H "X-N8N-API-KEY: $N8N_API_KEY" -H "Content-Type: application/json")

# --- Step 1: Deactivate all active workflows ---
echo "=== Step 1: Deactivating active workflows ==="
RESPONSE=$(curl -s -f "${API_HEADER[@]}" "$N8N_URL/api/v1/workflows?active=true&limit=250") || {
  echo "ERROR: Failed to fetch workflows from $N8N_URL"
  exit 1
}
DEACTIVATED_IDS=$(echo "$RESPONSE" | jq -r '.data[].id')

if [ -n "$DEACTIVATED_IDS" ]; then
  for id in $DEACTIVATED_IDS; do
    echo "  Deactivating $id..."
    curl -s -X PATCH "${API_HEADER[@]}" \
      -d '{"active": false}' "$N8N_URL/api/v1/workflows/$id" > /dev/null
  done
  echo "  Done."
else
  echo "  No active workflows."
fi

# --- Step 2: Import workflows via API ---
echo "=== Step 2: Importing workflows ==="
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

  # PUTで許可されたフィールドのみ抽出（credentialsはサーバー側で管理するため含めない）
  PAYLOAD=$(jq '
    {name, nodes, connections, settings, staticData} |
    .nodes |= map(del(.credentials))
  ' "$f")

  if [ "$HTTP_CODE" = "200" ]; then
    # 既存 → PUT で更新
    echo "  Updating: $WORKFLOW_NAME ($WORKFLOW_ID)..."
    RESULT=$(curl -s -w "\n%{http_code}" -X PUT "${API_HEADER[@]}" \
      -d "$PAYLOAD" "$N8N_URL/api/v1/workflows/$WORKFLOW_ID")
  else
    # 新規 → POST で作成（IDを含める）
    PAYLOAD_WITH_ID=$(echo "$PAYLOAD" | jq --arg id "$WORKFLOW_ID" '. + {id: $id}')
    echo "  Creating: $WORKFLOW_NAME ($WORKFLOW_ID)..."
    RESULT=$(curl -s -w "\n%{http_code}" -X POST "${API_HEADER[@]}" \
      -d "$PAYLOAD_WITH_ID" "$N8N_URL/api/v1/workflows")
  fi

  RESULT_CODE=$(echo "$RESULT" | tail -1)
  if [ "$RESULT_CODE" = "200" ] || [ "$RESULT_CODE" = "201" ]; then
    echo "    OK"
  else
    RESULT_BODY=$(echo "$RESULT" | sed '$d')
    echo "    FAILED (HTTP $RESULT_CODE): $RESULT_BODY"
    failed=1
  fi
done

# --- Step 3: Re-activate workflows that were active before import ---
echo "=== Step 3: Re-activating previously active workflows ==="

if [ -n "$DEACTIVATED_IDS" ]; then
  for id in $DEACTIVATED_IDS; do
    echo "  Activating $id..."
    if curl -s -X PATCH "${API_HEADER[@]}" \
      -d '{"active": true}' "$N8N_URL/api/v1/workflows/$id" > /dev/null; then
      echo "    OK"
    else
      echo "    FAILED to activate $id"
      failed=1
    fi
  done
else
  echo "  No workflows to re-activate."
fi

if [ $failed -eq 1 ]; then
  echo "WARNING: Some operations failed. Check the errors above."
  exit 1
fi

echo "=== Import completed successfully ==="
