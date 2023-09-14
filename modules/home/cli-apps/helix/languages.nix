{ pkgs
, lib
, ...
}:
let
  inherit (lib) getExe getExe';
in
{
  programs.helix.languages = {
    language = [
      {
        name = "bash";
        auto-format = true;
        formatter = {
          command = "${getExe pkgs.shfmt}";
          args = [ "-i" "2" "-" ];
        };
      }
      {
        name = "clojure";
        injection-regex = "(clojure|clj|edn|boot|yuck)";
        file-types = [ "clj" "cljs" "cljc" "clje" "cljr" "cljx" "edn" "boot" "yuck" ];
      }
    ];

    language-server = {
      bash-language-server = {
        command = "${getExe pkgs.nodePackages.bash-language-server}";
        args = [ "start" ];
      };

      clangd = {
        command = "${getExe' pkgs.clang-tools "clangd"}";
        clangd.fallbackFlags = [ "-std=c++2b" ];
      };

      nil = {
        command = getExe pkgs.nil;
        config.nil.formatting.command = [ "${getExe pkgs.nixpkgs-fmt}" "-q" ];
      };

      vscode-css-language-server = {
        command = "${getExe pkgs.nodePackages.vscode-css-languageserver-bin}";
        args = [ "--stdio" ];
      };
    };
  };
}
