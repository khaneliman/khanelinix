# Module Testing

Pick the cheapest tier that can observe the behavior in question. Most module
defects are merge, priority, or type defects, and those are visible at
evaluation time without building anything.

| Tier                | Runner                                            | Cost       | Observes                                                             |
| ------------------- | ------------------------------------------------- | ---------- | -------------------------------------------------------------------- |
| Pure evaluation     | `lib.evalModules` with `lib.runTests` or nix-unit | Sub-second | Option merging, priorities, type rejection, conditional definitions. |
| Configuration build | `nix flake check`, `nix build --dry-run`          | Seconds    | Assertions, generated files, package instantiation, schema coverage. |
| Virtual machine     | `pkgs.testers.runNixOSTest`                       | Minutes    | Service startup, unit ordering, sockets, on-disk state.              |

A VM test that only asserts a generated config file contains a value is a pure
evaluation test paying a QEMU boot for nothing. Reserve the VM tier for behavior
that needs a running system.

## Pure Evaluation

Evaluate the module under test in isolation with `lib.evalModules` and assert on
`config`. Nothing needs a host, a package set, or a build.

```nix
let
  inherit (pkgs) lib;

  eval =
    modules:
    lib.evalModules {
      modules = [ ../modules/services/demo.nix ] ++ modules;
    };

  enabled = eval [ { demo.enable = true; demo.port = 9000; } ];
  defaulted = eval [ { demo.enable = true; } ];
  disabled = eval [ { } ];
in
lib.runTests {
  testExplicitPort = {
    expr = enabled.config.environment.etc."demo".text;
    expected = "9000";
  };

  testDefaultPort = {
    expr = defaulted.config.environment.etc."demo".text;
    expected = "8080";
  };

  testDisabledDefinesNothing = {
    expr = disabled.config.environment.etc;
    expected = { };
  };

  testRejectsOutOfRangePort = {
    expr = (builtins.tryEval (eval [
      {
        demo.enable = true;
        demo.port = 99999;
      }
    ]).config.environment.etc."demo".text).success;
    expected = false;
  };
}
```

Three things about `lib.runTests` catch people out. It returns the list of
_failures_, so `[ ]` is a pass and a runner must treat a non-empty list as an
error. It only considers attributes whose names begin with `test`, so a typo in
the prefix silently skips the case. And it compares with `==`, so wrap anything
that should fail in `builtins.tryEval` and assert on `.success` rather than
letting the throw escape.

If the module depends on options declared elsewhere, import the declaring module
rather than stubbing the option. A stub with a different type tests the stub.
When the module needs a package set, pass it explicitly:

```nix
lib.evalModules {
  modules = [
    ../modules/services/demo.nix
    { _module.args.pkgs = pkgs; }
  ];
}
```

`nix-unit` runs the same `{ expr; expected; }` attribute shape as a flake check
and reports per-case failures, which is worth wiring up once a project has more
than a handful of cases.

## What To Cover

For a module with any merge or priority logic, evaluate:

- the feature disabled, asserting it defines nothing
- the feature enabled with defaults
- the feature enabled with every option explicitly set
- a definition that must be rejected by the type
- two contributing modules, when the option is a list, attrset, or has a
  `mkDefault` in the module itself

The last one is the case most often skipped and most often broken. A module that
sets a value with `mkDefault` behaves differently once a second module defines
the same option, and only a two-module evaluation shows it. Compare list order
as well as membership; see
[merge priority](module-style.md#options-and-merge-priority).

## Configuration Build Tier

```bash
nix flake check
nix build --dry-run .#nixosConfigurations.host.config.system.build.toplevel
```

This tier catches what pure evaluation cannot: failed assertions, missing
packages for the target platform, and options whose values only fail when
serialized into a generated file. Use `--dry-run` when the question is whether
the configuration resolves, not whether it builds.

For a faster signal on a single host, evaluate the derivation path instead of
building it:

```bash
nix eval --raw .#nixosConfigurations.host.config.system.build.toplevel.drvPath
```

## Virtual Machine Tier

```nix
pkgs.testers.runNixOSTest {
  name = "demo";

  nodes.machine = {
    imports = [ ../modules/services/demo.nix ];
    demo.enable = true;
  };

  testScript = ''
    machine.wait_for_unit("demo.service")
    machine.wait_for_open_port(8080)
  '';
}
```

Assert on observable system state: units reaching `active`, ports accepting
connections, files existing after activation. Asserting on the content of a
store path is an evaluation-tier question wearing a VM costume.

## Assertions Belong In The Module

Constraints that must hold for every user belong in the module as assertions,
not only in tests. A test proves the case you thought of; an assertion rejects
the case a user invents. See
[Assertions and warnings](assertions-and-warnings.md) for when a constraint
should be a type, an assertion, or a warning.

## Reporting

State the tier, the exact runner command, and the observed result. A passing
evaluation test does not establish runtime behavior, and a passing VM test does
not establish that the option merges correctly against another module. Name
whichever of those the check did not cover.
