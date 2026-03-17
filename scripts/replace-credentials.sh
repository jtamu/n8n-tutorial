#!/bin/bash
# ワークフローJSON内のcredential参照を、現在のn8nインスタンスのcredentialで差し替える
# 使い方: ./scripts/replace-credentials.sh <credentials.json> <workflow.json>
#   credentials.json: n8n export:credentials --all の出力
#   workflow.json: ワークフローJSONファイル
# 出力: 差し替え済みのワークフローJSONをstdoutに出力

set -euo pipefail

CREDS_FILE="$1"
WORKFLOW_FILE="$2"

# credentialsのマッピングを作成: { "type:name": "id", ... }
CRED_MAP=$(jq -r '[.[] | {key: "\(.type):\(.name)", value: .id}] | from_entries' "$CREDS_FILE")

# ワークフロー内の各ノードのcredential参照を差し替え、インポート不要なフィールドを除去
jq --argjson cred_map "$CRED_MAP" '
  {id, name, nodes, connections, settings, staticData, pinData, active, meta, tags} |
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
' "$WORKFLOW_FILE"
