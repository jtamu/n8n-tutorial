import:
	git pull && \
	./scripts/import-workflows.sh

ssh:
	gcloud compute ssh n8n-server --zone=us-west1-b --project=my-n8n-project-jtamu
