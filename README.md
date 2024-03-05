# setup
android studioをインストールし、起動画面の設定からコマンドラインツールをインストールしてください。
VSCODEのプラグインからflutterをインストールすると、右下に本体をインストールするかを聞かれるのでOKとする
場所はC:/devがよい。
その後flutter docktorがすべて緑になればOK

# edit
lib/main.dartを基本的には触る

# android build
権限周りは以下を修正
android/app/src/main/AndroidManifest.xml

```
flutter build apk
```

成果物はbuild/app/output/apk/xxxxx.apkに生成される。