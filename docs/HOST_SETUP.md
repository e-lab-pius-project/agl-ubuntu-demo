# UbuntuのSSH・画面・リモートデスクトップを設定する

対象はUbuntu Desktop 26.04 LTSのGNOMEです。[起動ガイド](../README.md)の `setup-host.sh` を実行済みなら、SSHと画面設定は済んでいます。RDPの接続情報はこのページで設定します。

## SSHを有効にする

未実行の場合は**Ubuntu本体の端末**で実行します。

```bash
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable --now ssh.socket
systemctl is-active ssh.socket
hostname -I
```

`active` を確認します。UbuntuではSSH接続の待受けをsocketで開始するため、接続前に `ssh.service` がinactiveでも、socketがactiveなら待受けできます。

別PCから接続します。ユーザー名とIPアドレスはUbuntuのものに置き換えます。

```bash
ssh <Ubuntuユーザー名>@<UbuntuのIPアドレス>
```

これはUbuntuホストへの接続です。AGLへの接続はUbuntu内で `bash scripts/ssh.sh` を使います。

## 自動ロック・消灯・暗転を止める

**設定を適用したいユーザーでUbuntuのデスクトップにログインし、端末から**実行します。sudoは付けません。

```bash
cd ~/agl-ubuntu-demo
bash scripts/configure-desktop.sh
```

処理の最後に設定を読み返し、次の6項目が反映された場合だけPASSを表示します。

| 項目 | 設定 |
|---|---|
| 無操作による画面消灯 | 無効（idle-delay = 0） |
| 自動スクリーンロック | 無効 |
| アイドル時の暗転 | 無効 |
| 周囲の明るさに応じた自動調整 | 無効 |
| AC接続時の自動サスペンド | 無効 |
| バッテリー駆動時の自動サスペンド | 無効 |

これはユーザー単位の設定です。手動ロック、ふたを閉じたときの動作、バッテリー切れによる停止は別です。放置してもロックされないため、共用場所では利用後に手動でロックするか終了してください。画面をつけ続けるとバッテリー消費も増えます。

Ubuntuの標準値へ戻す場合は、同じユーザーの端末で実行します。実行前の独自設定を復元する操作ではありません。

```bash
gsettings reset org.gnome.desktop.session idle-delay
gsettings reset org.gnome.desktop.screensaver lock-enabled
gsettings reset org.gnome.settings-daemon.plugins.power idle-dim
gsettings reset org.gnome.settings-daemon.plugins.power ambient-enabled
gsettings reset org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type
gsettings reset org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type
```

## RDPでデスクトップを共有する

本手順は、**Ubuntu本体でログイン済みの画面を共有する「デスクトップ共有」**を使います。AGLのQEMUウィンドウを本体とリモートで同時に見られます。「リモートログイン」は別のログイン方式です。再起動後はUbuntu本体で一度ログインしてから接続します。自動ログインは設定しません。

1. Ubuntuの「設定」→「システム」→「リモートデスクトップ」を開きます。
2. 「デスクトップ共有」を有効にします。
3. 「リモートコントロール」を有効にし、表示だけでなく操作も許可します。
4. 接続用のユーザー名・パスワードを設定します。**Ubuntuへのログイン情報とは別のRDP用認証情報**です。
5. 画面に表示されたIPアドレス・ポート・証明書のフィンガープリントを確認します。

通常のポートは3389です。リモートログインを併用すると共有側が3390などになるため、設定画面の値を使います。コマンドで確認する場合:

```bash
grdctl status
systemctl --user is-active gnome-remote-desktop.service
ss -ltn 'sport = :3389 or sport = :3390'
```

`RDP: Status: enabled`、`View-only: no`、サービスの `active` を確認します。パスワードを表示するオプションは使いません。

Windows側は `Win + R` → `mstsc` で「リモートデスクトップ接続」を開き、`<UbuntuのIPアドレス>:<ポート>` へ接続します。手順4のRDP用認証情報を使います。初回に証明書の警告が出た場合は、Ubuntu側で確認したフィンガープリントと照合します。

画面共有は、GNOMEセッションが動作し、ロックされていないことが前提です。Ubuntu本体の画面をロックすると接続が切れるため、AGLを継続操作したい間はロックしません。接続後、共有されたUbuntuの端末で `bash scripts/start.sh` を実行します。

## 接続できない場合

まず同じLANから接続し、`hostname -I` のIPアドレス、サービス状態、共有画面のポート、Ubuntu本体のログイン状態を確認します。

ファイアウォールを使用している場合は、必要な接続元だけを許可します。`setup-host.sh` はファイアウォールを変更しません。

```bash
sudo ufw status
# 接続元PCのIPが192.168.1.10、共有ポートが3389の場合の例
sudo ufw allow from 192.168.1.10 to any port 22 proto tcp
sudo ufw allow from 192.168.1.10 to any port 3389 proto tcp
```

IPアドレスとポートを実際の値へ置き換えてから実行します。外部から使う場合は組織のVPNなどを利用し、SSHやRDPのポートをインターネットへ直接公開しません。

## 公式資料

- [Ubuntu 26.04: Share your desktop remotely](https://ubuntu.com/desktop/docs/en/26.04/how-to/share-your-desktop-remotely/)
- [GNOME Remote Desktop: Configuration](https://github.com/GNOME/gnome-remote-desktop/blob/main/docs/configuration.md)
- [Ubuntu: OpenSSH server](https://documentation.ubuntu.com/server/how-to/security/openssh-server/)
