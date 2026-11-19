let
  inherit (builtins)
    attrNames
    concatStringsSep
    filter
    ;

  rootInputs = (import ../flake.nix).inputs;
  devInputs = (import ../flake/dev/flake.nix).inputs;
  readLock = path: builtins.fromJSON (builtins.readFile path);
  rootLock = readLock ../flake.lock;
  devLock = readLock ../flake/dev/flake.lock;
  lockedDevRoot = devLock.nodes.${devLock.nodes.${devLock.root}.inputs.root}.inputs;

  groups = import ../flake/input-groups.nix;
  grouped = builtins.groupBy (name: name) (
    builtins.concatMap (group: group.inputs) (builtins.attrValues groups)
  );
  duplicates = filter (name: builtins.length grouped.${name} > 1) (attrNames grouped);
  unknown = filter (name: !(rootInputs ? ${name})) (attrNames grouped);
  missing = filter (name: !(grouped ? ${name})) (attrNames rootInputs);

  rootFollow = name: builtins.match "root/([^/]+)" (devInputs.${name}.follows or "");
  retained = map (name: builtins.head (rootFollow name)) (
    filter (name: rootFollow name != null) (attrNames devInputs)
  );
  expectedNulls = filter (name: !(builtins.elem name retained)) (attrNames rootInputs);
  declaredNulls = filter (name: (devInputs.root.inputs.${name}.follows or null) == "") (
    attrNames devInputs.root.inputs
  );
  lockedNulls = filter (name: lockedDevRoot.${name} == [ ]) (attrNames lockedDevRoot);

  requireEmpty = label: names: names == [ ] || throw "${label}: ${concatStringsSep ", " names}";
  requireNames =
    label: expected: actual:
    expected == actual
    || throw "${label}: expected ${concatStringsSep ", " expected}; got ${concatStringsSep ", " actual}";
in
{
  updateGroupMembership =
    requireEmpty "Inputs repeated within or across update groups" duplicates
    && requireEmpty "Unknown update group inputs" unknown
    && requireEmpty "Inputs missing from update groups" missing;

  devRootNulls =
    requireNames "Root lock inputs" (attrNames rootInputs) (
      attrNames rootLock.nodes.${rootLock.root}.inputs
    )
    && requireNames "Dev lock root inputs" (attrNames rootInputs) (attrNames lockedDevRoot)
    && requireNames "Declared dev root null inputs" expectedNulls declaredNulls
    && requireNames "Locked dev root null inputs" expectedNulls lockedNulls;
}
