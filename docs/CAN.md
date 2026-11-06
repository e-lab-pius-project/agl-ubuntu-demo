# 仮想CANで車速を入力する

実車やUSB-CANを使わず、Ubuntu から QEMU 内の AGL に車速を入力します。

物理アダプターを使う場合は [USB-CAN接続手順](USB_CAN.md) を参照してください。cannelloniは双方向のため、本書の模擬送信試験と物理CAN接続は切り替えて使用します。

`Ubuntu vcan_agl → cannelloni (TCP) → AGL can0 (vcan) → kuksa-can-provider → KUKSA Vehicle.Speed`

cannelloni は CAN フレームをネットワーク越しに運ぶツールです。この手順では TCP を使います。QEMU に仮想PCI CANカードを追加する必要はありません。AGL のこのイメージには cannelloni、can-utils、仮想 can0、KUKSA が含まれています。

## 1. Ubuntu 側の準備

**Ubuntu本体** で実行します。cannelloni をまだ導入していない場合:

```bash
sudo apt install -y build-essential cmake git can-utils
git clone --branch v1.2.1 --depth 1 https://github.com/mguentner/cannelloni.git ~/cannelloni
cd ~/cannelloni
test "$(git rev-parse HEAD)" = db74c5aa8dcfae06a24f509a2bf6c3889cd7f855
cmake -S . -B build -DSCTP_SUPPORT=OFF
cmake --build build -j2
sudo cmake --install build
```

仮想CANとトンネルを開始します。

```bash
sudo modprobe vcan
ip link show vcan_agl >/dev/null 2>&1 || sudo ip link add dev vcan_agl type vcan
ip -details link show vcan_agl | grep -qw vcan
sudo ip link set vcan_agl up
sudo systemd-run --unit=agl-can-host --collect \
  /usr/local/bin/cannelloni -C s -I vcan_agl -L 127.0.0.1 -l 20000 -p
```

`vcan_agl` が **vcan** と表示されることを確認します。既に同名サービスが動いている場合は、二重起動せず既存サービスを使います。

## 2. AGL 側の準備

AGL を起動してから、Ubuntuのリポジトリ内で `bash scripts/ssh.sh` を実行します。以下は **AGL 内**で実行します。

```bash
ip -details link show can0
systemctl is-active kuksa-can-provider kuksa-databroker
systemd-run --unit=agl-can-guest --collect \
  /usr/bin/cannelloni -C c -I can0 -R 10.0.2.2 -r 20000
exit
```

`can0` は仮想CANです。`10.0.2.2` は QEMU のユーザーネットワークから見たホストです。ゲストから接続するため、追加のポート転送は不要です。

ホスト側は 127.0.0.1 にだけバインドします。`-p` は cannelloni のpeerチェックを無効にするオプションで、この構成では必要でした。待受アドレスをLAN全体へ広げないでください。

## 3. 入力と検査

**Ubuntu本体** で接続状態を確認し、TCP接続が確立してからリポジトリ内で試験します。

```bash
sudo journalctl -u agl-can-host -n 20 --no-pager
ss -tn | grep ':20000'
bash scripts/check-can.sh
```

期待する最後の出力:

```text
PASS: Ubuntu vcan_agl -> TCP -> AGL can0 -> KUKSA (0, 20, 42, 0 km/h)
```

AGLの公式DBCで定義された標準ID **0x3E9** を10 Hzで送り、KUKSAの `Vehicle.Speed` が **0 → 20 → 42 → 0 km/h** になることを検査します。40フレームの有限試験です。接続直後に失敗した場合はTCP接続を確認して再実行します。

この試験の到達点は **KUKSA の値**です。IVI画面の速度計表示や、PIUS固有ID `0x2010` の変換を確認するものではありません。テストスクリプトは物理CANへ送らないよう `vcan_agl` の種類を検査します。

## 4. 停止

Ubuntu のリポジトリ内で実行します。

```bash
bash scripts/ssh.sh systemctl stop agl-can-guest
sudo systemctl stop agl-can-host
```

この設定は自動起動には登録しません。UbuntuやAGLを再起動した後は必要なサービスと仮想CANを再度準備します。

## 設定の場所（AGL内）

- CANプロバイダー: `/etc/kuksa-can-provider/config.ini`
- DBC: `/usr/share/dbc/agl-vcar.dbc`
- VSS対応: `/usr/share/vss/vss.json`
- 接続先: `https://localhost:55555`

同梱トークンファイルはコマンドから参照しますが、その内容を文書やログに貼り付ける必要はありません。

参考: [cannelloni](https://github.com/mguentner/cannelloni)、[AGL公式 Demo Control Panel](https://docs.automotivelinux.org/en/salmon/06_Component_Documentation/09_AGL_Demo_Control_Panel/)。
