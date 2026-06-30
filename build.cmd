@echo off
setlocal

:: Read arguments passed from GitHub Actions
set ARCH=%~1
set BUILD_TYPE=%~2
set OBJ_LAYER=%~3
set DBL_PREC=%~4
set ASSERTS=%~5
set NAME_SUFFIX=%~6
set OUT_DATE=%~7

set DIST_DIR=JoltC-%ARCH%-%NAME_SUFFIX%-%OUT_DATE%
echo =======================================================
echo Configuring %DIST_DIR%
echo =======================================================

:: 1. Configure CMake
:: -S src tells CMake to look for the CMakeLists.txt inside the 'src' folder
cmake -S src -B build -A %ARCH% -DOBJECT_LAYER_BITS=%OBJ_LAYER% -DDOUBLE_PRECISION=%DBL_PREC% -DUSE_ASSERTS=%ASSERTS% -DUSE_STATIC_MSVC_RUNTIME_LIBRARY=OFF -DCMAKE_CXX_FLAGS="/Zc:enumTypes /wd4865"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo =======================================================
echo Building %DIST_DIR%
echo =======================================================

:: 2. Build the project
cmake --build build --config %BUILD_TYPE%
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

echo =======================================================
echo Packaging %DIST_DIR%
echo =======================================================

:: 3. Package the artifacts
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
mkdir "%DIST_DIR%\include\JoltC"

:: Copy C Headers (Now looking in src\JoltC)
xcopy /E /I /Y "src\JoltC\*" "%DIST_DIR%\include\JoltC\" >nul

:: Copy compiled libraries
if exist "build\%BUILD_TYPE%" (
    xcopy /E /I /Y "build\%BUILD_TYPE%\*" "%DIST_DIR%\" >nul
) else (
    copy "build\*.lib" "%DIST_DIR%\" >nul
    copy "build\*.dll" "%DIST_DIR%\" >nul
)

echo =======================================================
echo Zipping %DIST_DIR%
echo =======================================================

:: 4. Zip the output
if exist "%DIST_DIR%.zip" del "%DIST_DIR%.zip"
tar -a -c -f "%DIST_DIR%.zip" "%DIST_DIR%"

echo Successfully built and packaged %DIST_DIR%.zip