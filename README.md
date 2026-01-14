# AI冒険者マキナ (AI Adventurer Makina)
AIと育てる冒険者RPG - Flutter製アプリケーション

このマニュアルは、Macのターミナル操作に慣れていない方でも、迷わずゲームを起動できるように書かれています。

---

## 🍎 1. 始める前の準備 (Prerequisites)
以下のソフトがMacに入っているか確認してください。
1. Xcode (App Storeからインストール)
2. Flutter SDK (公式サイトからインストール)

---

## 🚀 2. 基本の起動手順 (How to Start)

ターミナル(Terminal)アプリを開き、以下の順番で操作してください。

### 手順①：デスクトップに移動する
まず、ゲームを保存する場所を「デスクトップ」にします。
```bash
cd ~/Desktop
```

### 手順②：ゲームをダウンロードする（初回のみ）
GitHubからデスクトップにデータをコピーします。
```bash
git clone https://github.com/y-aoki-accel/ai_rpg_makina.git
```

※完了すると、デスクトップに `ai_rpg_makina` というフォルダが作成されます。

### 手順③：フォルダに移動する
ダウンロードしたゲームのフォルダの中に入ります。
```bash
cd ai_rpg_makina
```

### 手順④：部品をダウンロードする
アプリに必要なライブラリを自動で取り込みます。
```bash
flutter pub get
```

### 手順⑤：アプリを起動する
Mac専用アプリとして起動します。
```bash
flutter run -d macos
```

※ 「✓ Built ...」 と表示されたら成功です！Dockでアイコンが跳ねていないか確認してください。

---

## 🆘 3. エラーが出たときの対処法 (Troubleshooting)
もし赤い文字のエラーが出た場合は、以下の手順で解決できます。

### ケースA：「CocoaPods not installed」と出る
Macアプリを作るためのツールが足りていません。以下を実行してください。  
※パスワードを聞かれますが、画面には表示されません。入力してEnterを押してください。
```bash
sudo gem install cocoapods
```

### ケースB：「Error installing ffi」と出る（よくあるエラー）
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

これが終わったら、もう一度 `sudo gem install cocoapods` を実行してから、起動コマンド（手順⑤）を試してください。

---

## 🌐 どうしても動かないときは... (Fallback)
Macアプリとしての起動が難しい場合、Google Chrome（ブラウザ）で起動することができます。
```bash
flutter run -d chrome
```