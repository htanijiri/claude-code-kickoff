#!/usr/bin/env bash
# テンプレート（template/）から新しいプロジェクトを作る。
#
#   ./new-project.sh <プロジェクト名> [--brief <計画書.md>] [--start] [--dir <作成先の親フォルダ>] [--no-git]
#
#   例: ./new-project.sh my-app
#       ./new-project.sh my-app --brief ~/Downloads/BRIEF.md --start
#
# 作成先の既定は ~/Developer/<プロジェクト名>。既にあれば何もせずに終了する。
# --brief を渡すと、そのファイルを brief/BRIEF.md としてコピーする（あとから手で置いてもよい）。
# --start を付けると、作成後にそのまま Claude Code を開いて /kickoff を実行する（--brief が必要）。
set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)/template"

usage() {
  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-1}"
}

NAME=""
BRIEF=""
PARENT="$HOME/Developer"
GIT_INIT=1
START=0

while [ $# -gt 0 ]; do
  case "$1" in
    --brief) BRIEF="${2:?--brief には計画書のパスを指定してください}"; shift 2 ;;
    --dir)   PARENT="${2:?--dir には作成先の親フォルダを指定してください}"; shift 2 ;;
    --no-git) GIT_INIT=0; shift ;;
    --start) START=1; shift ;;
    -h|--help) usage 0 ;;
    -*) echo "エラー: 不明なオプション $1" >&2; usage ;;
    *)
      [ -z "$NAME" ] || { echo "エラー: プロジェクト名は1つだけ指定してください" >&2; exit 1; }
      NAME="$1"; shift ;;
  esac
done

[ -n "$NAME" ] || usage

# フォルダ名と sed の置換に使うので、使える文字を絞る
if ! [[ "$NAME" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  echo "エラー: プロジェクト名は英数字・ . _ - だけにしてください（例: my-app）" >&2
  exit 1
fi

if [ "$START" -eq 1 ] && [ -z "$BRIEF" ]; then
  echo "エラー: --start には --brief が必要です（/kickoff は brief/BRIEF.md から始めるため）" >&2
  exit 1
fi

if [ -n "$BRIEF" ] && [ ! -f "$BRIEF" ]; then
  echo "エラー: 計画書が見つかりません: $BRIEF" >&2
  exit 1
fi

[ -d "$PARENT" ] || { echo "エラー: 作成先の親フォルダがありません: $PARENT" >&2; exit 1; }
DEST="$(cd "$PARENT" && pwd)/$NAME"
if [ -e "$DEST" ]; then
  echo "エラー: 既に存在します: $DEST" >&2
  exit 1
fi

# ジャーナル hook が jq を使う。なくてもプロジェクトは作れるので警告だけ出す
command -v jq >/dev/null 2>&1 || echo "警告: jq がありません。ジャーナル hook が動かないので brew install jq してください。" >&2

# テンプレートをコピー（隠しファイル込み）
mkdir -p "$DEST"
cp -R "$TEMPLATE_DIR/." "$DEST/"
find "$DEST" -name .DS_Store -delete

# プレースホルダーを置き換える
TODAY="$(date '+%Y-%m-%d')"
{ grep -rlE '\{\{(PROJECT_NAME|CREATED_AT)\}\}' "$DEST" || true; } | while IFS= read -r f; do
  sed -i '' -e "s/{{PROJECT_NAME}}/$NAME/g" -e "s/{{CREATED_AT}}/$TODAY/g" "$f"
done

chmod +x "$DEST"/.claude/hooks/*.sh

if [ -n "$BRIEF" ]; then
  cp "$BRIEF" "$DEST/brief/BRIEF.md"
fi

if [ "$GIT_INIT" -eq 1 ]; then
  # git の既定ブランチ名（master）ではなく、GitHub などの標準に合わせて main にする
  git -C "$DEST" init -q -b main
  if [ -z "$(git -C "$DEST" config user.email || true)" ]; then
    echo "警告: git の名前とメールアドレスが未設定です。コミットする前に git config --global user.name / user.email を設定してください。" >&2
  fi
fi

echo "✅ 作成しました: $DEST"

if [ "$START" -eq 1 ]; then
  echo "Claude Code を開いて /kickoff を実行します..."
  cd "$DEST"
  exec claude "/kickoff"
fi

echo ""
echo "次の手順:"
if [ -z "$BRIEF" ]; then
  echo "  1. 計画書を $DEST/brief/BRIEF.md に置く"
  echo "  2. cd $DEST && claude \"/kickoff\""
else
  echo "  cd $DEST && claude \"/kickoff\""
fi
