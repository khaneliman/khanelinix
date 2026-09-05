# jjui 0.10 replaced [custom_commands] with [[actions]] and [[bindings]].
# Builtin actions cover most former commands; the rest run through Lua.
let
  leader = "\\";
  seq = keys: [ leader ] ++ keys;
  luaAction = name: lua: { inherit name lua; };
  jjAsync = name: args: luaAction name "jjui.jj_async(${args})";
  revsetAction = name: revset: luaAction name "jjui.revset.set(${builtins.toJSON revset})";
  bind = action: keys: desc: {
    inherit action desc;
    scope = "revisions";
    seq = seq keys;
  };
in
{
  actions = [
    (revsetAction "custom.show_all" "all()")
    (luaAction "custom.show_ancestors" ''
      jjui.revset.set("::" .. jjui.context.change_id())
    '')
    (jjAsync "custom.squash_immutable" ''
      "squash", "--ignore-immutable", "-r", jjui.context.change_id()
    '')
    (jjAsync "custom.split_immutable" ''
      "split", "--ignore-immutable", "-r", jjui.context.change_id()
    '')
    (luaAction "custom.resolve_vscode" ''
      jjui.jj_interactive("resolve", "--tool", "vscode")
    '')
    (jjAsync "custom.new_main" ''"new", "main"'')
    (jjAsync "custom.tug" ''
      "bookmark", "move",
      "--from", "closest_bookmark(" .. jjui.context.change_id() .. ")",
      "--to", "closest_pushable(" .. jjui.context.change_id() .. ")"
    '')
    (jjAsync "custom.move_down" ''
      "rebase", "-r", jjui.context.change_id(),
      "--insert-before", jjui.context.change_id() .. "-"
    '')
    (jjAsync "custom.move_up" ''
      "rebase", "-r", jjui.context.change_id(),
      "--insert-after", jjui.context.change_id() .. "+"
    '')
    (jjAsync "custom.toggle_parent" ''
      "rebase", "-r", "@", "-d",
      "all:(parents(@) | " .. jjui.context.change_id() .. ") ~ (parents(@) & " .. jjui.context.change_id() .. ")"
    '')
    (jjAsync "custom.new_note_commit" ''
      "new", "--no-edit", "-A", jjui.context.change_id()
    '')
  ];

  bindings = [
    (bind "custom.show_all" [ "a" ] "show all commits")
    (bind "revset.reset" [ "v" ] "show default view")
    # Formerly \ a f, which shadowed \ a as a sequence prefix.
    (bind "custom.show_ancestors" [ "A" ] "show ancestors")
    (bind "revisions.force_edit" [ "e" ] "edit immutable")
    (bind "custom.squash_immutable" [ "S" ] "squash immutable")
    (bind "custom.split_immutable" [ "s" ] "split immutable")
    (bind "revisions.diff" [ "d" ] "show diff")
    (bind "custom.resolve_vscode" [ "r" ] "resolve in vscode")
    (bind "custom.new_main" [ "n" "m" ] "new on main")
    (bind "custom.tug" [ "t" ] "tug bookmark")
    (bind "custom.move_down" [ "m" "d" ] "move commit down")
    (bind "custom.move_up" [ "m" "u" ] "move commit up")
    (bind "custom.toggle_parent" [ "p" ] "toggle parent")
    (bind "custom.new_note_commit" [ "n" "n" ] "new note commit")
    {
      action = "oplog.diff";
      desc = "show oplog diff";
      scope = "oplog";
      seq = seq [ "o" ];
    }
  ];
}
