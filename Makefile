import:
	git pull && \
	docker compose exec n8n n8n import:workflow --separate --input=./workflows/
