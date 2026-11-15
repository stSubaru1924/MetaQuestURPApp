# MetaQuestURPApp

MetaQuest単機で実行可能なVRアプリケーションDemoのプロジェクトファイルとなっております。　　
内容としては水面の屈折表現を行うShaderのデモとなっており、画面コピー（OpaqueTexture）を利用したものと　　
最適化の例として画面コピーの代わりに事前ベイクしたリフレクションプローブ（CubeMap）の2通り制作を行い、ビルド、GPUTimeの計測を行いました（計測にはOVR Metrics toolを使用しております）
OpaqueTexture：12000～14000　　
CubeMap:5000～6000

ビルドには以下Unity環境及び以下のSDKのインストールが必要となります。

Unity 6000.3.28f1
・MetaXRSDK
・Universal RP

また、ビルド済みアプリケーションファイルはこちらに配置しております
