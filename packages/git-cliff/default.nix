{
  lib,
  pkgs,
  writeShellApplication,
  ...
}:
let
  git-cliff-config = pkgs.writeTextFile {
    name = "cliff.toml";
    text = # toml
      ''
         [changelog]
         # changelog header
         header = """
         # Changelog\n
         """
         # template for the changelog body
         # https://keats.github.io/tera/docs/#introduction
         body = """
         {% if version -%}
             ## [{{ version | trim_start_matches(pat="v") }}] - {{ timestamp | date(format="%Y-%m-%d") }}
         {% else -%}
             ## [Unreleased]
         {% endif -%}
         {% for group, commits in commits | group_by(attribute="group") %}
             ### {{ group }}
             {% for commit in commits %}
                 - {{ commit.message }}\
             {% endfor %}
         {% endfor %}\n
         """
         # template for the changelog footer
         footer = """
          This changelog has been generated automatically using the custom git-cliff hook for
          [git-hooks.nix](https://github.com/cachix/git-hooks.nix)
         """

         # remove the leading and trailing whitespace from the templates
         trim = true

         [git]
         # parse the commits based on https://www.conventionalcommits.org
         conventional_commits = false

        # filter out the commits that are not conventional
         filter_unconventional = false

        # process each line of a commit as an individual commit
         split_commits = false


        # regex for parsing and grouping commits
         commit_parsers = [
           { message = "^.*: add", group = "New" },
           { message = "^.*: init", group = "New" },
           { message = "^.*: support", group = "New" },
           { message = "^test", group = "New" },
           { message = "^doc", group = "Documentation", default_scope = "other" },
           { message = "^fix", group = "Fixes" },
           { message = "^.*: fix", group = "Fixes" },
           { message = "^.*: change", group = "Changed" },
           { message = "^.*: remove", group = "Removed" },
           { message = "^.*: delete", group = "Removed" },
           { message = "^.*", group = "Changed" },
         ]

         # protect breaking changes from being skipped due to matching a skipping commit_parser
         protect_breaking_commits = false

         # filter out the commits that are not matched by commit parsers
         filter_commits = true

         # regex for matching git tags
         tag_pattern = "v[0-9].*"

         # regex for skipping tags
         # skip_tags = "v0.1.0-beta.1"

         # regex for ignoring tags
         ignore_tags = ""

         # sort the tags topologically
         topo_order = false

         # sort the commits inside sections by oldest/newest order
         sort_commits = "newest"
      '';
  };
in
writeShellApplication {
  name = "git-cliff";

  meta = {
    mainProgram = "git-cliff";
  };

  runtimeInputs = with pkgs; [ git-cliff ];

  text = ''
    ${lib.getExe pkgs.git-cliff} \
    --output CHANGELOG.md \
    --config ${git-cliff-config.outPath}
  '';
}
