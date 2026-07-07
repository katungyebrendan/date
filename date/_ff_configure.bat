@echo off
set PATH=C:\Users\user\flutter\bin;C:\Users\user\AppData\Roaming\npm;C:\Users\user\AppData\Local\Pub\Cache\bin;%PATH%
firebase --version
call flutterfire configure --project=velo-c4757 --platforms=android,ios
