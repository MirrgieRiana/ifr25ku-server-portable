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

## API

関数の一覧や詳細は下記のソースファイルを参照してください。

- [ifr25ku-server-portable-0.0.0.xa1](.xarpite/maven/io/github/mirrgieriana/ifr25ku-server-portable/0.0.0/ifr25ku-server-portable-0.0.0.xa1)

## ライセンス

MIT License (Copyright (c) 2024-2025 MirrgieRiana)
