# claude-code-kickoff

Claude Code で新しいアプリを作るときのプロジェクトのひな形。
技術スタックには依存しない。進め方の型（計画書 → 仕様書 → 実装、ドキュメントの書き分け、作業ジャーナル）だけを入れてある。
技術を選んだら、そのプロジェクトの中で必要なファイルを作る。

## 使い方

最初に一度だけ、このリポジトリを好きな場所に clone する。

```bash
git clone https://github.com/htanijiri/claude-code-kickoff.git
```

プロジェクトを作るときは、clone したフォルダの `new-project.sh` を実行する。

```bash
# チャットで計画書（BRIEF.md）を作ってから
./claude-code-kickoff/new-project.sh my-app --brief ~/Downloads/BRIEF.md --start
# → ~/Developer/my-app を作り、そのまま Claude Code を開いて /kickoff を実行する
```

作成先の既定は `~/Developer/<プロジェクト名>`。変えるときは `--dir` で親フォルダを指定する。
`--start` を付けない場合は、あとで `cd ~/Developer/my-app && claude "/kickoff"` を実行する（起動後に `/kickoff` と打ってもよい）。

| オプション | 内容 |
|---|---|
| `--brief <ファイル>` | 計画書を `brief/BRIEF.md` としてコピーする。省略した場合は、あとから手で置く |
| `--start` | 作成後にそのまま Claude Code を開き、`/kickoff` を実行する（`--brief` が必要） |
| `--dir <フォルダ>` | 作成先の親フォルダ（既定は `~/Developer`） |
| `--no-git` | `git init` しない |

プレースホルダー `{{PROJECT_NAME}}`（プロジェクト名）と `{{CREATED_AT}}`（作成日）は、スクリプトが置き換える。
CLAUDE.md などにある `<!-- -->` の部分は、`/kickoff` で Claude が BRIEF を読んで埋める。

## 前提
- macOS（スクリプトは BSD の `sed -i ''` を使っている）
- `jq`（ジャーナル hook が使う）：`brew install jq`

## 流れ
1. **チャットで相談する**（Claude.ai / ChatGPT）。結果を計画書 `BRIEF.md` にまとめる。
2. **`new-project.sh` でプロジェクトを作る。** BRIEF は `brief/` に置かれる。
3. **`/kickoff`**：Claude が BRIEF を読み、決まっていないことを**チャットで質問する**。答えるとすべて決まった状態になる。
4. Claude が CLAUDE.md・README・TASKS・HISTORY と、**今回作る範囲のすべての仕様書**を書き、一度だけ確認を頼む。
5. **仕様書を読んで、チャットで「OK」と伝える。** 読むのは各仕様書の「👤 ユーザーが確認するところ」だけでよい（「🤖 実装メモ」は Claude 用）。読む順は `docs/specs/README.md` の一覧のとおり。
6. OK のあとは、Claude が仕様書を `合意済み` にして、**すべての仕様書を最後まで実装する**。仕様書ごとに合意や開始の指示を出す必要はない。途中で止まるのは、確認した内容を変える必要が出たときと、ユーザーにしかできない作業が必要なときだけ。
7. 作業のたびに `journal/` に記録が残る（hook で自動記録し、書き忘れがあれば差し戻す）。

ユーザーが出す指示は、3 の質問への回答と、5 の「OK」だけ。

## template/ の中身

| ファイル | 役割 |
|---|---|
| `CLAUDE.md` | Claude への指示。BRIEF から始める手順、進め方（まとめて合意し、最後まで実装する）、ドキュメントの書き分け、ジャーナルのルール |
| `README.md` | アプリの概要・設計の前提・構成・セットアップ |
| `TASKS.md` | フェーズ別のタスク、決定事項ログ（チャットで決めたこと、合意の記録） |
| `brief/` | 計画書（`BRIEF.md`）の置き場。README 以外は gitignore |
| `docs/specs/` | 機能ごとの仕様書（`NNN-機能名.md`）。「ユーザーが確認するところ」と「実装メモ」に分かれている。README に読み方・一覧・運用ルール |
| `docs/TECH_NOTES.md` | 技術選定の理由、ハマりどころ、効かなかったこと |
| `docs/HISTORY.md` | 主要な設計判断とその理由、開発の時系列 |
| `docs/DEPLOY.md` | デプロイ・動作確認・ロールバックの手順 |
| `.claude/skills/kickoff/` | `/kickoff` スキル。BRIEF を読む → 未決事項を質問する → 仕様書をすべて書く → 合意をもらう → 最後まで実装する、の手順 |
| `.claude/settings.json`, `.claude/hooks/` | 作業ジャーナルを自動記録する hook |
| `.gitignore` | brief/・journal/・秘密情報・ビルド出力など、よく使う除外設定 |

## テンプレートを直すとき
- hook は `local-llm-transcriber` のものを元にしている。どちらかで改善したら、もう一方にも反映する。
- ジャーナルの見出し（`### 指示（原文）` など）を変えるときは、`journal-stop.sh` の確認処理も直す。

## ライセンス
[MIT License](LICENSE)
