{
  gatewayEnabled ? false,
  lib,
  ...
}:
let
  registry = builtins.fromJSON (
    builtins.readFile ./skills/multi-provider-sdlc/references/model-routing.json
  );
  inherit (registry) models;
  semanticRoles = registry.semantic_roles;
  modelIds = builtins.attrNames models;
  controlCharacters = lib.stringToCharacters (
    builtins.fromJSON ''"\u0001\u0002\u0003\u0004\u0005\u0006\u0007\u0008\u0009\u000a\u000b\u000c\u000d\u000e\u000f\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001a\u001b\u001c\u001d\u001e\u001f\u007f"''
  );

  containsControlCharacter =
    value: lib.any (character: lib.hasInfix character value) controlCharacters;
  policyContainsControlCharacter =
    value:
    if builtins.isString value then
      containsControlCharacter value
    else if builtins.isList value then
      lib.any policyContainsControlCharacter value
    else if builtins.isAttrs value then
      lib.any (name: containsControlCharacter name || policyContainsControlCharacter value.${name}) (
        builtins.attrNames value
      )
    else
      false;

  modelExists = model: builtins.hasAttr model models;
  roleExists = role: builtins.hasAttr role semanticRoles;
  modelFor = model: models.${model};
  gatewayAliasFor = model: (modelFor model).gateway_alias;

  semanticModelReferences = lib.concatMap (role: builtins.attrValues (role.gateway or { })) (
    builtins.attrValues semanticRoles
  );
  taskModelReferences = lib.concatMap (
    route: route.preferred ++ route.fallbacks
  ) registry.task_routes;
  deliberationReferences = builtins.attrValues registry.deliberation;
  defaultReferences = builtins.attrValues registry.gateway_defaults;
  missingModels = lib.unique (
    builtins.filter (model: !modelExists model) (
      semanticModelReferences
      ++ taskModelReferences
      ++ deliberationReferences
      ++ defaultReferences
      ++ registry.cliproxy_alias_order
    )
  );
  missingRoles = lib.unique (
    builtins.filter (role: !roleExists role) (map (route: route.semantic_role) registry.task_routes)
  );
  aliases = map (model: (modelFor model).gateway_alias) modelIds;
  duplicateAliases = lib.length aliases != lib.length (lib.unique aliases);
  publishedModels = builtins.filter (model: (modelFor model).publish_alias) modelIds;
  missingPublishedAliases = builtins.filter (
    model: !(lib.elem model registry.cliproxy_alias_order)
  ) publishedModels;
  unexpectedPublishedAliases = builtins.filter (
    model: !(lib.elem model publishedModels)
  ) registry.cliproxy_alias_order;
  duplicatePublishedAliases =
    lib.length registry.cliproxy_alias_order != lib.length (lib.unique registry.cliproxy_alias_order);

  resolveGatewayModel =
    provider: model:
    let
      alias = gatewayAliasFor model;
    in
    if provider == "opencode" then "cliproxyapi/${alias}" else alias;

  modelsForRole =
    role:
    let
      route = semanticRoles.${role};
      gatewayModels = lib.mapAttrs resolveGatewayModel route.gateway;
    in
    route.native // lib.optionalAttrs gatewayEnabled gatewayModels;

  gatewayAgentSpecs = lib.mapAttrs (name: model: {
    inherit name;
    alias = model.gateway_alias;
    inherit (model) description;
    reasoningEffort = model.reasoning_effort;
    inherit (model) write;
    workspaceWrite = model.workspace_write;
  }) models;

  cliproxyAliases = map (
    name:
    let
      model = modelFor name;
    in
    {
      provider = model.upstream_provider;
      alias = model.gateway_alias;
      model = model.upstream_model;
      displayName = model.display_name;
    }
  ) registry.cliproxy_alias_order;

  directGatewayModels = builtins.listToAttrs (
    map (name: {
      name = (modelFor name).gateway_alias;
      value.name = (modelFor name).display_name;
    }) (builtins.filter (name: !(modelFor name).publish_alias) modelIds)
  );

  directGatewayModelsFor =
    configuredModels: claudeModel:
    directGatewayModels
    // lib.optionalAttrs (!(builtins.hasAttr claudeModel (directGatewayModels // configuredModels))) (
      builtins.listToAttrs [
        {
          name = claudeModel;
          value.name = (modelFor registry.gateway_defaults.claude).display_name;
        }
      ]
    );

  defaultUpstreamModels = lib.mapAttrs (
    _provider: model: (modelFor model).upstream_model
  ) registry.gateway_defaults;
in
if registry.schema_version != 2 then
  throw "Unsupported model-routing schema: ${toString registry.schema_version}"
else if policyContainsControlCharacter registry then
  throw "Model-routing policy text must not contain control characters"
else if missingModels != [ ] then
  throw "Unknown model-routing references: ${lib.concatStringsSep ", " missingModels}"
else if missingRoles != [ ] then
  throw "Unknown semantic role references: ${lib.concatStringsSep ", " missingRoles}"
else if duplicateAliases then
  throw "Model-routing gateway aliases must be unique"
else if missingPublishedAliases != [ ] then
  throw "CLIProxy alias order omits published models: ${lib.concatStringsSep ", " missingPublishedAliases}"
else if unexpectedPublishedAliases != [ ] then
  throw "CLIProxy alias order contains unpublished models: ${lib.concatStringsSep ", " unexpectedPublishedAliases}"
else if duplicatePublishedAliases then
  throw "CLIProxy alias order must contain unique model IDs"
else
  {
    inherit
      cliproxyAliases
      defaultUpstreamModels
      directGatewayModelsFor
      gatewayAgentSpecs
      models
      modelsForRole
      registry
      semanticRoles
      ;

    reasoningEffortForRole = role: semanticRoles.${role}.reasoning_effort;
  }
