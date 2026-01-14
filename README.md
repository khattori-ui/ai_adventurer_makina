AI冒険者マキナ (AI Adventurer Makina)
AIと育てる冒険者RPG - Flutter製アプリケーション

このマニュアルは、Macのターミナル操作に慣れていない方でも起動できるように書かれています。

🍎 1. 始める前の準備 (Prerequisites)
以下のソフトがMacに入っているか確認してください。

Xcode (App Storeからインストール)

Flutter SDK (公式サイトからインストール)

🚀 2. 基本の起動手順 (How to Start)
ターミナル(Terminal)アプリを開き、以下の順番で操作してください。

手順①：デスクトップに移動する
まずは、ゲームのデータを分かりやすい場所（デスクトップ）に置く準備をします。 ターミナルに以下のコマンドを貼り付けてEnterを押してください。

Bash

cd ~/Desktop
手順②：ゲームをダウンロードする（初回のみ）
GitHubからデスクトップにデータをコピーします。

Bash

git clone https://github.com/y-aoki-accel/ai_rpg_makina.git
※完了すると、デスクトップに ai_rpg_makina というフォルダが作成されます。

手順③：フォルダに移動する
ダウンロードしたフォルダの中に入ります。

Bash

cd ai_rpg_makina
手順④：部品をダウンロードする
アプリに必要なライブラリを取り込みます。

Bash

flutter pub get
手順⑤：アプリを起動する
Macアプリとして起動します。

Bash

flutter run -d macos
※ 「✓ Built ...」 と表示されたら成功です！Dockにアイコンが跳ねていないか確認してください。

🆘 3. エラーが出たときの対処法 (Troubleshooting)
もし赤い文字のエラーが出ても、以下の手順で解決できます。

ケースA：「CocoaPods not installed」と出る
Macアプリを作るための裏方ツールが足りていません。以下を実行してください。 ※パスワードを聞かれますが、画面には表示されません。入力してEnterを押してください。

Bash

sudo gem install cocoapods
ケースB：「Error installing ffi」と出る（一番多いエラー）
Macに元々入っているRubyのバージョンが古いため、エラーになります。 以下の**「3段階の修復コマンド」**を順番に実行してください。

1. 道具箱の場所をリセットする

Bash

sudo xcode-select --reset
2. 利用規約に同意する

Bash

sudo xcodebuild -license accept
3. バージョンを指定して部品を入れる

Bash

sudo gem install ffi -v 1.15.5
これが成功したら、もう一度 sudo gem install cocoapods を行い、起動コマンドを試してください。

🌐 どうしても動かないときは... (Fallback)
Macアプリとしての起動が難しい場合、Google Chrome（ブラウザ）で起動することができます。これなら難しい設定は不要です。

Bash

flutter run -d chrome