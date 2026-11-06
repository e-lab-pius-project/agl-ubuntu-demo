# USB-CANをUbuntuまたはAGLで使う

[起動ガイド](../README.md) · [仮想CANによる車速試験](CAN.md)

UbuntuはLinuxカーネルを直接使うため、Windowsのusbipdは不要です。以下の2方式から選びます。

| 方式 | USBを操作する側 | AGLで使うCAN |
|---|---|---|
| USBパススルー | QEMU内のAGL | 通常、実CANの `can1` |
| cannelloniで転送 | Ubuntu本体 | 既定の仮想 `can0` |

1台のUSBアダプターをUbuntuとAGLで同時には使えません。KUKSAの標準設定は `can0` を読みます。USBを `can1` として渡すだけではKUKSAの入力元は切り替わりません。

## Ubuntuで認識を確認する

USB-CANを挿し、**Ubuntu本体の端末**で確認します。

```bash
lsusb
lsusb -t
sudo modprobe gs_usb
modinfo gs_usb
lsmod | grep gs_usb
ip -details link show type can
```

`gs_usb` は対応するUbuntuカーネルのモジュールです。別のドライバーをダウンロードしてインストールする手順はありません。`lsusb` にも出ない場合は、ケーブルやポート、アダプターのファームウェアを確認します。USB認識とSocketCANインターフェースの出現は別の段階です。

CANableなどでも、ファームウェアがgs_usb対応でなければこの手順では認識されません。SLCANやDFUモードの場合は、そのファームウェアに合った手順が必要です。

## USBを直接AGLへ渡す

AGLが先に仮想 `can0` を作った後、USBを追加する流れです。元の `agl-wsl-demo` と同じ順番で、仮想CANの改名はしません。

**このイメージは実CANを自動で500 kbit/sに設定する場合があります。USBを追加する段階ではCAN_H/CAN_Lを実バスへ接続せず、ビットレートを確認してから配線してください。**

### 1. 対象USBだけにアクセス権を付ける

`lsusb` で対象を確認します。以下は `Bus 001 Device 008` の場合の例です。番号は再接続や再起動で変わります。

**Ubuntu:**

```bash
lsusb
sudo setfacl -m "u:$(id -un):rw" /dev/bus/usb/001/008
cd ~/agl-ubuntu-demo
bash scripts/start.sh -monitor stdio
```

QEMU全体をsudoで起動しません。上記のアクセス権はUSBの再接続後に付け直します。

### 2. 仮想can0の作成を待つ

**別のUbuntu端末:**

```bash
cd ~/agl-ubuntu-demo
bash scripts/ssh.sh
```

**AGL:**

```bash
ip -details link show can0
```

`vcan` と表示されることを確認します。

### 3. QEMUモニターでUSBを追加する

QEMUを起動した端末の `(qemu)` へ入力します。例のBus 001 Device 008は `hostbus=1,hostaddr=8` です。

```text
info usbhost
device_add usb-host,hostbus=1,hostaddr=8,id=usbcan
info usb
```

同じ製品を複数台挿している場合も、VID:PIDだけではなくバス番号・デバイス番号で1台を指定します。

**AGL:**

```bash
lsusb
ip -details link show type can
ip -details link show can0
readlink -f /sys/class/net/can1/device/driver
```

既定の `can0` はvcan、追加した `can1` はgs_usbなどの実ドライバー、という状態を確認します。名前は認識順で変わるため実際の出力に合わせます。起動時からUSBを渡しても名前が衝突するわけではありませんが、番号だけでは物理・仮想を区別できません。

### 4. ビットレートを合わせる

**AGL内**で、実CANの名前と接続先の仕様に合わせて設定します。次はClassical CAN 500 kbit/sの例です。

```bash
GUEST_CAN=can1
ip link set "$GUEST_CAN" down
ip link set "$GUEST_CAN" type can bitrate 500000 restart-ms 100
ip link set "$GUEST_CAN" up
ip -details -statistics link show "$GUEST_CAN"
candump "$GUEST_CAN"
```

CAN_H/CAN_L・基準GND・終端抵抗は機器の仕様に従います。本書では実バスに試験フレームを送信しません。CAN FDや実車への適用は個別に確認してください。

USBを外す場合は、AGLで実CANをdownにしてから、QEMUモニターで `device_del usbcan` を実行します。

## Ubuntu側の実CANをAGLの仮想can0へ転送する

この方式はKUKSAの既定の入力元を保てます。USBはUbuntuが保持するため、上のUSBパススルーとは併用しません。

1. [仮想CAN手順](CAN.md#1-ubuntu-側の準備)に従い、Ubuntuへcannelloniを導入します。
2. Ubuntu側で `ip -details link show type can` を確認し、実CANの名前・ドライバーとビットレートを確認します。
3. Ubuntu側の実CANを接続先と同じビットレートでupにし、下の転送を開始します。
4. [AGL側の準備](CAN.md#2-agl-側の準備)に従い、AGLのcannelloniを開始します。

**Ubuntu:** 実CANが `can0` の場合の例です。既存の仮想CAN用転送が動いていれば停止します。

```bash
sudo systemctl stop agl-can-host
sudo systemd-run --unit=agl-can-host --collect \
  /usr/local/bin/cannelloni -C s -I can0 -L 127.0.0.1 -l 20000 -p
```

既存の `agl-can-host` がない場合、stopはエラーになりますが、次の開始操作へ進めます。

cannelloniは双方向です。実CANに接続中は `check-can.sh` やcangenを実行しません。仮想CAN試験に戻す前に、両側の転送サービスを止めて切り替えます。この物理CAN→KUKSA経路は、本リポジトリでは未検証です。
