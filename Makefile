CONNECTION_STRING_BASE='DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;'
BLOB_CONTAINER_CONNECTION_STRING='$(CONNECTION_STRING_BASE)BlobEndpoint=http://azurite:10000/devstoreaccount1;'
TABLE_STORAGE_CONNECTION_STRING='$(CONNECTION_STRING_BASE)TableEndpoint=http://azurite:10002/devstoreaccount1;'
BLOB_CONTAINER_NAME=example

init:
	docker compose up -d

# blob コンテナ関連
create_blob_container:
	docker compose exec azure-cli az storage container create \
		--name $(BLOB_CONTAINER_NAME) \
		--connection-string $(BLOB_CONTAINER_CONNECTION_STRING)

upload_file:
	docker compose exec azure-cli az storage blob upload \
		--connection-string $(BLOB_CONTAINER_CONNECTION_STRING) \
		--container-name $(BLOB_CONTAINER_NAME) \
		--file '/examples/demo.txt'

upload_folder:
	docker compose exec azure-cli az storage blob upload-batch \
		--connection-string $(BLOB_CONTAINER_CONNECTION_STRING) \
		--destination $(BLOB_CONTAINER_NAME)/20241003 \
		--source '/examples/20241003'

upload_folder_deep:
	docker compose exec azure-cli az storage blob upload-batch \
		--connection-string $(BLOB_CONTAINER_CONNECTION_STRING) \
		--destination $(BLOB_CONTAINER_NAME)/20241004 \
		--source '/examples/20241004'

delete_blob_container:
	docker compose exec azure-cli az storage container delete \
		--name $(BLOB_CONTAINER_NAME) \
		--connection-string $(BLOB_CONTAINER_CONNECTION_STRING)

# table storage 関連


down:
	docker compose down
