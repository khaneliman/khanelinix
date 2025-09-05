{ pkgs, lib, ... }:
let
  llvm = pkgs.llvmPackages_latest;
  mymake = pkgs.writeShellScriptBin "mk" ''
    if [ -f "$1.c" ]; then
      i="$1.c"
      c=$CC
    else
      i="$1.cpp"
      c=$CXX
    fi
    o=$1
    shift
    $c -ggdb $i -o $o -lm -Wall $@
  '';
in
{
  c = {
    name = "c";

    languages.c = {
      enable = true;
    };

    packages =
      with pkgs;
      [
        # builder
        gnumake
        cmake
        bear
        meson
        ninja

        # debugger
        llvm.lldb

        # fix headers not found
        clang-tools

        # LSP and compiler
        llvm.libstdcxxClang

        # other tools
        cppcheck
        cpplint
        llvm.libllvm
        mymake

        # stdlib for cpp
        llvm.libcxx

        # libs
        glm
        SDL2
        SDL2_gfx
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        gdb
        valgrind
      ];

    enterShell = ''
      echo "🔨 C/C++ DevShell"
      echo "GCC $(gcc --version | head -n1)"
    '';
  };
}
