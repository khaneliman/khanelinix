{
  lib,
  mkShell,
  pkgs,
  ...
}:
let
  llvm = pkgs.llvmPackages_latest;

  # simple script which replaces the functionality of make
  # it works with <math.h> and includes debugging symbols by default
  # it will be updated as per needs

  # arguments: outfile
  # basic usage example: mk main [flags]
  mymake =
    pkgs.writeShellScriptBin "mk" # bash
      ''
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
mkShell {
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

  shellHook = ''
    echo "🔨 C/C++ DevShell"
    echo ""
    echo "📦 Available tools:"
    echo "  Build tools: gnumake, cmake, bear, meson, ninja"
    echo "  Debuggers: lldb${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ", gdb, valgrind"}"
    echo "  Compilers: clang, clang++"
    echo "  Analysis: cppcheck, cpplint"
    echo "  Libraries: SDL2, SDL2_gfx, glm"
    echo "  Custom: mk (simplified make script)"
    echo ""
    echo "🛠️  Ready for C/C++ development!"
  '';
}
