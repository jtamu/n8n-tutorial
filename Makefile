backup-credentials:
	docker compose exec -T n8n n8n export:credentials --all 2>/dev/null | sed -n '/^\[/,$$p' > credentials.json
	@echo "Credentials backed up to credentials.json"

import:
	git pull && \
	./scripts/import-workflows.sh credentials.json

ssh:
	gcloud compute ssh n8n-server --zone=us-west1-b --project=my-n8n-project-jtamu
