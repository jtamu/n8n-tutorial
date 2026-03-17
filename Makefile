backup-credentials:
	docker compose exec -T n8n n8n export:credentials --all 2>/dev/null | sed -n '/^\[/,$$p' > credentials.json
	@echo "Credentials backed up to credentials.json"

import:
	git pull && \
	mkdir -p /tmp/n8n-import && \
	for f in workflows/*.json; do \
		./scripts/replace-credentials.sh credentials.json "$$f" > "/tmp/n8n-import/$$(basename $$f)"; \
	done && \
	docker cp /tmp/n8n-import n8n:/tmp/n8n-import && \
	failed=0; \
	for f in /tmp/n8n-import/*.json; do \
		name=$$(basename "$$f"); \
		if ! docker compose exec -T n8n n8n import:workflow --input="/tmp/n8n-import/$$name" 2>&1; then \
			echo "FAILED: $$name"; \
			failed=1; \
		fi; \
	done; \
	rm -rf /tmp/n8n-import; \
	[ $$failed -eq 0 ]

ssh:
	gcloud compute ssh n8n-server --zone=us-west1-b --project=my-n8n-project-jtamu
