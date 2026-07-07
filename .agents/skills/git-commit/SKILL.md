---
name: git-commit
description: "Use when preparing git commits, staging changes, writing commit messages, checking signed commits, or pushing release branches and tags."
---

# Git commit workflow

この skill は、commit の作成・分割・署名確認・push 前確認を行うときに使う。

## 基本方針

- 明示的に「署名しない」と指示されていない限り、commit は必ず署名付きで作成する。
- commit 作成時は原則として `git commit -S` を使う。
- commit メッセージに AI / Agent / ツール名や「AIを使用した」「生成した」などの記述を含めない。
- commit は「どのツールを使ったか」ではなく「何を変更したか」を記録する。
- generated files、lockfile、framework、画像などを含める場合は、それが意図した変更か確認する。

## Commit 前の確認

1. `git status --short --branch` で作業ツリーを確認する。
2. `git diff` と `git diff --cached` で unstaged / staged の差分を確認する。
3. 変更の目的が複数ある場合は commit を分ける。
4. stage するファイルは明示的に選ぶ。`git add .` は使わない。
5. 未追跡ファイルを含める場合は、今回の commit に必要か確認する。
6. commit 前に必要な build / test / lint を実行または実行できない理由を確認する。

## Commit メッセージ

- 基本は日本語で、簡潔かつ具体的に書く。
- 日本語で不自然になる場合のみ英語表現を使ってよい。
- 内容が分かる短い件名にする。
- AI / Agent / ツール名は書かない。

良い例:

- 1.7.0 のソースを追加
- 最近の Xcode でビルドできるように修正
- commit 署名ルールを追加
- Fix null handling in payment service

悪い例:

- 修正しました
- AIで修正しました
- Cursorで修正しました
- Updated code

## 署名確認

- push 前に、push 対象の commit が署名済みで検証可能であることを確認する。
- 未署名または署名検証できない commit は push しない。
- repository に署名検証用の hook がある場合は最後の強制チェックとして残す。
- hook が未設定の場合は repository の setup script を探して有効化する。

## Push / tag の注意

- branch 名や tag 名が release version を表す場合は、その version の意味に合う commit を指しているか確認する。
- release tag は「その version のソース」を表す commit に付ける。
- build 対応や hotfix が次 version 扱いなら、branch / tag 名も次 version に揃える。
- remote branch の削除や tag の付け直しは履歴上の意味を変えるため、ユーザーの明示的な指示がある場合だけ行う。
