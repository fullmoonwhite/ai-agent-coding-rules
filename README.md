GlobalRules
AI エージェントとの共同開発を効率化するための、汎用ルールセットです。
人間と AI が同一のルール・同一の構造・同一の探索方法で作業することを目的としています。
詳細は GLOBAL_RULES.md（日本語）または GLOBAL_RULES_EN.md（英語）を参照してください。

使い方

このリポジトリをクローンまたはダウンロードして、エージェントのルールフォルダに配置する
generate_index.ps1 を各プロジェクトにコピーして使用する（詳細は GLOBAL_RULES.md Section 6）
エージェントの起動時に rules/CORE.md を読み込ませる


update_lang_index.ps1
rules/lang/ に新しい言語ルールファイルを追加したとき、関連するインデックスファイルを自動更新するスクリプトです。
追加条件:

rules/lang/XX_core.md と rules/lang/XX_examples.md の両方が存在すること
GLOBAL_RULES.md への追記は XX_RULES.md が存在する場合のみ

実行方法:
powershell# このスクリプトと同じフォルダで実行（パラメータ省略可）
.\update_lang_index.ps1

# フォルダを明示する場合
.\update_lang_index.ps1 -RulesDir "path\to\GlobalRules"
更新されるファイル:
ファイル更新内容rules/CORE.mdReference Guide テーブルに言語行を追加GLOBAL_RULES.mdSection 12-1 テーブルに言語行を追加GLOBAL_RULES_EN.mdSection 12-1 テーブルに言語行を追加

ライセンス
MIT License — 自由に使用・改変・再配布できます。
