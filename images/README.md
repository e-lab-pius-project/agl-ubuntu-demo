# 配布イメージと出典

本リポジトリは新しいイメージを再配布せず、以下のagl-wsl-demo Releasesを取得先として使います。

## 固定した版

- AGL master snapshot: **2026-10-01-b3881**
- ターゲット: **qemux86-64**
- ディスク: `agl-ivi-demo-flutter-qemux86-64-20261001034413.ext4.xz`
- カーネル: `bzImage`（6.18.39-yocto-standard）
- [公式ビルドの配布ディレクトリ](https://download.automotivelinux.org/AGL/snapshots/master/2026-10-01-b3881/qemux86-64/)
- [公式ディスク・カーネル](https://download.automotivelinux.org/AGL/snapshots/master/2026-10-01-b3881/qemux86-64/deploy/images/qemux86-64/)
- [GitHub Releases](https://github.com/e-lab-pius-project/agl-wsl-demo/releases/tag/agl-20261001)

Releases のディスクとカーネルは、2026-10-01 に取得して起動確認に使用した **未変更の公式ファイル**です。検証PCの変更用 qcow2、SSHホスト鍵、個人設定、実行ログは配布しません。画面向きやCANトンネルは手順に従って各PCで設定します。

[SHA256SUMS](SHA256SUMS) は配布ファイルの照合用です。**このプロジェクトで計算した値であり、AGL提供元の署名ではありません。** `latest` は更新されるため、取得には固定日付のURLを使用します。

## パッケージ・ライセンス・ソースの参照

AGL は多数のソフトウェアを含むディストリビューションです。各コンポーネントにはそれぞれのライセンスが適用されます。本リポジトリの文書やスクリプトの扱いを、AGLイメージ全体に適用するものではありません。

Releases には、同じ公式ビルドにある次の情報も添付します。

- `repo_manifest.xml`: ビルドレイヤーとコミットの固定値。
- `local.conf`: 公式ビルド設定（公式配布物）。
- `*.manifest`: インストール済みパッケージ一覧。
- `*.qemuboot.conf`: 公式QEMU設定。
- `*.spdx.json.xz`: 公式SPDX文書をxz圧縮したもの。パッケージ、出典、ライセンス等の追跡用。
- `SHA256SUMS`: 添付ファイルの照合用。

追加の公式資料:

- [当該ビルドのライセンス情報](https://download.automotivelinux.org/AGL/snapshots/master/2026-10-01-b3881/qemux86-64/deploy/licenses/)
- [当該ビルドのSPDX情報](https://download.automotivelinux.org/AGL/snapshots/master/2026-10-01-b3881/qemux86-64/deploy/spdx/)
- [AGL ソースリポジトリ](https://git.automotivelinux.org/)
- [AGL ビルドホストの準備](https://docs.automotivelinux.org/en/master/01_Getting_Started/02_Building_AGL_Image/02_Preparing_Your_Build_Host/)

SPDXとmanifestはメタデータであり、全コンポーネントのソースアーカイブそのものではありません。ソースとパッチは固定したレイヤーのレシピ・SPDXの参照先から追跡できます。
