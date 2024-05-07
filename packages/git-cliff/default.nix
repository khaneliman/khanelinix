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
          All notable changes to this project will be documented in this file.

          """
          # template for the changelog body
          # https://keats.github.io/tera/docs/#introduction
          body = """
          {%- macro remote_url() -%}
            https://github.com/{{ remote.github.owner }}/{{ remote.github.repo }}
          {%- endmacro -%}

          {% if version -%}
              ## [{{ version | trim_start_matches(pat="v") }}] - {{ timestamp | date(format="%Y-%m-%d") }}
          {% else -%}
              ## [Unreleased]
          {% endif -%}

          ### Details\

          {% for group, commits in commits | group_by(attribute="group") %}
              #### {{ group | upper_first }}
              {%- for commit in commits %}
                  - {{ commit.message | upper_first | trim }}\
                      {% if commit.github.username %} by @{{ commit.github.username }}{%- endif -%}
                      {% if commit.github.pr_number %} in \
                        [#{{ commit.github.pr_number }}]({{ self::remote_url() }}/pull/{{ commit.github.pr_number }}) \
                      {%- endif -%}
              {% endfor %}
          {% endfor %}

          {%- if github.contributors | filter(attribute="is_first_time", value=true) | length != 0 %}
            ## New Contributors
          {%- endif -%}

          {% for contributor in github.contributors | filter(attribute="is_first_time", value=true) %}
            * @{{ contributor.username }} made their first contribution
              {%- if contributor.pr_number %} in \
                [#{{ contributor.pr_number }}]({{ self::remote_url() }}/pull/{{ contributor.pr_number }}) \
              {%- endif %}
          {%- endfor %}\n
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
