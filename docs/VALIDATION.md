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

既存の別のAGL環境を止めないため、一時コピーしたstart.shのSSH転送ポートだけを2222から2223へ変更して試験しました。画面表示・KVM・ディスクなど、ほかの起動設定は本リポジトリと同じです。試験には新しい作業用ディスクを使い、USB-CANは渡していません。既存のAGL環境の設定は変更していません。

Ubuntuの新規インストールからsetup-host.shを通す一連の作業、WindowsからのRDP接続、Ubuntu 26.04でのCAN通信は未検証です。grdctlの操作体系と既存のRDP共有サービスの有効状態は実機で確認しています。

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
