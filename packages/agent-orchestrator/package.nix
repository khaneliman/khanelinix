{
  lib,
  python3,
  makeWrapper,
  stdenv,
  ...
}:
stdenv.mkDerivation {
  pname = "agent-orchestrator";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp agent_loop.py $out/bin/agent-orchestrator
    chmod +x $out/bin/agent-orchestrator

    wrapProgram $out/bin/agent-orchestrator \
      --prefix PATH : ${lib.makeBinPath [ python3 ]}

    runHook postInstall
  '';

  # Runtime expects codex, claude, and agy CLIs in PATH.
  # These are user-installed (not in nixpkgs) and come from:
  #   codex  — OpenAI Codex Pro plan
  #   claude — Anthropic Claude Code Max plan
  #   agy    — Google Gemini AI Plus plan (Antigravity CLI)

  meta = {
    description = "Multi-provider agentic task orchestrator with automatic fallback across OpenAI, Anthropic, and Google plans";
    license = lib.licenses.unfree;
    mainProgram = "agent-orchestrator";
    platforms = lib.platforms.all;
  };
}
