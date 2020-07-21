USEFUL MEMO
---

### 環境設定

シェクスクリプト `umemo.sh` を `PATH` が通っているディレクトリにシンボリックリンクを貼る。


例えば、`/usr/local/bin` に `PATH` が通っているとする。
```shellscript
$ cd /usr/local/bin
$ sudo ln -sf {PATH_TO_GEAR}/gear/umemo/umemo.sh umemo
```