_: _final: prev: {
  # TODO: remove override after https://github.com/NixOS/nixpkgs/pull/331127 is in unstable
  mysql-workbench = prev.mysql-workbench.override {
    libxml2 = prev.libxml2.override { enableHttp = true; };
  };
}
