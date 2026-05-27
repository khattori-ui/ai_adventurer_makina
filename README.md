# AI冒険者マキナ

AI育成型の放置RPG。プレイヤーは「師匠」として冒険者マキナを育て、クエストに送り出します。

詳細なゲーム仕様は [SPEC.md](SPEC.md) を参照してください。

---

## セットアップ

### 必要環境

- Flutter SDK（stable）
- Android Studio / Xcode（各プラットフォーム向け）

### 初回セットアップ

```bash
git clone git@github.com:y-aoki-accel/ai_rpg_makina.git
cd ai_rpg_makina
flutter pub get
cp .env.example .env
```

`.env` に API キー等を設定してください（`.env` は Git に含めません）。

| 変数 | 説明 |
|---|---|
| `GEMINI_API_KEY` | [Google AI Studio](https://aistudio.google.com/app/apikey) で取得 |
| `SAVE_DATA_SECRET_KEY` | セーブデータ暗号化用の任意文字列 |

### 実行

```bash
flutter run
```

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
