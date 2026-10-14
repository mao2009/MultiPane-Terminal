# Windows実機メモリ計測手順

## 前提
Windows PowerShell 5.1以上。これは**測定用スクリプトのみ**であり、ターミナルの実測値はまだありません。

1. 候補のターミナルを通常どおり起動し、タスクマネージャー等でホストPIDを確認する。
2. PowerShellでリポジトリルートへ移動。
3. 1タブ時・4タブ時・8タブ時など状態ごとに別名CSVを記録する。

```powershell
.\tools\Measure-Terminal.ps1 -HostProcessId 12345 -DurationSeconds 60 -IntervalSeconds 1 -OutputCsv .\results\one-tab.csv
```

同じシェル/フォント/ウィンドウ寸法/DPI/スクロールバックを指定する。各状態3回以上行う。

## CSVの解釈
1行=1時刻・1プロセス。PrivateBytes/WorkingSetBytesはバイト。CpuSecondsCumulativeはCPU累積秒数なので時刻間の差から利用率を計算する。同じ時刻のプロセス行を集約すればツリーの概算になるが、共有ページや外部conhostの多重/未計上に注意。

## 制約と追加計測
- ConPTYホストやWSL VMがプロセスの直系子孫でない場合は捕捉できない。別途Process Explorer / VM情報等で確認。
- GPUメモリはこのスクリプトでは取得しない。Windowsパフォーマンスカウンタまたは専用ツールを併用する。
- PID再利用/プロセス終了直後の取りこぼしがあり得る。
- 子シェルの作業量、WSLのメモリ、画面条件、GPU設定が揃わない比較は不公平。
- 外部のCIホストではユーザー実機のWindows描画・IME・GPUコストは評価できない。
- `results/`は.gitignore対象。必要な集約結果のみ文書に転記する。

## 実測までの判定
#3は測定コード追加をもって完了扱いにしない。各候補の実測値と比較が出てから完了。
