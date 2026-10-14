# 既存製品・OSSの調査計画

2026-10-14時点の**調査対象**。以下は採用決定・機能検証済み一覧ではない。READMEや最新コード・ライセンス・リリースを再確認すること。

| 対象 | URL | 最初に確認すること |
|---|---|---|
| Windows Terminal | https://github.com/microsoft/terminal | ペインごとの独立タブが設定/改修で可能か、ConPTY/描画の再利用単位 |
| WezTerm | https://github.com/wez/wezterm | muxとGUIの関係、独立タブグループの実現性、メモリ増分 |
| ConEmu | https://github.com/Maximus5/ConEmu | ペイン/タブ管理モデル、移植コスト、保守状況 |
| Zellij | https://github.com/zellij-org/zellij | Windowsでの実動作、ネスト/設定による要求充足 |
| Tabby | https://github.com/Eugeny/tabby | 独立タブ要件と常駐コスト、拡張性 |
| Ghostty | https://github.com/ghostty-org/ghostty | VT/レンダラーの再利用可能API・ライセンス |
| ghostty-windows | https://github.com/shiena/ghostty-windows | Win32/ConPTY/IME/分割とタブのモデル、リリース成熟度 |
| GhosttyWin32 | https://github.com/i999rri/GhosttyWin32 | WinUI依存、独立タブ改修可否、GPU/メモリ |
| RoyalTerminal | https://github.com/royalapplications/RoyalTerminal | エンジン単体流用と依存コスト |
| Devolutions Terminal | https://github.com/Devolutions/devolutions-terminal | 再利用コンポーネントのAPI、依存ランタイム |

## 各候補の記録項目
- 確認日、commit/tag、対象Windows版、動作確認結果（未検証/成功/失敗）
- 無改造での要求充足：再帰分割 / ペインごとのタブ / タブ移動 / WSL / IME
- フォークした際に必要な変更点、上流追従、プラグイン/SDKの有無
- ライセンスと再配布条件（コード本体・同梱依存ごと）
- メモリ測定条件と結果、既知バグ、保守・コミュニティの状況

## 採用判定
既存利用 > 既存機能の設定/拡張 > 最小フォーク > 複数OSSの組み合わせ > 新規作成。
「対応するらしい」だけで判定せず、再現手順かソース上の根拠を残す。
