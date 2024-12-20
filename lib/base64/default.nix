{ lib }:
rec {
  base64Table = builtins.listToAttrs (
    lib.imap0 (i: c: lib.nameValuePair c i) (
      lib.stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    )
  );

  # Generated using python3:
  # print(''.join([ chr(n) for n in range(1, 256) ]), file=open('ascii', 'w'))
  ascii = builtins.readFile ./ascii;

  decode =
    str:
    let
      # List of base-64 numbers
      numbers64 = map (c: base64Table.${c}) (lib.stringToCharacters str);

      # List of base-256 numbers
      numbers256 = lib.concatLists (
        lib.genList (
          i:
          let
            v = lib.foldl' (acc: el: acc * 64 + el) 0 (lib.sublist (i * 4) 4 numbers64);
          in
          [
            (lib.mod (v / 256 / 256) 256)
            (lib.mod (v / 256) 256)
            (lib.mod v 256)
          ]
        ) (lib.length numbers64 / 4)
      );

    in
    # Converts base-256 numbers to ascii
    lib.concatMapStrings (
      n:
      # Can't represent the null byte in Nix..
      lib.substring (n - 1) 1 ascii
    ) numbers256;
}
