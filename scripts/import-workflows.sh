#!/bin/bash
# ワークフローをn8n REST API経由でインポートする
# CLIのimport:workflowはactiveVersionIdのFK制約エラーを起こすため、APIを使う
#
# 処理の流れ:
#   1. 全activeワークフローをdeactivate
#   2. 各ワークフローをPUT(既存)またはPOST(新規)でインポート
#   3. 元々activeだったワークフローをactivate

set -euo pipefail

CREDS_FILE="$1"

N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_API_KEY="${N8N_API_KEY:-}"

if [ -z "$N8N_API_KEY" ]; then
  echo "ERROR: N8N_API_KEY is not set"
  exit 1
fi

API_HEADER=(-H "X-N8N-API-KEY: $N8N_API_KEY" -H "Content-Type: application/json")

# credentialsのマッピングを作成
CRED_MAP=$(jq -r '[.[] | {key: "\(.type):\(.name)", value: .id}] | from_entries' "$CREDS_FILE")

# --- Step 1: Deactivate all active workflows ---
echo "=== Step 1: Deactivating active workflows ==="
RESPONSE=$(curl -s -f "${API_HEADER[@]}" "$N8N_URL/api/v1/workflows?active=true&limit=250") || {
  echo "ERROR: Failed to fetch workflows from $N8N_URL"
  exit 1
}
ACTIVE_IDS=$(echo "$RESPONSE" | jq -r '.data[].id')

if [ -n "$ACTIVE_IDS" ]; then
  for id in $ACTIVE_IDS; do
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

  # credential差し替え＋PUTで許可されたフィールドのみ抽出
  PAYLOAD=$(jq --argjson cred_map "$CRED_MAP" '
    {name, nodes, connections, settings, staticData} |
    .nodes |= map(
      if .credentials then
        .credentials |= with_entries(
          .value as $cred |
          ($cred.name // "") as $name |
          (.key + ":" + $name) as $lookup_key |
          if $cred_map[$lookup_key] then
            .value.id = $cred_map[$lookup_key]
          else
            empty
          end
        ) |
        if .credentials == {} then del(.credentials) else . end
      else
        .
      end
    )
  ' "$f")

  # 既存ワークフローの存在確認
  EXISTING=$(curl -s -w "\n%{http_code}" "${API_HEADER[@]}" "$N8N_URL/api/v1/workflows/$WORKFLOW_ID")
  HTTP_CODE=$(echo "$EXISTING" | tail -1)

  if [ "$HTTP_CODE" = "200" ]; then
    # アーカイブ済みワークフローはスキップ
    IS_ARCHIVED=$(echo "$EXISTING" | sed '$d' | jq -r '.isArchived // false')
    if [ "$IS_ARCHIVED" = "true" ]; then
      echo "  Skipping (archived): $WORKFLOW_NAME ($WORKFLOW_ID)"
      continue
    fi

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

# --- Step 3: Activate workflows ---
echo "=== Step 3: Activating workflows ==="
ACTIVATE_IDS=$(jq -r 'select(.active == true) | .id' workflows/*.json)

if [ -n "$ACTIVATE_IDS" ]; then
  for id in $ACTIVATE_IDS; do
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
  echo "  No workflows to activate."
fi

if [ $failed -eq 1 ]; then
  echo "WARNING: Some operations failed. Check the errors above."
  exit 1
fi

echo "=== Import completed successfully ==="
