# MT4-Connector-Server
## 説明
MT4を外部のプログラムからコントロールするための制御基盤です。  
ここで公開しているのはサーバー側の機能です。

クライアントは以下のURLで公開しています：  
- Java版 クライアント  
https://github.com/Kurokawa-kun/MT4-Connector-Client-Java  
- Python版 クライアント  
https://github.com/Kurokawa-kun/MT4-Connector-Client-Python  
  
次のような仕組みで動作します。MT4からは単体のMQL4プログラムが動作しているように見えます。  
<img src="materials/MT4-Connector-Image1.png" width="50%">

将来的にやりたいことはMT4/MT5を外部から操作することではなく、ディープラーニングで相場情報を学習して自動注文を行うことです。このプログラムはその基盤となるものです。  
<img src="materials/MT4-Connector-Image2.png" width="50%">

## 必要なもの
必要に応じて以下のソフトウェアを用意してください。
- MT4
- Javaの開発環境、または
- Pythonの開発環境

## 使用方法

### クライアント側の準備

1. クライアント側のReleasesからzipをダウンロードします。
1. zipファイルの中身を開発用の作業フォルダに展開します。
1. 開発環境で開きます。Connectorクラスを継承してOnInit, OnTick, OnDeinit関数を実装します。

### サーバー側の準備
1. サーバー側のReleasesからzipをダウンロードします。  
1. zipファイルの中身をMT4のデータフォルダに展開します。  
    ※ デフォルトのデータフォルダは以下：  
    C:\Users\（ユーザー名）\AppData\Roaming\MetaQuotes\Terminal\（インスタンスID）
1. MT4を起動します。  
1. NavigatorウィンドウのExpertsツリーからConnectorをチャートに貼り付けます。  
    ※ 「DLLの使用を許可する」にチェックを入れてください
1. 必要なパラメータを指定します。  
    1. 作業ディレクトリ    
    1. インタプリタ名    

## 制限事項
以下の機能群はJava/Pythonに代替機能があることや、本来の目的とは関連性が低いためサポートしません。
- 算術関数
- 文字列関数
- 配列関数
- オブジェクト関数
- ファイル関数
- トレードシグナル
- GUIオブジェクト

## 既知の問題
- シンボルの数にもよりますが、全シンボル全時間足のデータを取得しようとすると1時間以上かかります。これは名前付きパイプのバッファが256バイトしかなく、データの送受信に時間がかかるためです。将来的には32768バイト程度に拡張して高速化する予定です。

## 補足
- MT5のサポートは？
    - 手が空いたらそのうち取り組むかもしれません。

# 技術的な話
## 関数の呼び出し
MQL4の関数と外部プログラムの関数を2つに分けました。
- グローバル関数 … 外部から呼び出される関数
- ローカル関数 … グローバル関数の内部で呼び出される関数

<table>
  <tr><td colspan="2">MQL4</td><td colspan="2">外部プログラム</td></tr>
  <tr><td>グローバル関数</td><td>役割</td><td>グローバル関数</td><td>役割</td></tr>
  <tr><td>OnInit</td><td>外部プログラムにOnInitの実行依頼を行います</td><td>OnInit</td><td>MQL4のOnInitに相当する処理を記述します</td></tr>
  <tr><td>OnTick</td><td>外部プログラムにOnTickの実行依頼を行います</td><td>OnTick</td><td>MQL4のOnTickに相当する処理を記述します</td></tr>
  <tr><td>OnDeinit</td><td>外部プログラムにOnDeinitの実行依頼を行います</td><td>OnDeinit</td><td>MQL4のOnDeinitに相当する処理を記述します</td></tr>
  <tr><td>上記以外（例えばOrderSend）</td><td>MQL4側の同名のローカル関数（例えばOrderSend）を呼び出します。</td><td></td><td></td></tr>
</table>
