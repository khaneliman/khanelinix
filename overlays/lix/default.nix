_: _final: prev: {
  lixPackageSets = prev.lixPackageSets.extend (
    _finalSets: prevSets: {
      lix_2_95 = prevSets.lix_2_95.overrideScope (
        _finalScope: prevScope: {
          lix = prevScope.lix.overrideAttrs (old: {
            # Only Lix >= 2.96 accepts this flag. Drop once nixpkgs guards it.
            mesonFlags = builtins.filter (flag: !prev.lib.hasPrefix "-Dmimalloc=" flag) old.mesonFlags;
          });
        }
      );
    }
  );
}
