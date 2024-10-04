CONNECTION_STRING='DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;'
BLOB_CONTAINER_NAME=example

init:
	docker compose up -d

create_blob_container:
	docker compose exec azure-cli az storage container create \
		--name $(BLOB_CONTAINER_NAME) \
		--connection-string $(CONNECTION_STRING)

upload_file:
	docker compose exec azure-cli az storage blob upload \
		--connection-string $(CONNECTION_STRING) \
		--container-name $(BLOB_CONTAINER_NAME) \
		--file '/examples/demo.txt'

upload_folder:
	docker compose exec azure-cli az storage blob upload-batch \
		--connection-string $(CONNECTION_STRING) \
		--destination $(BLOB_CONTAINER_NAME)/20241003 \
		--source '/examples/20241003'

upload_folder_deep:
	docker compose exec azure-cli az storage blob upload-batch \
		--connection-string $(CONNECTION_STRING) \
		--destination $(BLOB_CONTAINER_NAME)/20241004 \
		--source '/examples/20241004'

down:
	docker compose down
