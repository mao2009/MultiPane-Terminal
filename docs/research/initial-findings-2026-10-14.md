# 初回ソース調査（2026-10-14）

> 公開README・公式仕様による予備調査。Windows実機テスト、メモリ実測、最新ソース全行監査は未実施。採用決定ではない。

## 要件
ウィンドウ → 再帰分割ツリー → ペイン → **ペインごとに独立したタブ群**。非表示タブのPTYセッションは継続。

## 既存実装
| 候補 | 公開資料から確認した構成 | 初回判断 |
|---|---|---|
| Windows Terminal | トップレベルタブの下に二分木ペイン（公式設計文書） | 必須階層と逆。無改造充足の根拠なし |
| ghostty-windows (shiweis/shiena) | タブごとに独立した分割ツリー。Win32/ConPTY/OpenGL、IME、タブ、分割、GDIタブバー | 差分開発候補。ただし階層逆 |
| GhosttyWin32 | WinUI3 TabView → Tab → SplitPanel → Pane → TerminalControl | 階層逆。WinUI3とペインごとのD3D11デバイスのコスト評価が必要 |
| Zellij 0.44.0 | 2026-03-23 Windowsネイティブ対応、レイアウト/ペイン/タブ | Windows実機でネストや代替運用により要求を満たすか要検証 |
| WezTerm / ConEmu / Tabby | 今回ソース未精査 | 保留（非対応と断定しない） |

## Ghostty Windows具体的再利用ポイント
- shiweis/ghostty-windows (fork shiena/ghostty-windows): `src/apprt/win32/Window.zig`（ウィンドウ/タブ/分割ツリー/タブライフサイクル）、`Surface.zig`（HWND・WGL・入力・IME）、`App.zig`（イベントとdispatch）。
- 共通Core: `src/terminal/`（VT・scrollback）、`src/renderer/`（OpenGL）、`src/font/`（FreeType/HarfBuzz）、`src/pty.zig`（ConPTY）、`src/termio/`（I/O）。
- Zig 0.15.2+ のWindows向けビルド手順がREADMEにある。上流への追従ではWin32 switch分岐などの競合リスクあり。
- GhosttyWin32はC++/WinRTとWinUI3、各ペインごとにGhostty Surface/D3D11デバイスを使う設計（README）。
- ライセンス表記は一次資料で追確認し、LICENSEおよび全依存ライブラリの配布条件を正式に棚卸しする（READMEの表記のみで終了としない）。

## 設計上の注意
- 既存の「タブ → 分割ツリー」をそのまま再利用して「ペインごとのタブ」を実現できるとは限らない。操作ルーティング、フォーカス、タブ移動、セッション所有関係の変更を見積もる。
- GhosttyWin32のペイン別D3D11デバイスとghostty-windowsのWGLコンテキストについて、8〜16タブ時のGPU/Private Bytesを比較する。
- シェル/ConPTY関連プロセス込みのメモリとホスト単体を分けて測定する。

## 一次資料
- https://github.com/microsoft/terminal/blob/main/doc/specs/%23532%20-%20Panes%20and%20Split%20Windows.md
- https://github.com/shiweis/ghostty-windows
- https://github.com/shiena/ghostty-windows
- https://github.com/i999rri/GhosttyWin32
- https://zellij.dev/news/remote-sessions-windows-cli/

## 次のゲート
1. ZellijをWindowsでインストールし、ペイン単位の独立タブ相当の操作が可能か手順付き検証。
2. Ghostty Windows両候補のソースで、Tab所有権とSplitNodeの変更箇所を調査・概算。
3. 同一環境でPrivate Bytes/ConPTY/子プロセス/GPUを計測。
4. 上記の証拠が揃うまで新規実装・採用決定を保留。
