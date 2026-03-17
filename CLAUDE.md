# CLAUDE.md

## ルール

- `terraform.tfvars` に変数を追加・変更する場合は、必ず `terraform.tfvars.example` にも同じ変更を反映すること

## n8n ワークフロー開発の注意点

### SplitInBatches (Loop Over Items) ノード v3
- **Output 0 = 完了（Done）**: 全バッチ処理後に発火する
- **Output 1 = ループ本体**: 各バッチのアイテムを処理するパスに接続する
- ※ 一般的な直感（0=本体, 1=完了）と逆なので注意

### Form Trigger の responseMode
- `"lastNode"`: ワークフローの最終ノードの出力をフォームに表示する。Form completion ノード (`n8n-nodes-base.form`, operation: `"completion"`) と組み合わせて使う
- `"responseNode"`: **Respond to Webhook ノード (`n8n-nodes-base.respondToWebhook`) 専用**。Form completion ノードでは `No Respond to Webhook node found` エラーになる
- Form completion ノードで完了ページを表示したい場合は `"lastNode"` を使うこと

### ワークフロー更新時の注意
- n8n UI上でユーザーが手動で変更した接続やノードがある場合、APIで更新する前に必ず最新のワークフローを取得して現状を確認すること
- ノードの出力ポートの意味が不明な場合は、推測せずドキュメントまたは実際のワークフローの接続を確認すること
