# How to Install Natual Language Processing Tools
自然言語処理系ツールインストール方法まとめ


# セットアップ

## 環境 (確認した環境)
- macOS 10.14.6
- Python 3.7
- zsh

## 自然言語処理関係

### 解析器系

- [MeCab](https://taku910.github.io/mecab/) のインストール (形態素解析器)
    ```shell script
    % brew install mecab
    ```
- python-binding of mecab のインストール
    ```shell script
    % pip3 install mecab-python3
    ```
- crf++ のインストール (mecab内で使用される学習モデル)
    ```shell script
    % brew install crf++
    ```
- [CaboCha](https://taku910.github.io/cabocha/) のインストール (係り受け解析)
    ```shell script
    % brew install cabocha
    ```
- python-binding of cabocha のインストール
    ```shell script
    % pip3 install cabocha-python
    ```
- [JUMAN](http://nlp.ist.i.kyoto-u.ac.jp/index.php?JUMAN) のインストール (形態素解析器)
    - with brew
        ```shell script
        % brew install juman
        ```
    - from source files 
        ```shell script
        % dir=$HOME/Works/nlp/tool
        % [ -d ${dir} ]||mkdir -p ${dir}; cd ${dir}
        % curl -O http://nlp.ist.i.kyoto-u.ac.jp/nl-resource/juman/juman-7.01.tar.bz2
        % tar jxvf juman-7.01.tar.bz2
        % cd juman-7.01
        % ./configure --prefix=$HOME/Works/nlp/tool
        % make
        % make install
        ```
- [JUMAN++](http://nlp.ist.i.kyoto-u.ac.jp/index.php?JUMAN++) のインストール (形態素解析機)
    - with brew
        ```shell script
        % brew install jumanpp
        ```
    - from source files
        ```shell script
        % dir=$HOME/Works/nlp/tool
        % [ -d ${dir} ]||mkdir -p ${dir}; cd ${dir}
        % wget http://lotus.kuee.kyoto-u.ac.jp/nl-resource/jumanpp/jumanpp-1.02.tar.xz
        % tar xJvf jumanpp-1.02.tar.xz
        % cd jumanpp-1.02
        % cd jumanpp-resource
        % ./install.sh --prefix=${dir}
        % export JPPRCDIR=${dir}/share/jumanpp-resource
        % cd ../jumanpp-src
        % ./configure --prefix=${dir} --enable-default-resource-path=$JPPRCDIR
        % make
        % make install
        ```
-  [KNP](http://nlp.ist.i.kyoto-u.ac.jp/index.php?KNP) のインストール (係り受け解析)
    - with brew
        ```shell script
        % brew tap uetchy/nlp
        % brew install knp
        ```
    - from source files
        ```shell script
        % dir=$HOME/Works/nlp/tool
        % [ -d ${dir} ]||mkdir -p ${dir}; cd ${dir}
        % curl -O http://nlp.ist.i.kyoto-u.ac.jp/nl-resource/knp/knp-4.19.tar.bz2
        % tar jxvf knp-4.19.tar.bz2
        % cd knp-4.19
        % ./configure --prefix=$HOME/Works/nlp/tool \
        --with-juman-prefix=$HOME/Works/nlp/tool
        % make
        % sudo make install
        ```
-  [pyknp](https://pyknp.readthedocs.io/en/latest/) のインストール (JUMAN++ と KNPの Python バインダー)
    ```shell script
    % pip3 install pyknp
    ```
-  [jdepp](http://www.tkl.iis.u-tokyo.ac.jp/~ynaga/jdepp/) のインストール (係り受け解析器)
    ```shell script
   	% dir=$HOME/Works/nlp/tool
    % [ -d ${dir} ]||mkdir -p ${dir}; cd ${dir}
    % curl -O http://www.tkl.iis.u-tokyo.ac.jp/~ynaga/jdepp/jdepp-latest.tar.gz
    % tar zxf jdepp-latest.tar.gz&& rm -rf jdepp-latest.tar.gz
    % cd ${dir}/jdepp-2015-10-05
    % ./configure
    % make
    % make check
    % sudo make install
    % make installcheck
    ```
-  [SudachiPy](https://github.com/WorksApplications/SudachiPy) のインストール (形態素解析器 [Sudachi](https://github.com/WorksApplications/Sudachi#sudachi-%E6%97%A5%E6%9C%AC%E8%AA%9Ereadme) の Python バージョン)
    ```shell script
    % pip3 install SudachiPy
    % pip3 install \ 
    https://object-storage.tyo2.conoha.io/v1/nc_2520839e1f9641b08211a5c85243124a/sudachi/SudachiDict_core-20200127.tar.gz
    ```

- [GiNZA](https://github.com/megagonlabs/ginza) のインストール
    ```shell script
    % pip3 install ginza
    ```
    GiNZAの重要なフレームワークである [spaCy](https://spacy.io/) もインストールされる

- [Camphr](https://camphr.readthedocs.io/en/latest/index.html) のインストール (spaCyのプラグイン)
    ```shell script
    % pip3 install "transformers==2.4.1"
    % pip3 install "camphr==0.5.23"
    ```

- [Stanza](https://stanfordnlp.github.io/stanza/) ([Github](https://github.com/stanfordnlp/stanza)) のインストール  
([StanfordNLP](https://github.com/stanfordnlp/stanfordnlp)から、プロジェクト名が Stanza に変更されて開発が継続されている)
    ```shell script
    % pip3 install stanza
    ```

- [UniDic2UD](https://github.com/KoichiYasuoka/UniDic2UD) のインストール
    ```shell script
    % pip3 install unidic2ud
    ```

### 辞書

- mecab-ipadic のインストール
    ```shell script
    % brew install mecab-ipadic
    ```
- mecab-juman のインストール
    ```shell script
    % brew install mecab-jumandic
    ```
- mecab-unidic のインストール
    ```shell script
    % brew install mecab-unidic
    ```
- [mecab-ipadic-neologd](https://github.com/neologd/mecab-ipadic-neologd/blob/master/README.ja.md) のインストール (俗語等を含む辞書)
    ```shell script
    % dir=$HOME/Works/nlp/tool
    % [ -d ${dir} ]||mkdir -p ${dir}; cd ${dir}
    % git clone --depth 1 \
    git@github.com:neologd/mecab-ipadic-neologd.git
    % cd ${dir}/mecab-ipadic-neologd
    % ./bin/install-mecab-ipadic-neologd -n -a -y
    ```
- mecab-naist-jdic のインストール (ダウンロード元は[こちら](https://ja.osdn.net/projects/naist-jdic/releases/))
    ```shell script
    % dir=$HOME/Works/nlp/tool
    % [ -d ${dir} ]||mkdir -p ${dir}; cd ${dir}
    % curl -O http://iij.dl.sourceforge.jp/naist-jdic/53500/mecab-naist-jdic-0.6.3b-20111013.tar.gz
    % tar zxf mecab-naist-jdic-0.6.3b-20111013.tar.gz&& rm -rf mecab-naist-jdic-0.6.3b-20111013.tar.gz
    % cd ${dir}/mecab-naist-jdic-0.6.3b-20111013/
    % ./configure
    % make
    % make check
    % sudo make install
    ```
- [oseti](https://qiita.com/yukinoi/items/46aa016d83bb0e64f598) のインストール (日本語評価極性辞書)
    ```
    % pip3 install oseti
    ```