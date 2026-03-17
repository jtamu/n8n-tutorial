backup-credentials:
	docker compose exec -T n8n n8n export:credentials --all 2>/dev/null | sed -n '/^\[/,$$p' > credentials.json
	@echo "Credentials backed up to credentials.json"

import:
	git pull && \
	./scripts/deactivate-workflows.sh && \
	mkdir -p /tmp/n8n-import && \
	for f in workflows/*.json; do \
		./scripts/replace-credentials.sh credentials.json "$$f" > "/tmp/n8n-import/$$(basename $$f)"; \
	done && \
	docker cp /tmp/n8n-import n8n:/tmp/n8n-import && \
	docker compose exec -T n8n n8n import:workflow --separate --input=/tmp/n8n-import/ && \
	rm -rf /tmp/n8n-import && \
	./scripts/activate-workflows.sh

ssh:
	gcloud compute ssh n8n-server --zone=us-west1-b --project=my-n8n-project-jtamu
