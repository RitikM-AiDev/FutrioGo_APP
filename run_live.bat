@echo off
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "ANDROID_HOME=C:\Android\Sdk"
set "ANDROID_SDK_ROOT=C:\Android\Sdk"
set "PATH=C:\flutter\bin;%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%"

echo ========================================================
echo  Futrio Go - Flutter Assistant (Live Sync / Hot Reload)
echo ========================================================
echo.
echo Connecting to your Android phone...
echo Press 'r' in this terminal anytime to Hot Reload live changes!
echo Press 'R' to Hot Restart.
echo.

cd /d "%~dp0"
flutter run
pause

