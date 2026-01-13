arkdown
# AI冒険者マキナ (AI Adventurer Makina)
AIと育てる冒険者RPG - Flutter製アプリケーション

このマニュアルは、Macのターミナル操作に慣れていない方でも起動できるように書かれています。

---

## 🍎 1. 始める前の準備 (Prerequisites)
以下のソフトがMacに入っているか確認してください。
1.  **Xcode** (App Storeからインストール)
2.  **Flutter SDK** (公式サイトからインストール)

---

## 🚀 2. 基本の起動手順 (How to Start)

ターミナル(Terminal)アプリを開き、以下の順番で操作してください。

### 手順①：フォルダに移動する
まず「場所」を指定します。
1. `cd` と入力し、**スペースキーを1回**押します。
2. このフォルダをターミナル画面に**ドラッグ＆ドロップ**します。
3. **Enterキー**を押します。

```bash
cd [フォルダをここにドラッグ]

```

### 手順②：部品をダウンロードする

アプリに必要なライブラリを取り込みます。

```bash
flutter pub get

```

### 手順③：アプリを起動する

Macアプリとして起動します。

```bash
flutter run -d macos

```

※ **「✓ Built ...」** と表示されたら成功です！Dockにアイコンが跳ねていないか確認してください。

---

## 🆘 3. エラーが出たときの対処法 (Troubleshooting)

もし赤い文字のエラーが出ても、以下の手順で解決できます。

### ケースA：「CocoaPods not installed」と出る

Macアプリを作るための裏方ツールが足りていません。以下を実行してください。
※パスワードを聞かれますが、画面には表示されません。入力してEnterを押してください。

```bash
sudo gem install cocoapods

```

### ケースB：「Error installing ffi」と出る（一番多いエラー）

Macに元々入っているRubyのバージョンが古いため、エラーになります。
以下の**「3段階の修復コマンド」**を順番に実行してください。

**1. 道具箱の場所をリセットする**

```bash
sudo xcode-select --reset

```

**2. 利用規約に同意する**

```bash
sudo xcodebuild -license accept

```

**3. バージョンを指定して部品を入れる**

```bash
sudo gem install ffi -v 1.15.5

```

これが成功したら、もう一度 `sudo gem install cocoapods` を行い、起動コマンドを試してください。

### ケースC：「No pubspec.yaml file found」と出る

**「場所」が間違っています。**
ターミナルがフォルダの中にいません。手順①の `cd` コマンドからやり直してください。

---

## 🌐 どうしても動かないときは... (Fallback)

Macアプリとしての起動が難しい場合、Google Chrome（ブラウザ）で起動することができます。これなら難しい設定は不要です。

```bash
flutter run -d chrome

```