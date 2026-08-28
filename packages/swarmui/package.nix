{
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  git,
  lib,
  python3,
  stdenv,
  ...
}:
let
  runtimeId = dotnetCorePackages.systemToDotnetRid stdenv.hostPlatform.system;
in
buildDotnetModule (finalAttrs: {
  pname = "swarmui";
  version = "0.9.8-beta";

  src = fetchFromGitHub {
    owner = "mcmonkeyprojects";
    repo = "SwarmUI";
    rev = "0.9.8-Beta";
    hash = "sha256-VutWPuhiRY+9vosua7Y7hjHDtS9QnS+aZl72SFQ/Z88=";
  };

  patches = [ ./fix-comfyui-idle-monitor.patch ];

  projectFile = "src/SwarmUI.csproj";
  nugetDeps = ./deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.sdk_8_0;
  inherit runtimeId;

  dontPublish = true;
  installPath = "${placeholder "out"}/lib/swarmui";
  executables = [ "SwarmUI" ];

  postPatch = ''
    # Release archives have no Git metadata, so the commit-date probe cannot
    # provide useful information and must not emit an error on every start.
    substituteInPlace src/Core/Program.cs \
      --replace-fail \
        'Logs.Error($"Failed to get git commit date: {ex.ReadableString()}");' \
        'Logs.Debug($"Failed to get git commit date: {ex.ReadableString()}");'

    substituteInPlace \
      src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyCommon/__init__.py \
      --replace-fail \
        'register_model_folder("yolov8")' \
        'register_model_folder("yolov8")
    register_model_folder("clipseg")'
  '';

  postInstall = ''
    mkdir -p "$out/lib/swarmui"
    mkdir -p "$out/share/swarmui"

    cp -r src/bin/Release/net8.0/${runtimeId}/. "$out/lib/swarmui/"
    cp -r languages launchtools "$out/share/swarmui/"
    cp -r src "$out/share/swarmui/"
    rm -rf "$out/share/swarmui/src/bin" "$out/share/swarmui/src/obj"
    rm -rf "$out/share/swarmui/src/Extensions"
  '';

  postFixup = ''
    mv "$out/bin/SwarmUI" "$out/bin/swarmui"
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    git
    python3
  ];
  installCheckPhase = ''
    runHook preInstallCheck

    test -d "$out/share/swarmui/src/BuiltinExtensions/ComfyUIBackend/ExtraNodes"
    test ! -e "$out/share/swarmui/src/Extensions"
    "$out/bin/swarmui" --help

    python3 - \
      "$out/share/swarmui/src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyCommon/__init__.py" \
      "$out/share/swarmui/src/BuiltinExtensions/ComfyUIBackend/ExtraNodes/SwarmComfyCommon/SwarmClipSeg.py" \
      <<'PY'
    import ast
    import os
    import sys
    import tempfile
    from pathlib import Path
    from types import SimpleNamespace

    init_path, clipseg_path = map(Path, sys.argv[1:])
    init_tree = ast.parse(init_path.read_text())
    registrations = {
        call.args[0].value
        for call in ast.walk(init_tree)
        if isinstance(call, ast.Call)
        and isinstance(call.func, ast.Name)
        and call.func.id == "register_model_folder"
        and call.args
        and isinstance(call.args[0], ast.Constant)
    }
    assert "clipseg" in registrations

    clipseg_tree = ast.parse(clipseg_path.read_text())
    get_path = next(
        node
        for node in clipseg_tree.body
        if isinstance(node, ast.FunctionDef) and node.name == "get_path"
    )
    namespace = {"os": os}
    with tempfile.TemporaryDirectory() as model_root:
        expected = Path(model_root) / "clipseg"
        namespace["folder_paths"] = SimpleNamespace(
            folder_names_and_paths={"clipseg": ([str(expected)], set())}
        )
        exec(compile(ast.Module([get_path], []), str(clipseg_path), "exec"), namespace)
        actual = Path(namespace["get_path"]())
        assert actual == expected
        actual.mkdir()
        (actual / "write-probe").touch()
    PY

    fixtureRepo="$TMPDIR/swarmui-extension-fixture"
    state="$TMPDIR/swarmui-state"
    runtime="$state/runtime"
    extensions="$state/src/Extensions"
    mkdir -p "$fixtureRepo" "$runtime" "$extensions" "$state/src/bin"
    cp -r ${./tests/extension-fixture}/. "$fixtureRepo/"
    chmod -R u+w "$fixtureRepo"
    mv "$fixtureRepo/FixtureExtension.cs.in" "$fixtureRepo/FixtureExtension.cs"

    git -C "$fixtureRepo" init --quiet
    git -C "$fixtureRepo" config user.email fixture@example.invalid
    git -C "$fixtureRepo" config user.name "SwarmUI fixture"
    git -C "$fixtureRepo" add .
    git -C "$fixtureRepo" -c commit.gpgSign=false commit --quiet -m fixture

    cp -r "$out/share/swarmui"/. "$runtime/"
    mkdir -p "$runtime/Data" "$runtime/src/bin"
    for sourceFile in \
      GlobalSuppressions.cs \
      GlobalUsings.cs \
      SwarmUI.deps.props \
      SwarmUI.extension.props; do
      ln -s "$out/share/swarmui/src/$sourceFile" "$state/src/$sourceFile"
    done
    ln -s "$out/lib/swarmui" "$state/src/bin/live_release"
    ln -s "$out/lib/swarmui" "$runtime/src/bin/live_release"
    ln -s ../../src/Extensions "$runtime/src/Extensions"
    git clone --quiet "$fixtureRepo" "$extensions/Fixture"

    install -m 0600 /dev/null "$runtime/Data/Backends.fds"
    printf '%s\n' \
      'IsInstalled: true' \
      'LaunchMode: none' \
      'Maintenance:' \
      '    CheckForUpdates: false' \
      > "$runtime/Data/Settings.fds"

    export DOTNET_CLI_HOME="$TMPDIR/dotnet"
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export HOME="$TMPDIR/home"
    export NUGET_PACKAGES="$TMPDIR/nuget"
    mkdir -p "$DOTNET_CLI_HOME" "$HOME" "$NUGET_PACKAGES"

    for attempt in 1 2; do
      (
        cd "$runtime"
        timeout --signal=INT 15 \
          "$out/bin/swarmui" \
          --backends_file "$runtime/Data/Backends.fds" \
          --data_dir "$runtime/Data" \
          --host 127.0.0.1 \
          --launch_mode none \
          --port 17802 \
          --settings_file "$runtime/Data/Settings.fds"
      ) > "$TMPDIR/swarmui-extension-$attempt.log" 2>&1 || true

      if ! grep -F \
        'Prepping extension: SwarmFixture.FixtureExtension' \
        "$TMPDIR/swarmui-extension-$attempt.log"; then
        cat "$TMPDIR/swarmui-extension-$attempt.log"
        exit 1
      fi
    done

    test -e \
      "$runtime/src/bin/extensions/SwarmExtensionFixture/SwarmExtensionFixture.dll"

    runHook postInstallCheck
  '';

  meta = {
    description = "Web interface for AI image and video generation";
    homepage = "https://github.com/mcmonkeyprojects/SwarmUI";
    changelog = "https://github.com/mcmonkeyprojects/SwarmUI/releases/tag/${finalAttrs.src.rev}";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.khaneliman ];
    mainProgram = "swarmui";
    platforms = lib.platforms.linux;
    sourceProvenance = [
      lib.sourceTypes.fromSource
      lib.sourceTypes.binaryBytecode
      lib.sourceTypes.binaryNativeCode
    ];
  };
})
