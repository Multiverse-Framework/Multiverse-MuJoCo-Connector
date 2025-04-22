@echo off
setlocal EnableDelayedExpansion

for /f %%a in ('powershell -Command "[int](Get-Date -UFormat %%s)"') do set START_TIME=%%a

set CURRENT_DIR=%CD%
cd /d %~dp0

set "MSYS2_DIR=%CD%\ext\msys2"
set "MINGW32_CMAKE_EXE=%MSYS2_DIR%\mingw64\bin\cmake.exe"

if not exist "%MSYS2_DIR%" (
    mkdir "%MSYS2_DIR%"
    powershell -NoProfile -Command "curl -o '%MSYS2_DIR%\msys2-x86_64-20241208.exe' 'https://github.com/msys2/msys2-installer/releases/download/2025-02-21/msys2-x86_64-20250221.exe'; %MSYS2_DIR%\msys2-x86_64-20241208.exe in --confirm-command --accept-messages --root %MSYS2_DIR%"
    powershell -NoProfile -Command "%MSYS2_DIR%\msys2_shell.cmd -defterm -here -no-start -c 'pacman -Syu --noconfirm'"
    powershell -NoProfile -Command "%MSYS2_DIR%\msys2_shell.cmd -defterm -here -no-start -c 'pacman -Sy --noconfirm mingw-w64-x86_64-gcc mingw-w64-x86_64-make mingw-w64-x86_64-cmake'"
    powershell -NoProfile -Command "%MSYS2_DIR%\msys2_shell.cmd -defterm -here -no-start -c 'pacman -Syu --noconfirm'"
    echo MSYS2 installation complete.
) else (
    echo MSYS2 already installed. Updating packages...
    powershell -NoProfile -Command "%MSYS2_DIR%\msys2_shell.cmd -defterm -here -no-start -c 'pacman -Syu --noconfirm'"
    echo Updating packages complete.
)

set SRC_DIR=%CD%\src

set MUJOCO_VERSION=3.3.0
set MUJOCO_ZIP_FILE=mujoco-%MUJOCO_VERSION%.zip
if not exist "%SRC_DIR%" (
    mkdir "%SRC_DIR%"
    powershell -NoProfile -Command "curl -o %SRC_DIR%\%MUJOCO_ZIP_FILE% https://github.com/google-deepmind/mujoco/archive/refs/tags/%MUJOCO_VERSION%.zip"
    powershell -NoProfile -Command "7z x '%SRC_DIR%\%MUJOCO_ZIP_FILE%' -o'%SRC_DIR%'"
    del "%SRC_DIR%\%MUJOCO_ZIP_FILE%"
)
set MUJOCO_SRC_DIR=%SRC_DIR%\mujoco-%MUJOCO_VERSION%
set BUILD_DIR=%CD%\build\mujoco-%MUJOCO_VERSION%
set INSTALL_DIR=%CD%\install\mujoco-%MUJOCO_VERSION%
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
)
if not exist "%BUILD_DIR%" (
    mkdir "%BUILD_DIR%"
)

xcopy /E /I /Y "%CD%\plugin\multiverse_connector" "%MUJOCO_SRC_DIR%\mujoco-%MUJOCO_VERSION%\plugin\multiverse_connector"
set CMAKE_PATH=%MUJOCO_SRC_DIR%\CMakeLists.txt
@REM set LINE_TO_ADD=add_subdirectory(plugin/multiverse_connector^^^)
@REM findstr /C:"%LINE_TO_ADD%" "%CMAKE_PATH%" >nul
@REM if errorlevel 1 (
@REM     echo %LINE_TO_ADD%>> "%CMAKE_PATH%"
@REM )

%MINGW32_CMAKE_EXE% -S "%MUJOCO_SRC_DIR%" -B "%BUILD_DIR%" -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%" -DMUJOCO_BUILD_EXAMPLES=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_BUILD_SIMULATE=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5
%MINGW32_CMAKE_EXE% --build "%BUILD_DIR%"
%MINGW32_CMAKE_EXE% --install "%BUILD_DIR%"

copy /Y "%BUILD_DIR%\lib\multiverse_connector.dll" "%CD%\mujoco_plugin"
xcopy /E /I /Y "%CD%\mujoco_plugin" "%INSTALL_DIR%\bin"

for /f %%a in ('powershell -Command "[int](Get-Date -UFormat %%s)"') do set END_TIME=%%a
set /a ELAPSED=%END_TIME% - %START_TIME%

echo Build completed in %ELAPSED% seconds

endlocal
