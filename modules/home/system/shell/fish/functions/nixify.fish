function nixify
    if not test -e ./.envrc
        echo "use nix" > .envrc
        direnv allow
    end
    if not test -e shell.nix -a ! -e default.nix
        set code 'with import <nixpkgs> {}; 
          mkShell {
            nativeBuildInputs = [
              bashInteractive
            ];
          }'
        echo $code | sed "s/'/'\\\\''/g" | xargs echo > default.nix
        eval (env $EDITOR "default.nix")
    end
end

