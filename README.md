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

---

## 🏗 設計図 (Architecture)
このアプリは「MVVM + Providerパターン」で作られています。

```mermaid
graph TD
    %% スタイル定義
    classDef view fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef viewmodel fill:#fff9c4,stroke:#fbc02d,stroke-width:2px;
    classDef model fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;
    classDef service fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px;

    subgraph "View (見た目)"
        HS[Home Screen]:::view
        QS[Quest List Screen]:::view
        SS[Shop Screen]:::view
        CS[Conversation Screen]:::view
    end

    subgraph "ViewModel (脳みそ)"
        GP[GameProvider]:::viewmodel
    end

    subgraph "Model (データ定義)"
        Makina[Makina Class]:::model
        Item[Item Class]:::model
        Quest[Quest Class]:::model
    end

    subgraph "Service & Data (機能・保存)"
        AI[AI Service]:::service
        Store[Storage Service]:::service
        QData[Quest Data]:::service
    end

    %% 関係性
    HS -->|操作・監視| GP
    QS -->|操作・監視| GP
    SS -->|操作・監視| GP
    CS -->|操作・監視| GP

    GP -->|状態変更| Makina
    GP -->|アイテム操作| Item
    GP -->|クエスト参照| Quest

    GP -->|会話生成| AI
    GP -->|セーブ・ロード| Store
    GP -->|マスタデータ取得| QData