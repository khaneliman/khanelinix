# Hello, World in .NET

This flake defines:

- `nix run .#fantomas -- -r .` to run the
  [Fantomas](https://fsprojects.github.io/fantomas/) F# source formatter.
- `nix develop . --command alejandra .` to run the
  [Alejandra](https://github.com/kamadorueda/alejandra) Nix source formatter.
- `nix develop . --command markdown-link-check README.md` to check that this
  README's links are not broken.
- `nix run . -- Nix` to run the application.
- `nix run .#fetchDeps -- nix/deps.json` to regenerate the
  [NuGet lockfile](./nix/deps.json).

## Development

After changing the [NuGet] dependencies of either project, rerun
`nix run .#fetchDeps -- nix/deps.json`. The Nix build restores packages from
this lockfile without contacting NuGet.

## Style guidelines

This template is _opinionated_ about the style guidelines it uses. The F#
community at large tends to disagree with these guidelines, and you may wish to
adjust the [editorconfig](./.editorconfig) file to suit your own needs.

[NuGet]: https://www.nuget.org
