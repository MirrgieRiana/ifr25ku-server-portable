# ifr25ku-server-portable

Minecraft NeoForge サーバーをポータブルにセットアップ・管理するための Xarpite ライブラリです。

## 使い方

いずれの方法でも、適宜 `./.ifr25ku-server-portable/config.json` の編集が必要です。

### リポジトリを clone して使う

Xarpite がインストールされていない環境では、リポジトリを clone して使うことができます。

---

インストール:

```shell
git clone https://github.com/MirrgieRiana/ifr25ku-server-portable.git
```

---

使用例:

```shell
$ ./xarpite/xa 'USE("io.github.mirrgieriana:ifr25ku-server-portable:0.0.0").getProject("R2OftAxM").title'
Farmer's Delight
```

### Xarpite がインストール済みの環境で使う

リポジトリを clone せず、Maven URL から直接インポートできます。

```shell
$ xa '
    INC += "https://raw.githubusercontent.com/MirrgieRiana/ifr25ku-server-portable/refs/heads/maven/maven"
    @USE("io.github.mirrgieriana:ifr25ku-server-portable:2.0.0")
    getProject("R2OftAxM").title
'
Farmer's Delight
```

### 設定

`.ifr25ku-server-portable/config.json` に以下の項目を記述してください。

| キー                          | 説明                                     |
|-----------------------------|----------------------------------------|
| `modrinth_client_inc`       | modrinth-client ライブラリの Maven リポジトリ URL |
| `modrinth_client_location`  | modrinth-client の Maven 座標             |
| `neoforge_version`          | NeoForge のバージョン                        |
| `server_modpack_project_id` | Modrinth 上の Modpack プロジェクト ID          |
| `server_modpack_version`    | Modpack のバージョン                         |
| `modrinth_minecraft_dir`    | ローカルの Minecraft ディレクトリのパス              |

---

記述例

```json
{
  "modrinth_client_inc": "https://raw.githubusercontent.com/MirrgieRiana/modrinth-client.xa1/d7d9c6c3ba741fc8e2c12d7253ac135870f2127b/.xarpite/maven",
  "modrinth_client_location": "io.github.mirrgieriana:modrinth-client:0.0.1-SNAPSHOT",
  "neoforge_version": "21.1.217",
  "server_modpack_project_id": "ifr25ku-server-2509",
  "server_modpack_version": "2026.1.27",
  "modrinth_minecraft_dir": "/path/to/your/minecraft/directory"
}
```

### API

関数の一覧や詳細は下記のソースファイルを参照してください。

- [ifr25ku-server-portable-0.0.0.xa1](.xarpite/maven/io/github/mirrgieriana/ifr25ku-server-portable/0.0.0/ifr25ku-server-portable-0.0.0.xa1)

## MEMORY.md

AI がリポジトリの構造・内容などを把握するためのドキュメントです。
AI が管理しており、コミットもされます。

## ライセンス

MIT License (Copyright (c) 2024-2025 MirrgieRiana)
