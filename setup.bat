@echo off
setlocal EnableDelayedExpansion

for /f %%a in ('powershell -Command "[int](Get-Date -UFormat %%s)"') do set START_TIME=%%a

set CURRENT_DIR=%CD%
cd /d %~dp0

set "EXT_DIR=%CD%\ext"
set "ZIP_DIR=%EXT_DIR%\7zip"
set "ZIP_EXECUTABLE=%ZIP_DIR%\7za.exe"
if not exist "%ZIP_DIR%" (
  mkdir "%ZIP_DIR%"
  set "ZIP_FILE=7z2409-extra.7z"
  powershell -NoProfile -Command "C:\Windows\System32\curl.exe --ssl-no-revoke -L -o %EXT_DIR%\!ZIP_FILE! https://www.7-zip.org/a/!ZIP_FILE!"
  powershell -NoProfile -Command "tar -xf %EXT_DIR%\!ZIP_FILE! -C %ZIP_DIR%"
  del "%EXT_DIR%\!ZIP_FILE!"
)

set "CMAKE_DIR=%EXT_DIR%\cmake"
if not exist "%CMAKE_DIR%" (
    set "CMAKE_FILE_NAME=cmake-4.0.1-windows-x86_64"
    set "CMAKE_ZIP_FILE=!CMAKE_FILE_NAME!.zip"
    if not exist "%EXT_DIR%\!CMAKE_ZIP_FILE!" (
        powershell -NoProfile -Command "C:\Windows\System32\curl.exe --ssl-no-revoke -L -o '%EXT_DIR%\!CMAKE_ZIP_FILE!' 'https://github.com/Kitware/CMake/releases/download/v4.0.1/!CMAKE_ZIP_FILE!'"
    )
    powershell -NoProfile -Command "%ZIP_EXECUTABLE% x '%EXT_DIR%\!CMAKE_ZIP_FILE!' -o'%EXT_DIR%'"
    move "%EXT_DIR%\!CMAKE_FILE_NAME!" "%CMAKE_DIR%"
    del "%EXT_DIR%\!CMAKE_ZIP_FILE!"
)
set "CMAKE_EXECUTABLE=%CMAKE_DIR%\bin\cmake.exe"

set SRC_DIR=%CD%\src

for %%v in (3.2.7 3.3.0 3.3.1 3.3.2 3.3.3 3.3.4 3.3.5 3.3.6 3.3.7) do (
    set MUJOCO_VERSION=%%v
    set MUJOCO_SRC_DIR=%SRC_DIR%\mujoco-!MUJOCO_VERSION!
    if not exist "!MUJOCO_SRC_DIR!" (
        mkdir "!MUJOCO_SRC_DIR!"
        set MUJOCO_ZIP_FILE=mujoco-!MUJOCO_VERSION!-windows-x86_64.zip
        echo https://github.com/google-deepmind/mujoco/archive/refs/tags/!MUJOCO_VERSION!/mujoco-!MUJOCO_VERSION!-windows-x86_64.zip
        powershell -NoProfile -Command "C:\Windows\System32\curl.exe --ssl-no-revoke -L -o %SRC_DIR%\!MUJOCO_ZIP_FILE! https://github.com/google-deepmind/mujoco/archive/refs/tags/!MUJOCO_VERSION!/mujoco-!MUJOCO_VERSION!-windows-x86_64.zip"
        powershell -NoProfile -Command "%ZIP_EXECUTABLE% x '%SRC_DIR%\!MUJOCO_ZIP_FILE!' -o'%SRC_DIR%'"
        del "%SRC_DIR%\!MUJOCO_ZIP_FILE!"
    )

    set BUILD_DIR=%CD%\build\mujoco-!MUJOCO_VERSION!
    set INSTALL_DIR=%CD%\install\mujoco-!MUJOCO_VERSION!
    if not exist "!INSTALL_DIR!" (
        mkdir "!INSTALL_DIR!"
    )
    if not exist "!BUILD_DIR!" (
        mkdir "!BUILD_DIR!"
    )

    xcopy /E /I /Y "%CD%\plugin\multiverse_connector" "!MUJOCO_SRC_DIR!\plugin\multiverse_connector"
    set CMAKE_PATH=!MUJOCO_SRC_DIR!\CMakeLists.txt
    findstr /C:"plugin/multiverse_connector" "!CMAKE_PATH!" >nul
    if errorlevel 1 (
        >>"!CMAKE_PATH!" echo add_subdirectory^(plugin/multiverse_connector^)
    )

    %CMAKE_EXECUTABLE% -S "!MUJOCO_SRC_DIR!" -B "!BUILD_DIR!" -DCMAKE_INSTALL_PREFIX="!INSTALL_DIR!" -DMUJOCO_BUILD_EXAMPLES=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_BUILD_SIMULATE=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF -DCMAKE_POLICY_VERSION_MINIMUM="3.5" -Wno-deprecated -Wno-dev
    %CMAKE_EXECUTABLE% --build "!BUILD_DIR!" --config Release
    %CMAKE_EXECUTABLE% --install "!BUILD_DIR!"

    set "MUJOCO_PLUGIN_DIR=%CD%\mujoco_plugin\mujoco-!MUJOCO_VERSION!"
    if not exist "!MUJOCO_PLUGIN_DIR!" (
        mkdir "!MUJOCO_PLUGIN_DIR!"
    )
    copy /Y "!BUILD_DIR!\bin\Release\multiverse_connector.dll" "!MUJOCO_PLUGIN_DIR!\multiverse_connector.dll"
    xcopy /E /I /Y "!MUJOCO_PLUGIN_DIR!" "!INSTALL_DIR!\bin\mujoco_plugin"
    copy /Y "%CD%\plugin\multiverse_connector\lib\libzmq-mt-4_3_5.dll" "!INSTALL_DIR!\bin"
    copy /Y "%CD%\plugin\multiverse_connector\lib\jsoncpp.dll" "!INSTALL_DIR!\bin"

    for /f %%a in ('powershell -Command "[int](Get-Date -UFormat %%s)"') do set END_TIME=%%a
    set /a ELAPSED=!END_TIME! - !START_TIME!

    echo Build completed in !ELAPSED! seconds
)

endlocal
