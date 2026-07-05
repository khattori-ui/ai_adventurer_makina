# AI冒険者マキナ

AI育成型の放置RPG。プレイヤーは「師匠」として冒険者マキナを育て、クエストに送り出します。

詳細なゲーム仕様は [SPEC.md](SPEC.md) を参照してください。

---

## セットアップ

GitHub からプログラムをコピーし、**Android または iPhone にアプリを入れて遊ぶ**までの手順です。  
（アプリを作る作業は **Mac** 上で行います。）

### 用意するもの

| もの | 用途 |
|------|------|
| Mac | ビルド・インストール作業 |
| インターネット | ダウンロード用 |
| スマホ（Android または iPhone） | 入れ先（USB ケーブル推奨） |
| [Flutter](https://docs.flutter.dev/get-started/install/macos)（stable） | アプリを作る道具 |
| Android 向け | [Android Studio](https://developer.android.com/studio) |
| iPhone 向け | Mac 用 [Xcode](https://apps.apple.com/app/xcode)（App Store） |

初回だけ、ターミナル（Mac の「ターミナル.app」）で次を実行し、エラーがないか確認します。

```bash
flutter doctor
```

iPhone でシミュレータを使う場合は、Xcode → **Settings → Platforms** で **iOS** をダウンロードしてください。

---

### 手順1：GitHub からコピーする

ターミナルで、次を **1行ずつ** Enter します。

```bash
cd ~/Desktop
git clone https://github.com/y-aoki-accel/ai_rpg_makina.git
cd ai_rpg_makina
git checkout main
git pull origin main
```

SSH で clone する場合は `git clone git@github.com:y-aoki-accel/ai_rpg_makina.git` でも構いません。

---

### 手順2：秘密の設定ファイル（`.env`）を作る

API キーなどは GitHub に載っていないため、**各自で作ります**。

```bash
cp .env.example .env
```

`.env` をメモ帳などで開き、次のように書き換えます（`your_key_here` を自分の値に）。

| 変数名 | 何に使う？ | 取り方 |
|--------|------------|--------|
| `GEMINI_API_KEY` | マキナとの会話（AI） | [Google AI Studio](https://aistudio.google.com/app/apikey) で作成 |
| `GEMINI_MODEL` | 使う AI モデル名 | 例：`gemini-2.0-flash`（example のままでも可） |
| `ANTHROPIC_API_KEY` | 別 AI（Haiku）を使うとき | [Anthropic Console](https://console.anthropic.com/)（なくても起動は可） |
| `SAVE_DATA_SECRET_KEY` | 会話メモリの暗号化 | 32文字以上の好きな英数字（チームで同じ値を使う） |

**重要：** `.env` は **GitHub にアップロードしない**でください（鍵が漏れます）。

---

### 手順3：部品をそろえる

プロジェクトのフォルダ（`ai_rpg_makina`）で実行します。

```bash
flutter pub get
```

`Got dependencies!` と出れば OK です。


---

### 手順4：スマホの準備

#### Android

1. 設定 → **端末情報** → **ビルド番号** を 7 回タップ（開発者モード）
2. **開発者向けオプション** → **USB デバッグ** をオン
3. USB で Mac と接続し、スマホで **信頼** を選ぶ

#### iPhone（実機）

1. USB で Mac と接続
2. ターミナルで `open ios/Runner.xcworkspace`（Xcode が開く）
3. 左の **Runner** → **Signing & Capabilities** → **Team** に自分の Apple ID（無料可）

#### iPhone（シミュレータ＝Mac 上の仮想 iPhone）

1. Xcode で iOS ランタイムを入れる（上記 `flutter doctor`）
2. `open -a Simulator` でシミュレータを起動

---

### 手順5：スマホに入れて起動する

接続を確認します。

```bash
flutter devices
```

一覧にスマホ名が出れば OK です。右端の ID をメモします。

**Android の例**（ID は環境ごとに違います）：

```bash
flutter run -d 2201116SR
```

**iPhone**（pod でエラーが出るときは先に 1 行実行）：

```bash
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
flutter run
```

初回は 5〜15 分かかることがあります。終わるとスマホにアプリが入り、自動で開きます。

#### 動いたかの確認

- タイトルやホーム画面が開く
- 会話を 1 回送れる（AI がエラー文でも画面が壊れなければ接続はできていることが多い）

---

### うまくいかないとき

| 症状 | 対処 |
|------|------|
| `.env` が読めない | `ai_rpg_makina` フォルダ直下にあるか確認。変更後はアプリを再起動 |
| `No devices` | ケーブル、USB デバッグ（Android）、Xcode の Team（iPhone） |
| `iOS is not installed` | Xcode → Settings → Platforms で iOS をダウンロード |
| 会話だけ動かない | `.env` の `GEMINI_API_KEY`、Google 側の利用制限・課金を確認 |

エラーが出たときは、ターミナルの **赤い行の最初の 2〜3 行** をコピーして共有すると原因を特定しやすいです。

---

### コマンドだけ知りたい人向け（まとめ）

```bash
git clone https://github.com/y-aoki-accel/ai_rpg_makina.git
cd ai_rpg_makina && flutter pub get && cp .env.example .env
# .env を編集してから
flutter devices
flutter run -d <デバイスID>
```

---

## プロジェクト構成

```
lib/
  features/          … 機能ごとの画面＋ロジック（会話・クエスト・ショップなど）
  core/              … 全機能で共有（AI・暗号化・Firestore・セーブ・GameSession）
  shared/            … モデル・マスターデータ
  providers/         … GameProvider（画面向けの窓口）
  main.dart          … 起動処理
```

新機能を追加するときは `lib/features/機能名/` に置きます。

---

## 開発の流れ

本リポジトリは **main + feature ブランチ + PR** で開発します。`main` には直接 push しません。

```
main を最新化 → feature ブランチ作成 → 開発 → PR → CI ✅ → レビュー → マージ
```

### 1. 作業開始

```bash
git checkout main
git pull upstream main
git checkout -b feature/機能名   # 例: feature/shop-ui, fix/dialog-crash
```

### 2. 開発・コミット・push

```bash
git add .
git commit -m "feat: 〇〇を追加"
git push -u upstream feature/機能名
```

**ブランチ命名**

|  prefix | 用途 |
|---|---|
| `feature/` | 新機能 |
| `fix/` | バグ修正 |
| `chore/` | CI・設定など |

**1 PR = 1 目的** を目安にブランチを切ります。

### 3. Pull Request

1. GitHub で PR を作成（**base: `main`**）
2. **CI**（`flutter analyze` + ビルド）が ✅ になることを確認
3. レビュー後にマージ

### 4. マージ後

```bash
git checkout main
git pull upstream main
```

---

## CI

`main` への push および PR で GitHub Actions が実行されます。

- `flutter analyze`
- `flutter build apk --debug`

---

## 注意事項

- **`.env` はコミットしない**（API キー漏洩防止）
- ゲーム仕様・バランス調整は [SPEC.md](SPEC.md) を参照
- テスト中はクエスト時間が 0.5 秒固定（`game_provider.dart` の `_useTestQuestDuration`）
