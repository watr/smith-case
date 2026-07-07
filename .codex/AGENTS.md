## Personal Rules

### Commit policy
- 明示的に「署名しない」と指示されていない限り、commit は必ず署名付きで作成すること
- commit メッセージに AI / Agent / ツール名や「AIを使用した」「生成した」などの記述を含めないこと
- `git push` 前に、push 対象の commit が署名済みで検証可能であることを確認すること
- commit 作成・分割・メッセージ・署名確認の具体手順は `~/.codex/skills/git-commit/SKILL.md` に従うこと

### Git hooks
- repository に署名検証用の pre-push hook がある場合は有効化して使うこと

### Branch workflow
- version 番号の付いた作業では、対象 version の branch 上で作業すること
- main で version branch より先行して作業しないこと
- 作業開始前に現在 branch を確認し、必要なら対象 version branch に切り替えてから変更すること
