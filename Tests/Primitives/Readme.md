# CHXSDL3Renderer drawing primitives

Collection of programs to test drawing primitives of `cCHXSDL3Renderer`.

## Information

Many of the programs are simple tests of drawing and filling of the primitive;
others are specific tests (compare Circle algorithm vs Ellipse one).

## Compiling

From the main directory (where `build.sh` and `Build.bat` are):

### Unix-like:

```
./build.sh {Program}.pas
```

### Windows:

In a command line (easily opened with [Shift] + [R-Click] on the folder, and
then select "Open command line here" or similar):

```
Build.bat {Program}.pas
```

On Windows, the Free Pascal Compiler program is supposed to be in the
`PATH` environment variable and the executable's folder must have _SDL3.dll_
(and other _.dll_ if needed), and be sure that they are for the compiled
architecture (32/64 bits).

If Lazarus is used, it may be necessary to add the used unit folders to the
project manually.

### Scripts, Parameters and Executable

Both script files simply do the following:

1. Change to script directory.
2. Create FPC output directories.
3. Run `fpc @fpcfg.cfg {Program}.pas [OtherParameters]`

So,

- Additional FPC parameters can be passed to scripts to add or override
  _fpcfg.cfg_ ones.
- Parameter `-dRELEASE` generates a smart linked, stripped and optimized
  executable. By default, a debug one will be created with debug info, error
  checking fallback and `heaptrc` unit for memory leaks.

The executable program will be created in the `bin/` directory. As said in
_Compiling_, it needs _at least_ to find `SDL3.{dll|o}`. On Windows it's not
common to have it in a system folder, so it needs a copy of `SDL3.dll` in the
executable's folder.

Furthermore, the executable will change its current directory to the directory
where it resides to search external files if needed (its own _CHXSDL3Engine_
config file for example).

## Usage

By default some keys are assigned:

- **[F1]**: Toggle help text inside of the program.
- **[F11]**: Toggle FPS info.
- **[F10]** / **[F12]**: Decrease / Increase FPS.
- **[ESC]**: Exit the program.

Each program can have its own keys listed with **[F1]**, but in general:

- **[C]**: Change used colors.
- **[F]**: Change primitive draw and filling.
- **[P]**: Change points.
- **[R]**: Change rects.
