{
  lib,
  fetchFromGitHub,
  python3Packages,
  ...
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "freecad-mcp";
  version = "0.1.27";

  src = fetchFromGitHub {
    owner = "neka-nat";
    repo = "freecad-mcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-BGxa7+wa9QwiR1R2fs//ksMVfhzqklr0sybPwHYgIYQ=";
  };

  pyproject = true;
  build-system = [ python3Packages.hatchling ];
  dependencies = with python3Packages; [
    mcp
    validators
  ];

  # MCP filters the subprocess environment, hiding Nix's Python dependencies.
  postPatch = ''
    substituteInPlace tests/test_tool_errors.py \
      --replace-fail 'import json' $'import json\nimport os' \
      --replace-fail 'args=[str(Path(__file__))])' \
        'args=[str(Path(__file__))], env={"PYTHONPATH": os.pathsep.join(sys.path)})'
  '';

  nativeCheckInputs = [ python3Packages.pytestCheckHook ];
  pythonImportsCheck = [ "freecad_mcp.server" ];
  # RPC tests bind loopback sockets inside the Darwin build sandbox.
  __darwinAllowLocalNetworking = true;

  postInstall = ''
    install -d "$out/share/freecad-mcp"
    cp -r addon/FreeCADMCP "$out/share/freecad-mcp/"
    install -m644 LICENSE "$out/share/freecad-mcp/LICENSE"
  '';

  postCheck = ''
    "$out/bin/freecad-mcp" --help >/dev/null
  '';

  meta = {
    description = "MCP server and FreeCAD add-on for parametric modeling";
    homepage = "https://github.com/neka-nat/freecad-mcp";
    license = lib.licenses.mit;
    mainProgram = "freecad-mcp";
    maintainers = [ lib.maintainers.khaneliman ];
    platforms = lib.platforms.unix;
  };
})
