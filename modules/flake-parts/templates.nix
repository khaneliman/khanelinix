{
  flake.templates = builtins.listToAttrs (
    map (name: {
      name = name;
      value = {
        path = ../../templates/${name};
        description = "${name} template";
      };
    }) (builtins.attrNames (builtins.readDir ../../templates))
  );
}
