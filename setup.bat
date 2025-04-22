@echo off
setlocal EnableDelayedExpansion

for /f %%a in ('powershell -Command "[int](Get-Date -UFormat %%s)"') do set START_TIME=%%a

set CURRENT_DIR=%CD%
cd /d %~dp0

set "EXT_DIR=%CD%\ext"
set "CMAKE_DIR=%EXT_DIR%\cmake"
set "CMAKE_FILE_NAME=cmake-4.0.1-windows-x86_64"
set "CMAKE_ZIP_FILE=%CMAKE_FILE_NAME%.zip"
if not exist "%CMAKE_DIR%" (
    if not exist "%EXT_DIR%\%CMAKE_ZIP_FILE%" (
        powershell -NoProfile -Command "curl -o '%EXT_DIR%\%CMAKE_ZIP_FILE%' 'https://github.com/Kitware/CMake/releases/download/v4.0.1/%CMAKE_ZIP_FILE%'"
    )
    powershell -NoProfile -Command "7z x '%EXT_DIR%\%CMAKE_ZIP_FILE%' -o'%EXT_DIR%'"
    powershell -NoProfile -Command "move '%EXT_DIR%\%CMAKE_FILE_NAME%' '%CMAKE_DIR%'"
    del "%EXT_DIR%\%CMAKE_ZIP_FILE%"
)
set "CMAKE_EXECUTABLE=%CMAKE_DIR%\bin\cmake.exe"

set "CMAKE_BUILD_DIR=%EXT_DIR%\vcpkg"
set "VCPKG_DIR=%EXT_DIR%\vcpkg"
if not exist "%VCPKG_DIR%" (
    git clone https://github.com/Microsoft/vcpkg.git "%VCPKG_DIR%"
    cd "%VCPKG_DIR%"
    bootstrap-vcpkg.bat
    cd %EXT_DIR%
    .\vcpkg\vcpkg.exe install
)

set SRC_DIR=%CD%\src

set MUJOCO_VERSION=3.3.0
set MUJOCO_SRC_DIR=%SRC_DIR%\mujoco-%MUJOCO_VERSION%
set MUJOCO_ZIP_FILE=mujoco-%MUJOCO_VERSION%.zip
if not exist "%SRC_DIR%" (
    mkdir "%SRC_DIR%"
    powershell -NoProfile -Command "curl -o %SRC_DIR%\%MUJOCO_ZIP_FILE% https://github.com/google-deepmind/mujoco/archive/refs/tags/%MUJOCO_VERSION%.zip"
    powershell -NoProfile -Command "7z x '%SRC_DIR%\%MUJOCO_ZIP_FILE%' -o'%SRC_DIR%'"
    del "%SRC_DIR%\%MUJOCO_ZIP_FILE%"
)

set BUILD_DIR=%CD%\build\mujoco-%MUJOCO_VERSION%
set INSTALL_DIR=%CD%\install\mujoco-%MUJOCO_VERSION%
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
)
if not exist "%BUILD_DIR%" (
    mkdir "%BUILD_DIR%"
)

xcopy /E /I /Y "%CD%\plugin\multiverse_connector" "%MUJOCO_SRC_DIR%\plugin\multiverse_connector"
set CMAKE_PATH=%MUJOCO_SRC_DIR%\CMakeLists.txt
set LINE_TO_ADD=add_subdirectory(plugin/multiverse_connector^^^)
findstr /C:"plugin/multiverse_connector" "%CMAKE_PATH%" >nul
if errorlevel 1 (
    echo %LINE_TO_ADD%>> "%CMAKE_PATH%"
)

%CMAKE_EXECUTABLE% -S "%MUJOCO_SRC_DIR%" -B "%BUILD_DIR%" -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%" -DMUJOCO_BUILD_EXAMPLES=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_BUILD_SIMULATE=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF -DCMAKE_POLICY_VERSION_MINIMUM="3.5" -Wno-deprecated -Wno-dev
%CMAKE_EXECUTABLE% --build "%BUILD_DIR%" --config Release
%CMAKE_EXECUTABLE% --install "%BUILD_DIR%"

set "MUJOCO_PLUGIN_DIR=%CD%\mujoco_plugin\mujoco-%MUJOCO_VERSION%"
if not exist "%MUJOCO_PLUGIN_DIR%" (
    mkdir "%MUJOCO_PLUGIN_DIR%"
)
copy /Y "%BUILD_DIR%\bin\Release\multiverse_connector.dll" "%MUJOCO_PLUGIN_DIR%"
xcopy /E /I /Y "%MUJOCO_PLUGIN_DIR%" "%INSTALL_DIR%\bin\mujoco_plugin"

for /f %%a in ('powershell -Command "[int](Get-Date -UFormat %%s)"') do set END_TIME=%%a
set /a ELAPSED=%END_TIME% - %START_TIME%

echo Build completed in %ELAPSED% seconds

endlocal
