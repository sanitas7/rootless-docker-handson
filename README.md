# rootless-docker-handson
 Docker 20.10でGAになったRootless modeの導入ハンズオン

# Rootless Dockerとは
一言で説明すると、Docker daemonとコンテナを`non-root`で実行できるようにしてくれるモードのことです。これを使うことでセキュリティを強化できます。さらに、今まで多くの人を悩ませてきたであろう[Dockerでファイルを作成したときの所有者が`root`になってしまう問題](https://qiita.com/yohm/items/047b2e68d008ebb0f001)も簡単に解決できます。  
  
このリポジトリでは、(1) Rootless DockerをUbuntuでインストールする方法と(2) Rootless Dockerと今までと同じ`root`ありのDockerを使い分ける方法について、ハンズオン形式で説明します。

# 実行環境
ホストOS: Ubuntu 18.04.5  
Docker: 20.10

# 導入手順
<span style="color: red; ">DockerにRootless modeを導入する手順は[公式ドキュメント](https://docs.docker.com/engine/security/rootless/)で説明されています。最新の情報については公式ドキュメントを参照してください。</span>

## 前提となるパッケージのインストール
以下のコマンドを実行して`newuidmap`がホストOSインストールされているか確認します。パスが表示される場合はインストール済みです。
```bash
which newuidmap
```
インストールされていない場合は以下のコマンドでインストールしましょう。
```bash
sudo apt install uidmap
```

## スクリプトによるRootless Dockerのインストール
以下のコマンドで、公式で提供されているスクリプトからRootless Dockerをインストールできます。
```bash
curl -fsSL https://get.docker.com/rootless | sh
```
このとき、`Aborting because rootful Docker is running and accessible. Set FORCE_ROOTLESS_INSTALL=1 to ignore.` のようなエラーが表示されてインストールができないことがあります。その場合は以下のコマンドで環境変数を設定してから、改めてスクリプトを実行します。
```bash
export FORCE_ROOTLESS_INSTALL=1
curl -fsSL https://get.docker.com/rootless | sh
```

## Daemonとクライアントの設定
```bash
systemctl --user start docker
systemctl --user enable docker
sudo loginctl enable-linger $(whoami)
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
```

## Rootless Dockerが正常に動作しているか確認する
これでRootless Dockerが使えるようになりました。試しに以下のコマンドを実行して、Dockerから作られたファイルの所有者がホストOS上で`non-root`になっていることを確認してみましょう。
```bash
docker run --rm -v $PWD:/home ubuntu touch /home/test_rootless
ls -l | grep test_rootless
# -rw-r--r-- 1 sanitas sanitas      0 12月 14 20:06 test_rootless
```
無事にファイルの所有者が`non-root`になっていることが確認できました。

## contextの作成
Rootless Dockerと`root`ありのDockerを使い分けられるように、contextを作成します。
```bash
docker context create rootless --description "for rootless mode" --docker "host=unix://$XDG_RUNTIME_DIR/docker.sock"
```

# RootlessとrootありのDockerを使い分ける
Rootless modeを導入した後でも、これまでと同じように`root`でDockerを使いたいというケースがあるかもしれません。その場合でも、contextを切り替えることで簡単に`rootless`と`root`ありのDockerを使い分けることができます。  
  
Rootless modeを導入することができたら、一度マシンを再起動して以下のコマンドを実行してみてください。
```bash
docker context ls
```
以下のような出力が確認できます。`default`が`root`ありのcontextで、`rootless`が先ほど作ったrootless modeのcontextです。これらのcontextを切り替えることで、`root`ありと`rootless`の2つのモードを使い分けることができます。
```
default *   Current DOCKER_HOST based configuration   unix:///var/run/docker.sock                               swarm
rootless    for rootless mode                         unix:///run/user/1000/docker.sock
```
`root`ありの状態で先ほどと同様にDockerからファイルを作成して所有者を確認してみましょう。
```bash
docker run --rm -v $PWD:/home ubuntu touch /home/test_root
ls -l | grep test_root
# -rw-r--r-- 1 root    root         0 12月 14 20:31 test_root
```
所有者が`root`になっています。次にcontextを`rootless`に切り替えてファイルを作成し、所有者を確認します。

```bash
docker context use rootless
docker run --rm -v $PWD:/home ubuntu touch /home/test_rootless2
ls -l | grep test_rootless3
# -rw-r--r-- 1 sanitas sanitas      0 12月 14 20:33 test_rootless2
```
所有者が`non-root`になっています。これで`root`ありと`rootless`のDockerが使い分けられるようになりました。`root`ありに戻したい場合は以下のコマンドを実行すればOKです。

```bash
docker context use default
```

# References
- [Run the Docker daemon as a non-root user (Rootless mode)](https://docs.docker.com/engine/security/rootless/)
- [dockerでvolumeをマウントしたときのファイルのowner問題](https://qiita.com/yohm/items/047b2e68d008ebb0f001)