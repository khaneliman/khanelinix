_: _self: super: {
  # TODO: remove after https://github.com/NixOS/nixpkgs/pull/384904 is available
  biome = super.biome.overrideAttrs (oa: {
    cargoTestFlags = oa.cargoTestFlags ++ [
      "-- --skip=commands::check::print_json"
      "--skip=commands::check::print_json_pretty"
      "--skip=commands::explain::explain_logs"
      "--skip=commands::format::print_json"
      "--skip=commands::format::print_json_pretty"
      "--skip=commands::format::should_format_files_in_folders_ignored_by_linter"
    ];
  });
}
