# ghostty-windows Window.zig の実コード一次監査

調査日: 2026-10-14
対象: https://github.com/shiena/ghostty-windows/blob/main/src/apprt/win32/Window.zig
方法: GitHub公開ソースを読み取り。ビルド・Windows実機検証は未実施。コミットSHAは未固定、実装開始前に固定すること。

## コード上の確証
- ファイル冒頭のコメント: WindowはトップレベルHWND、Surface子HWNDをタブとして管理。
- `MAX_TABS: usize = 64`、`tab_count`、`tab_trees: [64]SplitTree(Surface)`、`tab_active_surface: [64]*Surface`、`active_tab`がWindowに直接所属。
- `addTab()`: Surfaceを生成・初期化し、そのSurfaceをルートとしたSplitTreeを1個生成、tab_treesへ挿入。
- `closeTabByIndex()`: 該当SplitTreeをdeinitし、Surfaceをrefcount経由で解放、後続のタブ配列を詰める。最終タブを閉じるとWindowにWM_CLOSE。
- `layoutSplits()`: `tab_trees[active_tab]`だけを走査し配置・表示、zoomed状態も同じツリー単位。
- `findTabIndex()` / `findHandle()`: SurfaceからWindow単位のtab indexを特定。フォーカス/通知系にも関連が予想される。

## 求める変更の影響範囲
現状: Window → Tab[0..63] → SplitTree → Surface
要求: Window → SplitTree → Pane → TabGroup → Surface

単なるTabBarの増設では済まない。以下の所有権・イベント変更が必要。
1. `tab_trees`と`active_tab`のWindow直下所有を解消し、PaneにTabGroupを所属させる。
2. SplitTreeはSurfaceではなくPaneを葉にする設計（既存SplitTree型を再利用できるか要検証）。
3. Tab追加・切替・並び替え・削除をアクティブPane対象にする。
4. 最終タブ終了時のウィンドウ終了条件を、最後のPaneの最後のTabに変更する。
5. タブBar描画、HitTest、ドラッグ先、IME/キー入力フォーカスをペイン局所座標で扱う。
6. 非表示SurfaceのPTY出力消費を継続し、表示・リサイズだけ抑制する。
7. ペイン削除とSurface refcountの二重解放/リークをテストする。

## 省メモリの注意
- タブを増やしても描画コンテキストが各Surface単位で生成されるかどうかをSurface.zigとrendererまで追跡する。
- 仮に各SurfaceがGPUコンテキストを保持すれば非表示タブも追加メモリを消費する。削減する場合は再表示コストと正しさを測る。
- 固定長64スロットは上限とWindow構造体サイズのトレードオフ。可変長化が必ずしも小メモリとは限らない。
- 上流との差分が大きくなりそうなため、実機検証と工数見積もり前にはフォークを決定しない。

## 次に読む箇所
`Surface.zig`のinit/deinitとWM_SIZE/IME、`App.zig`のイベント配送、`split_tree.zig`の所有権/iterator、renderer/PTYの非表示動作。ソース・タグ固定後に変更箇所を列挙する。
