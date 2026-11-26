program TestComponentsSetup;
{<
  Non-interactive tests for cCHXSDL3Engine component initialization, using
  CHXTests. Components must be set up exactly once by AddComponent.

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}

uses
  SysUtils, CTypes, SDL3,
  ucCHXSDL3Engine, ucCHXSDL3Renderer, ucaCHXSDL3Component,
  ucCHXTestGroup, ucCHXTWConsole, ucCHXTWJSON, uCHXTestJSON;

const
  kRenderW = 320;
  kRenderH = 240;

type

  { cCountingComponent }

  cCountingComponent = class(caCHXSDL3Component)
  private
    FSetupCount : Integer;
    FFinishCount : Integer;
    FSetupBG, FSetupBD, FSetupHL : TSDL_FColor;
    FSetupLogPresW, FSetupLogPresH : CInt;
    FSetupLogPresMode : TSDL_RendererLogicalPresentation;
  public
    constructor Create;
    procedure Setup; override;
    procedure Finish; override;
    procedure Compute(const FrameTime : CUInt32;
      var ExitProg : Boolean); override;
    procedure Draw(const Render : cCHXSDL3Renderer); override;

    property SetupCount : Integer read FSetupCount;
    property FinishCount : Integer read FFinishCount;
    property SetupBG : TSDL_FColor read FSetupBG;
    property SetupBD : TSDL_FColor read FSetupBD;
    property SetupHL : TSDL_FColor read FSetupHL;
    property SetupLogPresW : CInt read FSetupLogPresW;
    property SetupLogPresH : CInt read FSetupLogPresH;
    property SetupLogPresMode : TSDL_RendererLogicalPresentation
      read FSetupLogPresMode;
  end;

  { cSetupTestEngine }

  cSetupTestEngine = class(cCHXSDL3Engine)
  private
    FAddInSetup : Boolean;
    FSetupCount : Integer;
    FCreatedComp : cCountingComponent;
  protected
    procedure Setup; override;
    procedure Finish; override;
    procedure Compute(var ExitProg : Boolean); override;
    procedure Draw; override;
  public
    constructor Create(const aAddInSetup : Boolean);
    function ExposeAddComponent(
      const aComp : caCHXSDL3Component) : caCHXSDL3Component;
    property SetupCount : Integer read FSetupCount;
    property CreatedComp : cCountingComponent read FCreatedComp;
  end;

  { cComponentSetupTests }

  {$PUSH}
  {$M+}
  cComponentSetupTests = class(cCHXTestGroup)
  private
    procedure CheckColor(const aColor : TSDL_FColor;
      const aR, aG, aB, aA : Single; const aLabel : String);
    procedure CheckComponent(const aComp : cCountingComponent;
      const aLabel : String);
    procedure CheckSingleCase(const aAddInSetup : Boolean);
  published
    procedure TestAddBeforeRun;
    procedure TestAddFromEngineSetup;
  end;
  {$POP}

{
  cCountingComponent
}

constructor cCountingComponent.Create;
begin
  inherited Create('Counter', 0, 0, 10, 10);
  FSetupCount := 0;
  FFinishCount := 0;
end;

procedure cCountingComponent.Setup;
begin
  Inc(FSetupCount);
  FSetupBG := BGColor;
  FSetupBD := BDColor;
  FSetupHL := HLColor;
  FSetupLogPresW := LogPresW;
  FSetupLogPresH := LogPresH;
  FSetupLogPresMode := LogPresMode;
end;

procedure cCountingComponent.Finish;
begin
  Inc(FFinishCount);
end;

procedure cCountingComponent.Compute(const FrameTime : CUInt32;
  var ExitProg : Boolean);
begin
end;

procedure cCountingComponent.Draw(const Render : cCHXSDL3Renderer);
begin
end;

{
  cSetupTestEngine
}

constructor cSetupTestEngine.Create(const aAddInSetup : Boolean);
begin
  inherited Create(False, 'ComponentSetup', kRenderW, kRenderH, 1, False,
    'software');
  FAddInSetup := aAddInSetup;
  FSetupCount := 0;
  FCreatedComp := nil;
end;

procedure cSetupTestEngine.Setup;
begin
  Inc(FSetupCount);
  if FAddInSetup then
  begin
    FCreatedComp := cCountingComponent.Create;
    ExposeAddComponent(FCreatedComp);
  end;
end;

procedure cSetupTestEngine.Finish;
begin
end;

procedure cSetupTestEngine.Compute(var ExitProg : Boolean);
begin
  ExitProg := True;
end;

procedure cSetupTestEngine.Draw;
begin
end;

function cSetupTestEngine.ExposeAddComponent(
  const aComp : caCHXSDL3Component) : caCHXSDL3Component;
begin
  Result := AddComponent(aComp);
end;

{
  cComponentSetupTests
}

procedure cComponentSetupTests.CheckColor(const aColor : TSDL_FColor;
  const aR, aG, aB, aA : Single; const aLabel : String);
begin
  MustEqual(aColor.R, aR, 0.001, aLabel + ' R');
  MustEqual(aColor.G, aG, 0.001, aLabel + ' G');
  MustEqual(aColor.B, aB, 0.001, aLabel + ' B');
  MustEqual(aColor.A, aA, 0.001, aLabel + ' A');
end;

procedure cComponentSetupTests.CheckComponent(
  const aComp : cCountingComponent; const aLabel : String);
begin
  MustTrue(Assigned(aComp), aLabel + ' exists');
  if not Assigned(aComp) then Exit;

  MustEqual(aComp.SetupCount, 1, aLabel + ' Setup calls');
  MustEqual(aComp.FinishCount, 1, aLabel + ' Finish calls');

  CheckColor(aComp.SetupBG, 0.5, 0.5, 0.5, 1.0, aLabel + ' BGColor');
  CheckColor(aComp.SetupBD, 0.25, 0.25, 0.25, 1.0, aLabel + ' BDColor');
  CheckColor(aComp.SetupHL, 1.0, 1.0, 0.0, 1.0, aLabel + ' HLColor');

  MustEqual(aComp.SetupLogPresW, kRenderW,
    aLabel + ' LogPresW');
  MustEqual(aComp.SetupLogPresH, kRenderH,
    aLabel + ' LogPresH');
  MustTrue(aComp.SetupLogPresMode = SDL_LOGICAL_PRESENTATION_LETTERBOX,
    aLabel + ' LogPresMode');
end;

procedure cComponentSetupTests.CheckSingleCase(const aAddInSetup : Boolean);
var
  Engine : cSetupTestEngine;
  BeforeComp : cCountingComponent;
begin
  Engine := cSetupTestEngine.Create(aAddInSetup);
  try
    Engine.Init;
    BeforeComp := cCountingComponent.Create;
    MustTrue(Engine.ExposeAddComponent(BeforeComp) = BeforeComp,
      'AddComponent returns the component');

    Engine.Run;

    MustEqual(Engine.SetupCount, 1, 'engine Setup calls');
    CheckComponent(BeforeComp, 'component added before Run');
    if aAddInSetup then
      CheckComponent(Engine.CreatedComp, 'component added from Setup');
  finally
    // The engine owns the components and frees them on destruction.
    Engine.Free;
  end;
end;

procedure cComponentSetupTests.TestAddBeforeRun;
begin
  CheckSingleCase(False);
end;

procedure cComponentSetupTests.TestAddFromEngineSetup;
begin
  CheckSingleCase(True);
end;

var
  MainTest : cComponentSetupTests;
  JSONWriter : cCHXTWJSON;

begin
  MainTest := cComponentSetupTests.Create;
  try
    MainTest.AddWriter(cCHXTWConsole);
    AddJSONWriter(MainTest, 'TestComponentsSetup', JSONWriter);
    ExitCode := MainTest.RunAllCases;
    CheckJSONSaveError(JSONWriter, ExitCode);
  finally
    MainTest.Free;
  end;
end.
