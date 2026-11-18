# MetaQuestURPApp

MetaQuest単機で実行可能なVRアプリケーションDemoのプロジェクトファイルとなっております。<br>
内容としては水面の屈折表現を行うShaderのデモとなっており、画面コピー（OpaqueTexture）を利用したものと<br>
最適化の例として画面コピーの代わりに事前ベイクしたリフレクションプローブ（CubeMap）の2通り制作を行い、ビルド、GPUTimeの計測を行いました（計測にはOVR Metrics toolを使用しております）<br>
OpaqueTexture：12000～14000µs<br>
https://github.com/user-attachments/assets/aa7acd62-3d15-4999-8fdf-cc38b39d9229

CubeMap:5000～6000µs<br>
https://github.com/user-attachments/assets/1d522e98-3d34-48e5-987f-a1714245c9b8


ビルドには以下Unity環境及び以下のSDKのインストールが必要となります。

Unity 6000.3.28f1<br>
・MetaXRSDK<br>
・Universal RP<br>

また、ビルド済みアプリケーションファイルはこちらに配置しております<br>
https://github.com/stSubaru1924/Portfolio/releases/tag/Demo_apk
