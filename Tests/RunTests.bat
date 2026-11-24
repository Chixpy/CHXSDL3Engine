@echo off
setlocal
chcp 65001 > nul
rem CHXTests exit codes: 0 ok, 1 failed assertion, 2 error, 3 skipped.

pushd "%~dp0"
if not defined SDL_VIDEODRIVER set "SDL_VIDEODRIVER=dummy"

echo.
echo == build TestConfig ==
set "STEP=build TestConfig"
call Build.bat TestConfig.pas
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :fail

echo.
echo == build SmokePrimitives ==
set "STEP=build SmokePrimitives"
call Build.bat SmokePrimitives.pas
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :fail

echo.
echo == build TestComponentsSetup ==
set "STEP=build TestComponentsSetup"
call Build.bat TestComponentsSetup.pas
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :fail

echo.
echo == build TestScreenshot ==
set "STEP=build TestScreenshot"
call Build.bat TestScreenshot.pas
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :fail

echo.
echo == TestConfig ==
set "STEP=TestConfig"
bin\TestConfig.exe
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :fail

echo.
echo == SmokePrimitives ==
set "STEP=SmokePrimitives"
bin\SmokePrimitives.exe
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :fail

echo.
echo == TestComponentsSetup ==
set "STEP=TestComponentsSetup"
bin\TestComponentsSetup.exe
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :fail

echo.
echo == TestScreenshot ==
set "STEP=TestScreenshot"
bin\TestScreenshot.exe
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :fail

echo.
echo All headless suites passed.
popd
endlocal
exit /b 0

:fail
echo.
echo FAIL: %STEP% (exit %RC%) 1>&2
popd
endlocal & exit /b %RC%
