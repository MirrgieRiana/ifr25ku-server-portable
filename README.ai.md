<!--
  このファイルは AI がリポジトリの構造・内容を把握することを助けるために自動生成したものです。
  人間向けの利用ガイドではなく、AI アシスタントがコードベースを理解するための参照資料です。

  準拠リビジョン: e8db6d4fa90c7a358536ef36ba356cb22f737968
  準拠リビジョン日時: 2026-01-28 22:10:26 +0900
-->

# ifr25ku-server-portable

Minecraft NeoForge サーバーを、シェルスクリプトと独自言語 Xarpite で構築・管理するポータブルなツールキット。
Modrinth 上の Modpack 定義から Mod を自動取得してサーバーを構成し、ローカルの Modrinth App と Mod 構成を同期する機能を持つ。

| 項目 | 値 |
|---|---|
| リポジトリ | <https://github.com/MirrgieRiana/ifr25ku-server-portable.git> |
| 作者 | MirrgieRiana |
| 開発期間 | 2026-01-19 ～ 2026-01-28 (コミット履歴より) |

## 対象環境

| 項目 | 値 |
|---|---|
| Minecraft | 1.21.1 |
| Mod Loader | NeoForge 21.1.217 |
| Modpack (Modrinth) | プロジェクト ID `ifr25ku-server-2509` |
| Modpack バージョン | `2026.1.27` |
| JVM ヒープ上限 | 4 GB (`-Xmx4G`) |
| 実行プラットフォーム | Linux x86_64 (WSL2 上で開発・運用) |

## ワークフロー

```
  SERVER_MODPACK_PROJECT_ID ─┐
  SERVER_MODPACK_VERSION ────┤
                             ▼
                      ┌─────────────┐         ┌──────────────┐
                      │ install.sh  │────────► │ <target_dir> │
                      │  (Xarpite)  │         │  (サーバー)  │
                      └──────┬──────┘         └──┬───┬───┬───┘
                             │                   │   │   │
                    Modrinth API v2              │   │   │
                    から Mod を取得               │   │   │
                                                 │   │   │
                              ┌───────────────────┘   │   └──────────────────┐
                              ▼                       ▼                      ▼
                       ┌────────────┐          ┌────────────┐         ┌────────────┐
                       │  run.sh    │          │  diff.sh   │         │  sync.sh   │
                       │ サーバー起動│          │  差分確認  │         │  Mod 同期  │
                       └────────────┘          └─────┬──────┘         └──────┬─────┘
                                                     │                      │
                                                     ▼                      ▼
                                               MODRINTH_MINECRAFT_DIR (ローカル)
```

**運用手順:**

1. `./install.sh <target_dir>` — サーバーを新規構築
2. `./run.sh <target_dir>` — サーバーを起動
3. クライアント側で Mod 構成を変更した場合:
   - `./diff.sh <target_dir>` — ローカルとサーバーの Mod の差分を確認
   - `./sync.sh <target_dir>` — ローカルの Mod 構成をサーバーに反映
4. `./get-versions.sh` — Modpack の利用可能バージョンを一覧表示（バージョンアップ検討時）

## ファイル構成

```
.
├── install.sh                     サーバーインストール
├── run.sh                         サーバー起動
├── sync.sh                        Mod 同期 (ローカル → サーバー)
├── diff.sh                        Mod 差分表示 (ローカル ⇔ サーバー)
├── get-versions.sh                Modpack バージョン一覧取得
│
├── SERVER_MODPACK_PROJECT_ID      Modrinth プロジェクト ID
├── SERVER_MODPACK_VERSION         Modpack バージョン番号
├── MODRINTH_MINECRAFT_DIR         ローカル Minecraft ディレクトリパス [gitignored]
│
├── xarpite/                       Xarpite 言語処理系 (v4.98.0)
│   ├── xa                         ショートコマンドラッパー (Bash)
│   ├── xarpite                    メインランチャー (Bash)
│   ├── xarpite-update             自己アップデート (Bash)
│   ├── bin/native/xarpite         ネイティブバイナリ (ELF x86_64, 5.7 MB)
│   ├── classifier                 "linux-x86_64"
│   ├── default_engine             "native"
│   ├── version                    "4.98.0"
│   └── LICENSE                    MIT (Copyright 2024-2025 MirrgieRiana)
│
├── maven/                         Xarpite 用ローカル Maven リポジトリ
│   └── .../modrinth-client/0.0.1/
│       └── modrinth-client-0.0.1.xa1
│
├── build/                         ビルド生成物 [gitignored]
│   └── neoforge-installer/
│       └── neoforge-21.1.217-installer.jar
│
├── Untitled-1.ipynb               開発用 Jupyter Notebook
├── .gitignore
└── .gitattributes                 全ファイル -text (改行変換無効)
```

## 設定ファイル

### SERVER_MODPACK_PROJECT_ID

Modrinth 上の Modpack プロジェクト ID を1行で記述するプレーンテキスト。
現在の値: `ifr25ku-server-2509`

### SERVER_MODPACK_VERSION

対象とする Modpack のバージョン番号を1行で記述するプレーンテキスト。
現在の値: `2026.1.27`

### MODRINTH_MINECRAFT_DIR

ローカル環境の Modrinth App (Theseus) が使用する Minecraft プロファイルディレクトリの絶対パスを1行で記述するプレーンテキスト。`sync.sh` と `diff.sh` が参照する。gitignored。

現在の値の例: `/mnt/c/Users/tacti/AppData/Roaming/com.modrinth.theseus/profiles/IFR25KU Server`

パス構成から、Windows 上の Modrinth App のプロファイルを WSL2 経由で `/mnt/c/` 越しに参照していることが分かる。

## スクリプト詳細

### install.sh — サーバーインストール

```bash
./install.sh <target_dir>
```

前提コマンド: `wget`, `curl`, `java`, `unzip`

処理フロー:

1. **ディレクトリ作成** — `<target_dir>` が既存でないことを確認し、`mkdir -p` で作成。
2. **NeoForge 取得** — NeoForge 21.1.217 のインストーラー JAR を `maven.neoforged.net` からダウンロード。`build/neoforge-installer/` にキャッシュし、2回目以降はスキップ。
3. **NeoForge インストール** — `<target_dir>` 内で `java -jar ... --install-server` を実行。NeoForge サーバーの実行環境 (ライブラリ群、起動スクリプト等) が `<target_dir>` に生成される。
4. **JVM 設定** — `<target_dir>/user_jvm_args.txt` に `-Xmx4G` を追記。
5. **Mod 取得 (Xarpite)** — 以下の処理を Xarpite スクリプトとして実行:
   1. `SERVER_MODPACK_PROJECT_ID` と `SERVER_MODPACK_VERSION` を読み込み
   2. Modrinth API (`/v2/project/{id}/version`) で該当バージョンの情報を取得
   3. バージョン情報からプライマリファイル (`.mrpack`) の URL を取得してダウンロード
   4. `.mrpack` (ZIP 形式) 内の `modrinth.index.json` を `unzip -p` で標準出力に展開し、JSON パース
   5. `modrinth.index.json` に記載された全 Mod のダウンロード URL を抽出し、`wget` で `<target_dir>/mods/` に取得

### run.sh — サーバー起動

```bash
./run.sh <target_dir>
```

`<target_dir>` に `cd` した上で、NeoForge が生成した `run.sh` を `-nogui` オプション付きで `exec` する。

### sync.sh — Mod 同期

```bash
./sync.sh <target_dir>
```

前提: `MODRINTH_MINECRAFT_DIR` ファイルが存在すること。

`rsync -c -a --delete -v` でローカル (`MODRINTH_MINECRAFT_DIR` の `mods/`) からサーバー (`<target_dir>/mods/`) へ同期する。

- `-c` — チェックサムベースの差分検出 (タイムスタンプではなくファイル内容で比較)
- `-a` — アーカイブモード (パーミッション・所有者等を保持)
- `--delete` — サーバー側にのみ存在するファイルを削除 (完全ミラー)
- `-v` — 同期内容を詳細表示

### diff.sh — Mod 差分表示

```bash
./diff.sh <target_dir>
```

前提: `MODRINTH_MINECRAFT_DIR` ファイルが存在すること。

サーバーとローカルの `mods/` ディレクトリのファイル名一覧を `ls -1` で取得し、`diff -U0` で比較する。
`+` 行がローカルにのみ存在する Mod、`-` 行がサーバーにのみ存在する Mod を示す。
ヘッダ行 (`@@`, `---`, `+++`) は `grep -vE` で除去される。

終了コードは差分の有無に関わらず常に `0` (`exit 0` がハードコードされている)。

### get-versions.sh — Modpack バージョン一覧

```bash
./get-versions.sh
```

Xarpite 経由で Modrinth API の `/v2/project/{id}/version` を呼び出し、全バージョンの `version_number` フィールドを出力する。
`SERVER_MODPACK_PROJECT_ID` から ID を読み込む。引数は不要。

## Xarpite 言語処理系

Xarpite は MirrgieRiana が開発した独自プログラミング言語。このリポジトリでは、Modrinth API の呼び出しと JSON データ処理のために使用されている。

| 項目 | 値 |
|---|---|
| バージョン | 4.98.0 |
| エンジン (現在) | native (ELF 64-bit x86_64) |
| 対応エンジン | `native`, `jvm`, `node` |
| ライセンス | MIT (Copyright 2024-2025 MirrgieRiana) |
| 配布元 | Maven Central (`io.github.mirrgieriana:xarpite-bin`) |
| ソースリポジトリ | (非公開、Maven Central のメタデータから配布) |

### ランチャー構成

| ファイル | 役割 |
|---|---|
| `xarpite/xa` | ショートコマンドモードのラッパー。`XARPITE_SHORT_COMMAND=1` を設定して `xarpite` を呼び出す。`install.sh` と `get-versions.sh` が使用。 |
| `xarpite/xarpite` | メインランチャー。`--native` / `--jvm` / `--node` オプション、環境変数 `XARPITE_ENGINE`、ファイル `default_engine` の優先順で実行エンジンを決定する。 |
| `xarpite/xarpite-update` | Maven Central からの自己アップデートスクリプト。メタデータ XML から最新バージョンを取得し、tar.gz をダウンロード・展開した後、rsync の dry run を表示して確認を求める。 |

### 言語機能 (リポジトリ内のコードから観察)

| 分類 | 構文 | 説明 |
|---|---|---|
| 関数定義 | `name := args -> body` | 変数束縛と関数定義 |
| パイプ | `expr \| func` | 値をイテレーション的に次の関数に渡す |
| 変換パイプ | `expr >> FUNC` | 値全体を変換関数に渡す |
| フィルター | `>> FILTER [ _ => cond ]` | コレクションの絞り込み |
| 外部コマンド | `EXEC("cmd", "arg", ...)` | シェルコマンドの実行と出力取得 |
| ファイル読込 | `READ("path")` | ファイル内容の読み込み |
| トリム | `.&` | 文字列の前後空白除去 |
| JSON パース | `.$*` / `JSOND(str)` | 文字列を JSON としてパース |
| JSON 出力 | `JSON[indent: "  "](data)` | オブジェクトを整形 JSON 文字列に変換 |
| 文字列スライス | `str[0 ~ 40]` | 部分文字列の抽出 |
| URL エンコード | `>> URL` | URL エンコード |
| パーセントエンコード | `>> PERCENT` | パーセントエンコード |
| オブジェクト | `{ key: value, ... }` | オブジェクトリテラル |
| テンプレート文字列 | `"text $(expr) text"` | 式埋め込み文字列 |
| Raw 文字列 | `%>...<% ` | エスケープなし文字列 |
| ライブラリ | `@USE("path")` | 外部ファイルのインポート |
| 非同期実行 | `LAUNCH ( => body )` | 非同期タスクの起動 |
| 待機 | `::await()` | 非同期タスクの完了待ち |
| キャッシュ | `>> CACHE` | 結果のキャッシュ |
| 条件分岐 | `cond ? ( then ) : ( else )` | 三項演算子 |
| 配列変換 | `>> TO_ARRAY` | 配列への変換 |
| 単一要素 | `>> SINGLE` | コレクションから単一要素を取得 |
| 副作用 | `::ALSO ( => body )` | 値を保持しつつ副作用を実行 |
| プロパティアクセス | `.field` / `.field()` | オブジェクトのフィールド参照。`()` 付きで配列要素への展開 |
| 数値変換 | `.+` | 文字列を数値に変換 |
| 標準入力 | `IN` | 標準入力からの行読み込み |

## Modrinth クライアントライブラリ (modrinth-client.xa1)

パス: `maven/io/github/mirrgieriana/modrinth-client/0.0.1/modrinth-client-0.0.1.xa1`
ソース: <https://github.com/MirrgieRiana/modrinth-client.xa1> (v0.0.1 タグ)

Xarpite で記述された Modrinth API v2 のクライアントライブラリ。
内部で `curl -s` を使って `https://api.modrinth.com/v2/` にリクエストし、応答 JSON をパースして返す。
ファイルハッシュの計算には `sha1sum` コマンドを使用する。

**エクスポートされる関数:**

| 関数 | API エンドポイント | 説明 |
|---|---|---|
| `getProject(id)` | `GET /v2/project/{id}` | プロジェクト情報の取得 |
| `getProjectVersions(id)` | `GET /v2/project/{id}/version` | プロジェクトの全バージョン一覧 |
| `search(query)` | `GET /v2/search?query={query}` | プロジェクト検索 |
| `fileSearch(file)` | `GET /v2/version_file/{sha1}?algorithm=sha1` | ローカルファイルの SHA1 からバージョン情報を逆引き |

**内部ヘルパー:**

| 関数 | 説明 |
|---|---|
| `fetch(api)` | `curl -s` で API を呼び出し、応答を JSON パース (`.$*`) して返す |
| `sha1(file)` | `sha1sum` でファイルハッシュを取得し、先頭40文字を返す (`[0 ~ 40]`) |

## Jupyter Notebook (Untitled-1.ipynb)

開発・メンテナンス作業に使用される 3 セル構成の Notebook。

### セル 0 — Xarpite アップデート

Xarpite の `xarpite-update` を実行するコマンド。現在はコメントアウトされている。

### セル 1 — modrinth-client.xa1 のインストール

GitHub リポジトリ `MirrgieRiana/modrinth-client.xa1` の v0.0.1 タグから `modrinth-client.xa1` をダウンロードし、ローカル Maven ディレクトリに配置する。

注: Notebook 内のダウンロード先パスは `maven/io/github/mirrgieriana/modrinth-client.xa1/0.0.1/modrinth-client.xa1` だが、実際にリポジトリに存在するファイルのパスは `maven/io/github/mirrgieriana/modrinth-client/0.0.1/modrinth-client-0.0.1.xa1` であり、一致しない。Notebook 実行後にディレクトリ構造が再編されたものと推測される。

### セル 2 — Mod 依存関係解析

ローカルの Modrinth Minecraft ディレクトリ内の全 Mod ファイルパスを標準入力から受け取り、Modrinth API の `fileSearch` で各ファイルの SHA1 ハッシュからバージョン情報を逆引きし、プロジェクト ID と依存関係を取得する。

特徴的な実装:
- `LAUNCH` / `>> CACHE` / `::await()` を組み合わせ、API 呼び出しを並行実行
- `.cache/` ディレクトリにレスポンスを JSON ファイルとしてキャッシュし、再実行時の API 呼び出しを回避
- キャッシュキーにはファイルパスとハッシュをパーセントエンコードした文字列を使用

## Git 設定

### .gitignore

| パターン | 対象 |
|---|---|
| `/*tmp*/` | `tmp` を名前に含むディレクトリ (サーバーインスタンス `tmp1/` 等) |
| `/MODRINTH_MINECRAFT_DIR` | ローカル環境固有のパス情報 |
| `/.cache/` | Modrinth API レスポンスキャッシュ |
| `/build/` | ビルド生成物 (NeoForge インストーラー等) |
| `*.log` | ログファイル |

### .gitattributes

```
* -text
```

全ファイルに `-text` を設定し、Git による改行コード自動変換 (CRLF ↔ LF) を無効化。
Xarpite のネイティブバイナリや `.jar` ファイルを含むため、バイナリ安全な設定としている。

## 付録: ローカルサーバーインスタンス (tmp1/)

`install.sh` によって生成され、実際に起動された痕跡のあるサーバーインスタンス。
gitignored (`/*tmp*/` パターン) だがローカルに存在する。

### サーバー設定 (server.properties 抜粋)

| 設定 | 値 |
|---|---|
| gamemode | survival |
| difficulty | easy |
| max-players | 20 |
| pvp | true |
| online-mode | true |
| view-distance | 10 |
| simulation-distance | 10 |
| initial-enabled-packs | vanilla, fabric |
| server-port | 25565 |

### インストール済み Mod 一覧 (153 個)

#### Create 系 (12 個)

| Mod | ファイル名 |
|---|---|
| Create | create-1.21.1-6.0.9.jar |
| Create: Connected | create_connected-1.1.11-mc1.21.1.jar |
| Create: Dragons Plus | create-dragons-plus-1.8.6.jar |
| Create: Enchantment Industry | create-enchantment-industry-2.2.5b.jar |
| Create: Oxidized | create_oxidized-0.1.3.jar |
| Create: Vibrant Vaults | create_vibrant_vaults-0.3.2.jar |
| Create: Wrencheable Planes | create-wrencheable-planes-2.0.jar |
| Create Addition | createaddition-1.5.10.jar |
| Create Contraption Terminals | createcontraptionterminals-1.21-1.2.0.jar |
| Create Diesel Generators | createdieselgenerators-1.21.1-1.3.8.jar |
| Create Goggles | creategoggles-1.21.1-6.1.1-[NEOFORGE].jar |
| Create Railways Navigator | createrailwaysnavigator-neoforge-1.21.1-beta-0.8.5.jar |

#### Farmer's Delight 系 (17 個)

| Mod | ファイル名 |
|---|---|
| Farmer's Delight | FarmersDelight-1.21.1-1.2.9.jar |
| Ars Delight | arsdelight-2.1.9.jar |
| Aether's Delight | aethersdelight-0.1.4.2-1.21.1.jar |
| Brewin' And Chewin' | BrewinAndChewin-neoforge-4.4.2+1.21.1.jar |
| Cocktails Delight | Cocktails-Delight-1.21.1-NeoForge-1.0.4.jar |
| Corn Delight | corn_delight-1.1.8-1.21.1.jar |
| Crate Delight | cratedelight-25.09.22-1.21-neoforge.jar |
| Easter's Delight | eastersdelight-neoforge-1.21-1.0.1.jar |
| Egg Delight | EggDelight-v1.2-1.21.1.jar |
| End's Delight | ends_delight-2.5.1+neoforge.1.21.1.jar |
| Expanded Delight | expandeddelight-0.1.4.jar |
| Extra Delight | extradelight-2.6.3.jar |
| Fruits Delight | fruitsdelight-1.2.11.jar |
| More Delight | moredelight-25.07.28a-1.21-neoforge.jar |
| Ocean's Delight | oceansdelight-neoforge-1.0.3-1.21.jar |
| Seed Delight | SeedDelight-NeoForge-1.21-1.0.1 (1).jar |
| Tofu Delight | tofudelight-1.21.1-6.0.0.jar |

#### YUNG's 系 (13 個)

| Mod | ファイル名 |
|---|---|
| YUNG's API | YungsApi-1.21.1-NeoForge-5.1.6.jar |
| YUNG's Better Caves | YungsBetterCaves-1.21.1-NeoForge-3.1.4.jar |
| YUNG's Better Desert Temples | YungsBetterDesertTemples-1.21.1-NeoForge-4.1.5.jar |
| YUNG's Better Dungeons | YungsBetterDungeons-1.21.1-NeoForge-5.1.4.jar |
| YUNG's Better End Island | YungsBetterEndIsland-1.21.1-NeoForge-3.1.2.jar |
| YUNG's Better Jungle Temples | YungsBetterJungleTemples-1.21.1-NeoForge-3.1.2.jar |
| YUNG's Better Mineshafts | YungsBetterMineshafts-1.21.1-NeoForge-5.1.1.jar |
| YUNG's Better Nether Fortresses | YungsBetterNetherFortresses-1.21.1-NeoForge-3.1.5.jar |
| YUNG's Better Ocean Monuments | YungsBetterOceanMonuments-1.21.1-NeoForge-4.1.2.jar |
| YUNG's Better Strongholds | YungsBetterStrongholds-1.21.1-NeoForge-5.1.3.jar |
| YUNG's Better Witch Huts | YungsBetterWitchHuts-1.21.1-NeoForge-4.1.1.jar |
| YUNG's Bridges | YungsBridges-1.21.1-NeoForge-5.1.1.jar |
| YUNG's Cave Biomes | YungsCaveBiomes-1.21.1-NeoForge-3.1.1.jar |

#### Macaw's 系 (13 個)

| Mod | ファイル名 |
|---|---|
| Macaw's Bridges | mcw-bridges-3.1.1-mc1.21.1neoforge.jar |
| Macaw's Doors | mcw-doors-1.1.2-mc1.21.1neoforge.jar |
| Macaw's Fences and Walls | mcw-mcwfences-1.2.1-mc1.21.1neoforge.jar |
| Macaw's Furniture | mcw-furniture-3.4.1-mc1.21.1neoforge.jar |
| Macaw's Holidays | mcw-holidays-1.1.2-mc1.21.1neoforge.jar |
| Macaw's Lights and Lamps | mcw-lights-1.1.5-mc1.21.1neoforge.jar |
| Macaw's Paths and Pavings | mcw-mcwpaths-1.1.1-mc1.21.1neoforge.jar |
| Macaw's Stairs | mcw-mcwstairs-1.0.2-mc1.21.1neoforge.jar |
| Macaw's Windows | mcw-mcwwindows-2.4.2-mc1.21.1neoforge.jar |
| Macaw's Paintings | mcw-paintings-1.0.5-1.21.1neoforge.jar |
| Macaw's Roofs | mcw-roofs-2.3.2-mc1.21.1neoforge.jar |
| Macaw's Trapdoors | mcw-trapdoors-1.1.5-mc1.21.1neoforge.jar |
| Macaw's Biomes O' Plenty | mcwbiomesoplenty-neoforge-1.21.1-1.5.jar |

#### Aether 系 (7 個)

| Mod | ファイル名 |
|---|---|
| The Aether | aether-1.21.1-1.5.10-neoforge.jar |
| Deep Aether | deep_aether-1.21.1-1.1.4.jar |
| Aether Villages | AetherVillages-1.21.1-1.0.8-neoforge.jar |
| Aether Ruined Portal | aether-ruined-portal-3.4.jar |
| Explore Ruins Aether | explore_ruins_aether-1.0.0-neoforge-1.21.1.jar |
| Farmer's Cutting the Aether | farmers-cutting-the-aether-1.21.1-1.0-neoforge.jar |
| Flower Seeds 2 Aether | Flower Seeds 2 Aether-1.21.1-3.1.0.jar |

#### ストレージ・自動化系 (7 個)

| Mod | ファイル名 |
|---|---|
| Applied Energistics 2 | appliedenergistics2-19.2.17.jar |
| MEGA Cells (AE2 アドオン) | megacells-4.10.1.jar |
| Refined Storage | refinedstorage-neoforge-2.0.0.jar |
| Refined Storage: Curios Integration | refinedstorage-curios-integration-1.0.0.jar |
| Refined Storage: Mekanism Integration | refinedstorage-mekanism-integration-1.1.1.jar |
| Storage Drawers | StorageDrawers-neoforge-1.21.1-13.11.4.jar |
| Tom's Simple Storage | toms_storage-1.21-2.2.4.jar |

#### 技術系 (4 個)

| Mod | ファイル名 |
|---|---|
| Mekanism | Mekanism-1.21.1-10.7.17.83.jar |
| CC: Tweaked (ComputerCraft) | cc-tweaked-1.21.1-forge-1.117.0.jar |
| CC:C Bridge (CC ↔ Create 連携) | cccbridge-mc1.21.1-v1.7.2-neoforge.jar |
| Magitech | magitech-1.1.3.jar |

#### 魔術系 (3 個)

| Mod | ファイル名 |
|---|---|
| Ars Nouveau | ars_nouveau-1.21.1-5.11.1.jar |
| Iron's Spells 'n Spellbooks | irons_spellbooks-1.21.1-3.15.2.jar |
| Modonomicon | modonomicon-1.21.1-neoforge-1.117.4.jar |

#### 大型コンテンツ (4 個)

| Mod | ファイル名 |
|---|---|
| DivineRPG | divinerpg-1.10.9.3.jar |
| DivineRPG Compat | divinerpg_compat-1.0.4.jar |
| Advent of Ascension (AoA3) | AoA3-1.21.1-3.7.16.1.jar |
| Grimoire of Gaia 4 | GrimoireOfGaia4-1.21.1-6.0.0-alpha.9.jar |

#### ワールド生成・構造物系 (8 個)

| Mod | ファイル名 |
|---|---|
| Biomes O' Plenty | BiomesOPlenty-neoforge-1.21.1-21.1.0.13.jar |
| TerraBlender | TerraBlender-neoforge-1.21.1-4.1.0.8.jar |
| Deeper and Darker | deeperdarker-neoforge-1.21-1.3.4.jar |
| Dungeon Crawl | DungeonCrawl-NeoForge-1.21-2.3.15.jar |
| Mo' Structures | mostructures-neoforge-1.6.0+1.21.1.jar |
| Repurposed Structures | repurposed_structures-7.5.17+1.21.1-neoforge.jar |
| Repurposed Structures FD Compat | repurposed_structures_farmers_delight_compat_v7.jar |
| Resource World | resource_world-1.5.1-bugfix-1.21.1-neoforge.jar |

#### 食料・農業系 (8 個)

| Mod | ファイル名 |
|---|---|
| TofuCraftReload | tofucraft-1.21.1-12.18.3.0.jar |
| Caupona | Caupona-1.21.1-0.5.3.jar |
| Botany Pots | botanypots-neoforge-1.21.1-21.1.41.jar |
| Botany Pots Tiers | botanypotstiers-neoforge-1.21.1-7.0.10.jar |
| Flower Seeds 2 | flowerseeds2-1.21.1-3.2.2.jar |
| Harvest with ease | harvest-with-ease-neoforge-1.21-9.4.0.jar |
| Productive Bees | productivebees-1.21.1-13.13.0.jar |
| The Bumblezone | the_bumblezone-7.11.8+1.21.1-neoforge.jar |

#### 装飾・建築系 (8 個)

| Mod | ファイル名 |
|---|---|
| BiblioCraft | bibliocraft-1.21.1-1.6.2.jar |
| Handcrafted | handcrafted-neoforge-1.21.1-4.0.3.jar |
| Bedspreads | bedspreads-neoforge-7.0.0+1.21.1.jar |
| Rechiseled | rechiseled-1.2.1-neoforge-mc1.21.jar |
| Supplementaries | supplementaries-1.21-3.5.19-neoforge.jar |
| Bits 'n' Bobs | bits_n_bobs-0.0.43.jar |
| D&Desires | DnDesires-1.21.1-2.2d-BETA.jar |
| Feature Recycler | Feature-Recycler-neoforge-2.0.0.jar |

#### ユーティリティ・UI 系 (16 個)

| Mod | ファイル名 |
|---|---|
| JourneyMap | journeymap-neoforge-1.21.1-6.0.0-beta.53.jar |
| EMI | emi-1.1.22+1.21.1+neoforge.jar |
| Roughly Enough Items (REI) | RoughlyEnoughItems-16.0.799-neoforge.jar |
| Just Enough Items (JEI) | jei-1.21.1-neoforge-19.27.0.340.jar |
| Jade | Jade-1.21.1-NeoForge-15.10.5.jar |
| Mouse Tweaks | MouseTweaks-neoforge-mc1.21-2.26.1.jar |
| Carry On | carryon-neoforge-1.21.1-2.2.4.4.jar |
| Camera | camera-neoforge-1.21.1-1.0.21.jar |
| Disenchanting Table | disenchanting_table-merged-1.21.1-5.0.2.jar |
| Polymorph | polymorph-neoforge-1.1.0+1.21.1.jar |
| Gravestone | gravestone-neoforge-1.21.1-1.0.35.jar |
| Leaves Be Gone | LeavesBeGone-v21.1.0-1.21.1-NeoForge.jar |
| Sophisticated Backpacks | sophisticatedbackpacks-1.21.1-3.25.24.1499.jar |
| Sophisticated Core | sophisticatedcore-1.21.1-1.4.1.1459.jar |
| Comforts | comforts-neoforge-9.0.5+1.21.1.jar |
| Server Translation API | server_i18n_api-1.4.2-1.21.3-neoforge.jar |

#### 村人・取引系 (2 個)

| Mod | ファイル名 |
|---|---|
| Easy Villagers | easy-villagers-neoforge-1.21.1-1.1.41.jar |
| Trading Floor | trading_floor-3.0.15.jar |

#### 乗り物系 (2 個)

| Mod | ファイル名 |
|---|---|
| Immersive Aircraft | immersive_aircraft-1.4.1+1.21.1-neoforge.jar |
| Aviator Dreams Reloaded | aviator-dreams-reloaded-neoforge-1.2.1+1.21.1.jar |

#### 外部連携 (1 個)

| Mod | ファイル名 |
|---|---|
| Discord Integration | dcintegration-neoforge-3.0.7-1.21.jar |

#### ライブラリ・前提 Mod (26 個)

| Mod | ファイル名 |
|---|---|
| Forgified Fabric API | forgified-fabric-api-0.116.7+2.2.0+1.21.1.jar |
| Architectury API | architectury-13.0.8-neoforge.jar |
| Cloth Config | cloth-config-15.0.140-neoforge.jar |
| Curios API | curios-neoforge-9.5.1+1.21.1.jar |
| GeckoLib | geckolib-neoforge-1.21.1-4.8.3.jar |
| oωo Lib | owo-lib-neoforge-0.12.15.5-beta.1+1.21.jar |
| Puzzles Lib | PuzzlesLib-v21.1.39-1.21.1-NeoForge.jar |
| Bookshelf | bookshelf-neoforge-1.21.1-21.1.80.jar |
| Patchouli | Patchouli-1.21.1-92-NEOFORGE.jar |
| Guide-Me | guideme-21.1.15.jar |
| Player Animation Lib | player-animation-lib-forge-2.0.4+1.21.1.jar |
| Resourceful Lib | resourcefullib-neoforge-1.21-3.0.12.jar |
| GlitchCore | GlitchCore-neoforge-1.21.1-2.1.0.0.jar |
| Moonlight Lib | moonlight-1.21-2.29.16-neoforge.jar |
| Cobweb | cobweb-neoforge-1.21-1.4.0.jar |
| Mono Lib | monolib-neoforge-1.21.1-2.1.0.jar |
| Mysterious Mountain Lib | mysterious_mountain_lib-1.2.14-1.21.1.jar |
| Addons Lib | addonslib-neoforge-1.21.1-1.10.jar |
| Prickle | prickle-neoforge-1.21.1-21.1.11.jar |
| Cryonic Config | cryonicconfig-neoforge-1.0.0+mc1.21.11.jar |
| SuperMartijn642's Config Lib | supermartijn642configlib-1.1.8-neoforge-mc1.21.jar |
| SuperMartijn642's Core Lib | supermartijn642corelib-1.1.20-neoforge-mc1.21.jar |
| Midnight Lib | midnightlib-neoforge-1.9.2+1.21.1.jar |
| Kotlin for Forge | kotlinforforge-5.11.0-all.jar |
| Bagus Lib | bagus_lib-1.21.1-13.24.0.jar |
| Fusion | fusion-1.2.12-neoforge-mc1.21.1.jar |

#### 互換・統合 Mod (2 個)

| Mod | ファイル名 |
|---|---|
| GT Ore Growth AoA/Divine Support | gt_ore_growth_aoa_divine_support-1.0.0-neoforge-1.21.1.jar |
| Farmers Cutting the Aether | farmers-cutting-the-aether-1.21.1-1.0-neoforge.jar |

#### サーバー独自 Mod (1 個)

| Mod | ファイル名 |
|---|---|
| ifr25ku | ifr25ku-31.31.0-alpha.4+neoforge.jar |

Modpack 名と同名の独自 Mod。サーバー固有のカスタマイズや設定変更を担っていると推測される。

## コミット履歴

全 25 コミット (2026-01-19 ～ 2026-01-28)。
メッセージが `1` のみのコミットが 19 件を占め、内容を示すメッセージを持つのは以下の 6 件:

| ハッシュ (短縮) | 日時 | メッセージ |
|---|---|---|
| `6427690` | 01-19 22:14 | init |
| `e0d5a3d` | 01-20 14:55 | Update NeoForge installer command to include server option |
| `b2efad1` | 01-22 08:40 | Add -Xmx4G to user_jvm_args.txt if missing |
| `851c579` | 01-25 14:34 | Add .gitattributes to configure text file handling |
| `07c070f` | 01-27 11:35 | Add Xarpite |
| `2487faf` | 01-27 18:56 | Update .gitignore to ignore temporary files |

日本語メッセージのコミットが 1 件:
- `ba52bb1` (01-27 18:58): ディレクトリ引数を追加し、スクリプト内のパスを動的に変更
