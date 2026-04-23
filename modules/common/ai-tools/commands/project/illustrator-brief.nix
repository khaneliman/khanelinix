let
  commandName = "illustrator-brief";
  description = "Produce a repo-grounded architecture brief for a human illustrator or diagramming tool";
  allowedTools = "Read, Grep, Glob";
  argumentHint = "[path]";
  prompt = ''
    Produce a comprehensive "illustrator brief" describing this project's architecture, intended for a human illustrator (or a diagramming tool) who will design the actual diagram.

    Target path: use `[path]` if provided, otherwise use the current working directory.

    Rules:

    1. Facts only. Do NOT prescribe layout, colors, icons, arrow directions, or visual style. The illustrator decides how the diagram should look.

    2. Be exhaustive about WHAT exists and HOW pieces connect. Cover whichever of these apply to this project:
       - Product framing: what the product is, who uses it, and which modules, apps, or major features are shipped today.
       - Client side: what runs in the user's browser or device (frameworks, UI libraries, styling, state, streaming or real-time mechanisms).
       - Identity and authentication: provider, tenant or realm, session mechanism, how protected routes or endpoints are enforced, any directory or profile APIs used.
       - Cloud / hosting resources: compute (app services, containers, serverless), container or artifact registries, managed databases and caches, secret stores, artificial intelligence / machine learning services and model deployments, observability and monitoring, file or blob storage, queues, content delivery networks, and any other cloud services in use. Include environment names (dev, staging, prod) and resource-group or project names where they exist.
       - Third-party software as a service and APIs the system depends on.
       - Backend runtime: language, runtime, HTTP server, build tool, object-relational mapper or data-access layer, validation, artificial intelligence orchestration software development kits, streaming, background jobs, tool calling. List the actual tools or capabilities each agent or service exposes if the system is agentic.
       - Data stores: tables, schemas, indexes (including vector or full-text), and where files live.
       - Source control, continuous integration / continuous delivery, and planning tooling.
       - A flat tech-stack inventory suitable for a legend.
       - The real data flows between components (numbered list).

    3. Ground everything in the current repo. Before writing the brief, read the most authoritative sources: the README, any CLAUDE.md or AGENTS.md files, route or entry-point definitions, environment variable schemas, package manifests (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.), database schema files, infrastructure-as-code (Terraform, Bicep, Pulumi, CloudFormation, Helm, etc.), continuous integration pipelines, and any module or feature directories. Update any detail that has drifted since the last brief.

    4. Output format: markdown, organized by topic sections. No visual-design suggestions, no "suggested layout", no "style notes". Do not describe what the diagram should look like; just describe what exists.

    5. Audience: a skilled illustrator who has never seen this codebase. Use complete sentences and expand acronyms on first use where it helps.

    Additional constraints:
    - If a category does not apply or cannot be verified from the repo, omit it instead of speculating.
    - Prefer concrete names from the repo over generic labels.
    - Do not modify repository files unless explicitly asked; return the brief in your response.
  '';
in
{
  ${commandName} = {
    inherit
      commandName
      description
      allowedTools
      argumentHint
      prompt
      ;
  };
}
