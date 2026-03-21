<!--
  このファイルは AI がリポジトリの構造・内容を把握することを助けるためのものです。
  人間向けの利用ガイドではなく、AI アシスタントがコードベースを理解するための参照資料です。
-->

# ifr25ku-server-portable

Minecraft NeoForge サーバーをポータブルにセットアップ・管理するための Xarpite ライブラリ。
Modrinth 上の Modpack 定義から Mod を自動取得してサーバーを構成し、ローカルの Modrinth App と Mod 構成を同期する機能を持つ。
GitHub raw URL 経由で Xarpite の Maven ライブラリとしてインポートできる。

| 項目 | 値 |
|---|---|
| リポジトリ | <https://github.com/MirrgieRiana/ifr25ku-server-portable.git> |
| 作者 | MirrgieRiana |
| Maven 座標 | `io.github.mirrgieriana:ifr25ku-server-portable` |

## 対象環境

| 項目 | 値 |
|---|---|
| Minecraft | 1.21.1 |
| Mod Loader | NeoForge (バージョンは config.json で設定) |
| Modpack (Modrinth) | プロジェクト ID `ifr25ku-server-2509` |
| JVM ヒープ上限 | 4 GB (`-Xmx4G`) |
| 実行プラットフォーム | Linux x86_64 (WSL2 上で開発・運用) |

## ファイル構成

```
.
├── .xarpite/maven/io/github/mirrgieriana/
│   └── ifr25ku-server-portable/0.0.0/
│       └── ifr25ku-server-portable-0.0.0.xa1   メインライブラリ
│
├── .ifr25ku-server-portable/                    [gitignored]
│   └── config.json                              設定ファイル
│
├── .github/workflows/
│   └── maven-publish.yml                        Maven publish ワークフロー
│
├── build.gradle.kts                             Gradle ビルド設定
├── settings.gradle.kts                          Gradle プロジェクト設定
├── gradlew                                      Gradle Wrapper (実行可能)
├── gradlew.bat                                  Gradle Wrapper (Windows)
├── gradle/wrapper/                              Gradle Wrapper ファイル
│
├── xarpite/                                     Xarpite 言語処理系 (v4.105.0)
│   ├── xa                                       ショートコマンドラッパー
│   ├── xarpite                                  メインランチャー
│   ├── xarpite-update                           自己アップデート
│   ├── bin/native/xarpite                       ネイティブバイナリ (ELF x86_64)
│   └── LICENSE                                  MIT License
│
├── libs/fsaintjacques/semver-tool/              セマンティックバージョニング比較ツール
│
├── CLAUDE.md                                    AI コンテキスト設定
├── MEMORY.md                                    AI 用リポジトリ参照資料 (このファイル)
├── README.md                                    利用ガイド
├── .gitignore
└── .gitattributes                               全ファイル -text (改行変換無効)
```

## 設定ファイル (.ifr25ku-server-portable/config.json)

gitignored。各環境で個別に作成する必要がある。

| キー | 説明 |
|---|---|
| `modrinth_client_inc` | modrinth-client ライブラリの Maven リポジトリ URL |
| `modrinth_client_location` | modrinth-client の Maven 座標 |
| `neoforge_version` | NeoForge のバージョン |
| `server_modpack_project_id` | Modrinth 上の Modpack プロジェクト ID |
| `server_modpack_version` | Modpack のバージョン |
| `modrinth_minecraft_dir` | ローカルの Minecraft ディレクトリのパス |

## メインライブラリ (ifr25ku-server-portable-0.0.0.xa1)

Xarpite で記述されたサーバー管理ライブラリ。`@USE` でインポートするとオブジェクトとしてエクスポートされる。

`projectDir` はプロジェクトルートを指し、環境変数 `IFR25KU_SERVER_PORTABLE_HOME` があればそれを、なければ `PWD` を使用する。

### エクスポートされる関数

| 関数 | 説明 |
|---|---|
| `getConfig()` | config.json を読み込んで返す (LAZY) |
| `getModrinthClient()` | Modrinth API クライアントを返す (LAZY) |
| `getSha1(filePath)` | ファイルの SHA-1 ハッシュを返す |
| `cached(name, initializer)` | ファイルベースのキャッシュ機構 |
| `getProject(projectId)` | Modrinth プロジェクト情報を取得 (キャッシュ付き) |
| `getDefaultModpackVersions()` | Modpack の全バージョンを昇順で返す (キャッシュ付き) |
| `getVersionFromFile(filePath)` | ファイルから Modrinth バージョン情報を取得 (キャッシュ付き) |
| `install(targetDir, modpackVersion)` | NeoForge サーバーと Mod をインストール |
| `diffToDefaultMinecraftDir(targetDir)` | ローカルとサーバーの Mod 差分を表示 |
| `syncFromDefaultMinecraftDir(targetDir)` | ローカルの Mod をサーバーに同期 |
| `getModDependencies(minecraftDir)` | 全 Mod の依存関係を並行取得 |
| `getRunCommand(targetDir)` | サーバー起動コマンドを返す |

### 内部ユーティリティ (@{ } ブロック内)

| 関数 | 説明 |
|---|---|
| `isFile(path)` | ファイルの存在確認 |
| `exists(path)` | パスの存在確認 |
| `mkdirs(path)` | ディレクトリの再帰作成 |
| `readJson(path)` | JSON ファイルの読み込み |
| `writeJson(path, data)` | JSON ファイルの書き込み |

## Maven Publish ワークフロー

`v*.*.*` 形式のタグが push されると GitHub Actions が実行される。

1. main ブランチと maven ブランチを別々にチェックアウト
2. maven ブランチの既存リポジトリ内容を `main/build/maven-repo/` にコピー
3. `./gradlew publish` で新バージョンを publish (既存の maven-metadata.xml とマージ)
4. 結果を maven ブランチに書き戻してコミット・プッシュ

コミットメッセージ: `<version> (<short-hash>)`

### Gradle 設定

| 項目 | 値 |
|---|---|
| groupId | `io.github.mirrgieriana` |
| artifactId | `ifr25ku-server-portable` |
| version | 環境変数 `VERSION` (デフォルト `0.0.0`) |
| 成果物 | `.xa1` ファイル |
| 出力先 | `build/maven-repo/` |

## ブランチ構成

| ブランチ | 用途 |
|---|---|
| `main` | ソースコード |
| `maven` | Maven リポジトリ (ワークフローが自動管理) |

## Xarpite 言語処理系

| 項目 | 値 |
|---|---|
| バージョン | 4.105.0 |
| エンジン | native (ELF 64-bit x86_64) |
| 対応エンジン | `native`, `jvm`, `node` |
| ライセンス | MIT (Copyright 2024-2025 MirrgieRiana) |
| 配布元 | Maven Central (`io.github.mirrgieriana:xarpite-bin`) |

## Modrinth クライアントライブラリ

config.json の `modrinth_client_inc` と `modrinth_client_location` で指定される外部ライブラリ。
`getModrinthClient()` で遅延取得される。

| 関数 | 説明 |
|---|---|
| `getProject(id)` | プロジェクト情報の取得 |
| `getProjectVersions(id)` | プロジェクトの全バージョン一覧 |
| `getVersion(id)` | バージョン情報の取得 |
| `search(query)` | プロジェクト検索 |
| `fileSearch(file)` | ファイルの SHA1 からバージョン情報を逆引き |

## .gitignore

| パターン | 対象 |
|---|---|
| `.idea/` | JetBrains IDE |
| `build/` | Gradle ビルド生成物 |
| `.gradle/` | Gradle キャッシュ |
| `.ifr25ku-server-portable/` | 設定ファイル (環境依存) |
| `/*tmp*/` | テスト用サーバーインスタンス |
