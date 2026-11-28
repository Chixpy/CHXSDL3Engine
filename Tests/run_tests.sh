#!/bin/sh
# Headless test runner for CHXSDL3Engine.
# CHXTests exit codes: 0 ok, 1 assertion failed, 2 error, 3 skipped.
# SDL_VIDEODRIVER may be set by the caller; it defaults to dummy.

set -u

cd "$(dirname "$0")" || exit 2

export SDL_VIDEODRIVER="${SDL_VIDEODRIVER-dummy}"

RunStep()
{
  Label="$1"
  shift
  printf '\n== %s ==\n' "$Label"
  "$@"
  Status=$?
  if [ "$Status" -ne 0 ]; then
    printf 'FAIL: %s (exit %s)\n' "$Label" "$Status" >&2
    exit "$Status"
  fi
}

RunStep 'build TestConfig' ./build.sh TestConfig.pas
RunStep 'build SmokePrimitives' ./build.sh SmokePrimitives.pas
RunStep 'build TestComponentsSetup' ./build.sh TestComponentsSetup.pas
RunStep 'build TestScreenshot' ./build.sh TestScreenshot.pas
RunStep 'build TestFontBitmap' ./build.sh TestFontBitmap.pas
RunStep 'build TestPrimitivesPixels' ./build.sh TestPrimitivesPixels.pas
RunStep 'TestConfig' ./bin/TestConfig
RunStep 'SmokePrimitives' ./bin/SmokePrimitives
RunStep 'TestComponentsSetup' ./bin/TestComponentsSetup
RunStep 'TestScreenshot' ./bin/TestScreenshot
RunStep 'TestFontBitmap' ./bin/TestFontBitmap
RunStep 'TestPrimitivesPixels' ./bin/TestPrimitivesPixels

printf '\nAll headless suites passed.\n'
