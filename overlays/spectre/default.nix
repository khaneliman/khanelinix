_: _final: prev: {
  # TODO: remove once https://github.com/NixOS/nixpkgs/pull/324952 hits unstable
  vimPlugins = prev.vimPlugins // {
    nvim-spectre =
      let
        version = "2024-06-25";

        src = prev.fetchFromGitHub {
          owner = "nvim-pack";
          repo = "nvim-spectre";
          rev = "49fae98ef2bfa8342522b337892992e3495065d5";
          sha256 = "027jfxxmccfjyn2g9pzsyrx9ls9lg8fg28rac8bqrwa95v5z5dgn";
        };

        spectre_oxi = prev.rustPlatform.buildRustPackage {
          pname = "spectre_oxi";
          inherit version src;
          sourceRoot = "${src.name}/spectre_oxi";

          cargoHash = "sha256-SqbU9YwZ5pvdFUr7XBAkkfoqiLHI0JwJRwH7Wj1JDNg=";

          preCheck = ''
            mkdir tests/tmp/
          '';
        };
      in
      prev.vimUtils.buildVimPlugin {
        inherit version src;
        pname = "nvim-spectre";
        meta.homepage = "https://github.com/nvim-pack/nvim-spectre/";

        postInstall = ''
          ln -s ${spectre_oxi}/lib/libspectre_oxi.* $out/lua/spectre_oxi.so
        '';
      };
  };
}
