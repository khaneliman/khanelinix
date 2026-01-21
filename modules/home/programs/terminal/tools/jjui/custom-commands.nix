{
  "show all commits" = {
    key_sequence = [
      "\\"
      "a"
    ];
    revset = "all()";
  };
  "show default view" = {
    key_sequence = [
      "\\"
      "v"
    ];
    revset = "";
  };
  "edit immutable" = {
    key_sequence = [
      "\\"
      "e"
    ];
    args = [
      "edit"
      "--ignore-immutable"
      "-r"
      "$change_id"
    ];
  };
  "squash immutable" = {
    key_sequence = [
      "\\"
      "S"
    ];
    args = [
      "squash"
      "--ignore-immutable"
      "-r"
      "$change_id"
    ];
  };
  "split immutable" = {
    key_sequence = [
      "\\"
      "s"
    ];
    args = [
      "split"
      "--ignore-immutable"
      "-r"
      "$change_id"
    ];
  };
  "show diff" = {
    key_sequence = [
      "\\"
      "d"
    ];
    args = [
      "diff"
      "-r"
      "$change_id"
      "--color"
      "always"
    ];
    show = "diff";
  };
  "show oplog diff" = {
    key_sequence = [
      "\\"
      "o"
    ];
    args = [
      "op"
      "show"
      "$operation_id"
      "--color"
      "always"
    ];
    show = "diff";
  };
  "resolve vscode" = {
    key_sequence = [
      "\\"
      "r"
    ];
    args = [
      "resolve"
      "--tool"
      "vscode"
    ];
    show = "interactive";
  };
  "new main" = {
    key_sequence = [
      "\\"
      "n"
      "m"
    ];
    args = [
      "new"
      "main"
    ];
  };
  "tug" = {
    key_sequence = [
      "\\"
      "t"
    ];
    args = [
      "bookmark"
      "move"
      "--from"
      "closest_bookmark($change_id)"
      "--to"
      "closest_pushable($change_id)"
    ];
  };
  "show after revisions" = {
    key_sequence = [
      "\\"
      "a"
      "f"
    ];
    revset = "::$change_id";
  };
  "move commit down" = {
    key_sequence = [
      "\\"
      "m"
      "d"
    ];
    args = [
      "rebase"
      "-r"
      "$change_id"
      "--insert-before"
      "$change_id-"
    ];
  };
  "move commit up" = {
    key_sequence = [
      "\\"
      "m"
      "u"
    ];
    args = [
      "rebase"
      "-r"
      "$change_id"
      "--insert-after"
      "$change_id+"
    ];
  };
  "toggle parent" = {
    key_sequence = [
      "\\"
      "p"
    ];
    args = [
      "rebase"
      "-r"
      "@"
      "-d"
      "all:(parents(@) | $change_id) ~ (parents(@) & $change_id)"
    ];
  };
  "new note commit" = {
    key_sequence = [
      "\\"
      "n"
      "n"
    ];
    args = [
      "new"
      "--no-edit"
      "-A"
      "$change_id"
    ];
  };
}
