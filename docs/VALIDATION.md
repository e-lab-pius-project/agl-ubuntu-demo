# 検証記録

本リポジトリで実行した検査と、元のリポジトリで確認された結果を区別します。

## 本リポジトリ

2026-11-06、Ubuntu 24.04 / WSL2のテスト環境で、本リポジトリのスクリプトを検査しました。

| 検査 | 結果 |
|---|---|
| 全シェルスクリプトのbash構文 | PASS |
| KVM指定・SSH転送の127.0.0.1限定・モニター引数の転送 | PASS（QEMUをテスト用プロセスへ置換） |
| 同じデータフォルダーの二重起動拒否・DISPLAY未設定の拒否 | PASS |
| 固定イメージのSHA-256照合・qcow2作成・qemu-img check | PASS |
| 再実行による既存変更の保持・破損カーネルの拒否 | PASS |
| ホスト設定スクリプトのroot実行拒否 | PASS |

続けてUbuntu 26.04.1 / QEMU 10.2.1 / KVMの実機で確認しました。

| 検査 | 結果 |
|---|---|
| 全シェルスクリプトのbash構文・起動引数のテスト | PASS |
| configure-desktop.shの6設定と読み返し | PASS（別D-Busセッションと一時設定領域を使用） |
| prepare.shの固定ファイル照合・展開・qcow2作成 | PASS |
| check-preparation.shの再実行・変更保持・破損拒否 | PASS |
| AGL 21.93.0の起動・ゲストへのSSH・KUKSAサービス起動 | PASS |
| 仮想can0がvcanであること・ゲストの失敗サービス0件 | PASS |
| 画面の向き調整・Continue操作・ホーム画面の描画 | PASS（[取得画面](agl-home.png)） |
| 実QEMU稼働中の二重起動拒否 | PASS |
| poweroffによる正常終了・QEMU終了 | PASS |

この時点の起動試験はGPU有効化前の2D構成です。既存の別のAGL環境を止めないため、一時コピーしたstart.shのSSH転送ポートを2222から2223へ変更しました。試験には新しい作業用ディスクを使い、USB-CANは渡していません。既存のAGL環境の設定は変更していません。

この日の検査には、Ubuntuの新規インストールからsetup-host.shを通す全工程、WindowsからのRDP接続、CAN通信は含みません。grdctlの操作体系と既存のRDP共有サービスの有効状態は実機で確認しています。仮想CAN通信の追加検証は次節に記録します。

## 2026-11-07：GPU有効化とPIUSパネルのCAN表示

Ubuntu Desktop 26.04.1、AMD Ryzen 5 7530U内蔵Radeon、QEMU 10.2.1 / KVM、仮想CPU 2個・RAM 2 GiBで確認しました。起動設定を `virtio-vga-gl`・`gtk,gl=on` に切り替え、AGL側で `virgl: yes` と `virgl (AMD Radeon Graphics …)` を確認しています。既存の作業ディスクと起動スクリプトは切替前に退避しました。

[pius-meter-panel](https://github.com/e-lab-pius-project/pius-meter-panel)を表示し、Ubuntuの仮想CANからcannelloni TCPでAGLへ入力しました。CANプロバイダーの最小転送間隔は同プロジェクトで50 msに設定します。

100 ms周期の入力に対し、20秒間でCAN受信・KUKSA更新とも各信号約10 Hz、実描画約10 fpsを確認しました。画面合成は平均約0.58 msでした。実描画はWeston timelineの `core_repaint_posted` で計測しています。

- [実画面・各段階の計測値と手順](https://github.com/e-lab-pius-project/pius-meter-panel/blob/main/docs/VALIDATION.md#ubuntu-2604virgl最小転送間隔50-msの検証)
- GPU有効化前後の100 ms設定での比較：合成時間は平均約10.5 ms → 約0.44 ms、パネルCPU使用率は約35% → 約2.8%（1コア=100%）。
- 最小転送間隔100 msを残すと更新は約8 fpsで、GPU有効化だけではCANプロバイダーの間引きは解消しません。
- GPU有効・2D切替・不正な `AGL_GL` の拒否は、更新した `tests/check-start.sh` で検査しました。Ubuntu 26.04実機とWSL2のUbuntu 24.04で成功しています。

この記録のCAN通信は仮想CANです。実CAN、WindowsからのRDP接続、新規Ubuntuインストールからの全工程、60 fpsの描画能力、長時間運転は未検証です。

再現用コマンド:

```bash
for script in scripts/*.sh tests/*.sh; do bash -n "$script"; done
# prepare.shで固定イメージを取得済みの環境
bash tests/check-preparation.sh
# /dev/kvmにアクセスできる環境。QEMUの代わりにテスト用プロセスを使う
bash tests/check-start.sh
```

`check-preparation.sh` は一時フォルダーで、作業用ディスクの作成・既存変更の保持・破損カーネルの拒否を検査します。VMは起動しません。

`check-start.sh` は起動引数・ローカル限定のSSH転送・二重起動の拒否を検査します。実際の画面表示やゲスト起動の検査とは別です。

## 元のagl-wsl-demo

[参照コミット](https://github.com/e-lab-pius-project/agl-wsl-demo/tree/dcd741dda599ef73a9f1135b2df9349552ef120e)の検証記録では、Ubuntu 24.04 / WSL2 / QEMU 8.2.2で次を確認しています。

- 未変更の公式Flutterイメージから起動、ホーム画面表示、SSH接続、正常終了。
- 仮想CANからKUKSA Vehicle.Speedへの入力（0 → 20 → 42 → 0 km/h）。
- 仮想can0を残したUSB-CANのホットプラグ。AGLの実can1とホスト側アダプター間で各方向6フレーム、通信エラー0。

これらはUbuntu 26.04での実行結果ではありません。物理CAN→cannelloni→KUKSAの一連の経路も未検証です。
