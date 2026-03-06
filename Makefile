import:
	git pull && \
	docker compose exec n8n n8n import:workflow --separate --input=./workflows/

export:
	docker compose exec n8n n8n export:workflow --all --separate --output=./workflows/
