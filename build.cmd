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
echo Building %DIST_DIR%
echo =======================================================

:: 1. Configure CMake
cmake -B build -A %ARCH% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DOBJECT_LAYER_BITS=%OBJ_LAYER% -DDOUBLE_PRECISION=%DBL_PREC% -DUSE_ASSERTS=%ASSERTS% -DUSE_STATIC_MSVC_RUNTIME_LIBRARY=OFF
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: 2. Build the project
cmake --build build --config %BUILD_TYPE%
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: 3. Package the artifacts
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
mkdir "%DIST_DIR%\include\JoltC"

:: Copy C Headers
xcopy /E /I /Y "JoltC\*" "%DIST_DIR%\include\JoltC\" >nul

:: Copy compiled libraries
if exist "build\%BUILD_TYPE%" (
    xcopy /E /I /Y "build\%BUILD_TYPE%\*" "%DIST_DIR%\" >nul
) else (
    copy "build\*.lib" "%DIST_DIR%\" >nul
    copy "build\*.dll" "%DIST_DIR%\" >nul
)

:: 4. Zip the output using native Windows tar
if exist "%DIST_DIR%.zip" del "%DIST_DIR%.zip"
tar -a -c -f "%DIST_DIR%.zip" "%DIST_DIR%"

echo Successfully built and packaged %DIST_DIR%.zip