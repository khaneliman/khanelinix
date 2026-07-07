let
  commandName = "illustrator-brief";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Produce a repo-grounded architecture brief for a human illustrator or diagramming tool";
    allowedTools = "Read, Grep, Glob";
    argumentHint = "[path]";
    prompt = ''
      Produce repo-grounded architecture brief for human illustrator or diagramming
      tool. Target `[path]` or current directory.

      Rules:
      - Facts only. Do not prescribe layout, color, icons, arrows, or style.
      - Ground claims in authoritative repo sources: README, AGENTS/CLAUDE/GEMINI
        docs, entrypoints/routes, env schemas, manifests, database schemas, IaC,
        CI, and feature/module directories.
      - Cover applicable verified categories: product framing, client, auth,
        cloud/hosting, third-party services, backend runtime, agent/tool
        capabilities, data stores, source control/CI/planning, tech-stack legend,
        and numbered real data flows.
      - Omit unverified or non-applicable categories instead of speculating.
      - Output markdown topic sections for illustrator unfamiliar with repo.
      - Expand helpful acronyms on first use.
      - Do not modify files unless explicitly asked.
    '';
  };
}
