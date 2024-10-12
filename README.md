# docker-azurite-study
- [azurite](https://learn.microsoft.com/ja-jp/azure/storage/common/storage-use-azurite?tabs=visual-studio%2Cblob-storage) についてDockerコンテナを利用した環境構築を試したときのメモ
- Azure歴2日とかなので間違ってること書いていることがあるかもしれない。。（；o；

## 参考サイト（Blob コンテナ関連）
- [ローカルでの Azure Storage の開発に Azurite エミュレーターを使用する | Microsoft Learn](https://learn.microsoft.com/ja-jp/azure/storage/common/storage-use-azurite?tabs=docker-hub%2Cblob-storage)
  - 公式のドキュメント（Dockerを利用しないケースの情報も含む）
  - azure-cli コンテナからの az コマンドを使用したストレージ操作の際の `ストレージアカウント` や `アカウントキー` についても[同記事内](https://learn.microsoft.com/ja-jp/azure/storage/common/storage-use-azurite?tabs=docker-hub%2Cblob-storage#well-known-storage-account-and-key)に記載がある
  - これは azurite を Docker で使う場合に限った話ではないが、コンテナ内から同一ネットワークの azurite コンテナ内(例としてBLOBコンテナ)にアクセスするには `http://azurite:10000/` のようなアクセスをする必要がある
  - 開発用の接続文字列として `UseDevelopmentStorage=true` という設定も存在するが、これは `http://localhost:10000` のような接続を想定したもの。azure-cli コンテナから azurite コンテナを操作したいといったケースの場合、長い接続文字列を指定する必要があるみたい（後述）
    - Makefile内にもハードコートしているが以下のKeyValueペア情報をセミコロンで繋げた文字列をconnection-stringオプションで渡すことになる
- [Azure Storage Explorer – クラウド ストレージ管理 | Microsoft Azure](https://azure.microsoft.com/ja-jp/products/storage/storage-explorer)
  - CLIからのコマンド操作のみでストレージを操作するのはさすがに大変なので上記のソフトウェアをインストールすると何かと便利（Microsoft公式）
    - `今回は azure-cli コンテナからのCLI操作の実行結果の確認用途でのみ使用`
  - このソフトウェアはWindowsなどDockerの外にインストール＆実行するもの。当然だがBlobストレージなどの接続文字列は↑に記載したものとは異なる点は注意
  - 2024/10現在、このソフトウェアは実行するのに`.NET 8`が必要な様子
    - Azure Storage Explorerのインストーラ起動時に併せてインストールすることが可能
- [az storage | Microsoft Learn](https://learn.microsoft.com/ja-jp/cli/azure/storage?view=azure-cli-latest)
  - Azure CLIの各コマンドについての解説が載っているページ（公式）
  - 左側のツリー構造は日本語翻訳が混じって読みづらいことになっているので[英語の同ページ](https://learn.microsoft.com/en-us/cli/azure/storage?view=azure-cli-latest)も併せてみると便利

azurite 接続文字列情報（以下KeyValueのうち必要なものを連結したものをconnection-stringオプションでセットする）
|key|value|必須or任意|
|---|---|---|
|DefaultEndpointsProtocol|http|必須|
|AccountName|devstoreaccount1|必須|
|AccountKey|Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==|必須|
|BlobEndpoint|http://azurite:10000/devstoreaccount1|任意|
|QueueEndpoint|http://azurite:10001/devstoreaccount1|任意|
|TableEndpoint|http://azurite:10002/devstoreaccount1|任意|

## Makefileの各ターゲットについて
### init
- 勉強用のコンテナ環境を起動する
- 実行後、azure-cliとazuriteの2コンテナが起動状態にあれば正常

```bash
> docker ps
CONTAINER ID   IMAGE                                     COMMAND                  CREATED          STATUS          PORTS                                  NAMES
8b887d2fbdbb   mcr.microsoft.com/azure-cli               "/bin/sh -c bash"        40 seconds ago   Up 36 seconds                                          docker-azurite-study-azure-cli-1
72c7f59c3475   mcr.microsoft.com/azure-storage/azurite   "docker-entrypoint.s…"   40 seconds ago   Up 36 seconds   0.0.0.0:10000-10002->10000-10002/tcp   docker-azurite-study-azurite-1
```

### create_blob_container
- Blobストレージに example という名前のBlobコンテナを作成する
- 実行後に`{ "created": true }`という出力が得られれば正常(ちなみに2度目の実行では既にBlobコンテナが存在するため`{ "created": false }`となる)

```bash
> make create_blob_container
docker compose exec azure-cli az storage container create \
                --name example \
                --connection-string 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;'
{
  "created": true
}
```

- このコマンドを実行後、Azure Storage Explorer でdevstoaccount1のBlob Containersを選択すると example というBlobコンテナが閲覧できるはず。

![create_blob_container_01](./images/create_blob_container_01.png)

### upload_file
- 1ファイルをBlobコンテナにアップロードする
- 以下のような出力が得られれば正常
- `azure-cliコンテナにホスト側に存在するexamplesディレクトリを/examplesというパスでマウントしている`

```bash
> make upload_file
docker compose exec azure-cli az storage blob upload \
                --connection-string 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;' \
                --container-name example \
                --file '/examples/demo.txt'
Finished[#############################################################]  100.0000%
{
  "client_request_id": "76d8f544-818b-11ef-8989-0242ac180002",
  "content_md5": "/gHOKn+6yPr67XyYKgTiKQ==",
  "date": "2024-10-03T13:29:06+00:00",
  "encryption_key_sha256": null,
  "encryption_scope": null,
  "etag": "\"0x1E42F7CF57B49A0\"",
  "lastModified": "2024-10-03T13:29:06+00:00",
  "request_id": "8cb3f27c-8c00-4873-9635-38e8589eb2c1",
  "request_server_encrypted": true,
  "version": "2024-11-04",
  "version_id": null
}
```

![upload_file_01](./images/upload_file_01.png)

## upload_folder
- `--source`で指定したパス内に含まれるファイル一式を`--destination`で指定したパス内にアップロードする
- `--destination`はblobコンテナ名を先頭として存在しないパスを記載してもOK(フォルダとして作成される)
- 以下のような出力が得られれば正常

```bash
> make upload_folder
docker compose exec azure-cli az storage blob upload-batch \
                --connection-string 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;' \
                --destination example/20241003 \
                --source '/examples/20241003'
Finished[#############################################################]  100.0000%
[
  {
    "Blob": "http://azurite:10000/devstoreaccount1/example/20241003/demo1.txt",
    "Last Modified": "2024-10-03T13:54:50+00:00",
    "Type": "text/plain",
    "eTag": "\"0x22FDC63AE5E7700\""
  },
  {
    "Blob": "http://azurite:10000/devstoreaccount1/example/20241003/demo2.txt",
    "Last Modified": "2024-10-03T13:54:50+00:00",
    "Type": "text/plain",
    "eTag": "\"0x1C55803129B0C60\""
  }
]
```

![upload_folder_01](./images/upload_folder_01.png)

![upload_folder_02](./images/upload_folder_02.png)

- `blob upload-batchコマンドではアップロード元のフォルダ構造を維持できないという情報を見かけた。。(リンクは伏す。次のupload_folder_deepターゲットで検証)`

### upload_folder_deep
- upload_folder ターゲットの検証から少し発展させ`--source`で指定したパス内に子フォルダや孫フォルダが存在する状態で前回と同じような`blob upload-batch`コマンドによるアップロードを実施
- ついでにフォルダ名について日本語を使ってみる
- 以下のような出力が得られた

```bash
> make upload_folder_deep
docker compose exec azure-cli az storage blob upload-batch \
                --connection-string 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;' \
                --destination example/20241004 \
                --source '/examples/20241004'
Finished[#############################################################]  100.0000% 100.0000%
[
  {
    "Blob": "http://azurite:10000/devstoreaccount1/example/20241004/hoge.txt",
    "Last Modified": "2024-10-04T11:02:46+00:00",
    "Type": "text/plain",
    "eTag": "\"0x1E050A265770AF0\""
  },
  {
    "Blob": "http://azurite:10000/devstoreaccount1/example/20241004/%E5%AD%90%E3%83%95%E3%82%A9%E3%83%AB%E3%83%80/child.txt",
    "Last Modified": "2024-10-04T11:02:46+00:00",
    "Type": "text/plain",
    "eTag": "\"0x20E84D1D629CE00\""
  },
  {
    "Blob": "http://azurite:10000/devstoreaccount1/example/20241004/%E5%AD%90%E3%83%95%E3%82%A9%E3%83%AB%E3%83%80/%E5%AD%AB%E3%83%95%E3%82%A9%E3%83%AB%E3%83%80/grandchild.txt",
    "Last Modified": "2024-10-04T11:02:46+00:00",
    "Type": "text/plain",
    "eTag": "\"0x24CADB48678BE40\""
  }
]
```

![upload_folder_deep_01](./images/upload_folder_deep_01.png)

![upload_folder_deep_02](./images/upload_folder_deep_02.png)

![upload_folder_deep_03](./images/upload_folder_deep_03.png)

![upload_folder_deep_04](./images/upload_folder_deep_04.png)

- `孫フォルダを含む全てのディレクトリ構造を維持したアップロードが行えることを確認できた!これは便利(^o^)`

### delete_blob_container
- 作成したblobコンテナを削除する
- azuriteでの動作確認においては中にファイルが残っていようがこれといった確認なしで削除できた(本番がどうかは不明)
- 実行後に`{ "deleted": true }`という出力が得られれば正常(ちなみに2度目の実行では既にBlobコンテナが存在しないため`{ "deleted": false }`となる)

```bash
> make delete_blob_container
docker compose exec azure-cli az storage container delete \
                --name example \
                --connection-string ''DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;'BlobEndpoint=http://azurite:10000/devstoreaccount1;'
{
  "deleted": true
}
```
