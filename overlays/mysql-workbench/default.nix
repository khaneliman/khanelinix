_: _final: prev: {
  mysql-workbench = prev.mysql-workbench.overrideAttrs (old: {
    patches = old.patches ++ [ ./fix-xml2.patch ];

    # GCC 13: error: 'int64_t' in namespace 'std' does not name a type
    # when updating the version make sure this is still needed
    env.CXXFLAGS = "-include cstdint";
  });
}
