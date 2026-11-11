@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul

pushd "%~dp0"
mkdir bin > nul
mkdir lib > nul

echo Compiling tests...
fpc @fpcfg.cfg %*
set "ERRCOMP=!ERRORLEVEL!"

popd

exit /b %ERRCOMP%
