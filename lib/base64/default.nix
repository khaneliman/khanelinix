{ inputs }:
let
  inherit (inputs.nixpkgs.lib)
    imap0
    nameValuePair
    stringToCharacters
    concatLists
    genList
    foldl'
    sublist
    length
    concatMapStrings
    substring
    mod
    ;
in
rec {
  base64Table = builtins.listToAttrs (
    imap0 (i: c: nameValuePair c i) (
      stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    )
  );

  # Generated using python3:
  # print(''.join([ chr(n) for n in range(1, 256) ]), file=open('ascii', 'w'))
  ascii = builtins.readFile ./ascii;

  decode =
    str:
    let
      # List of base-64 numbers
      numbers64 = map (c: base64Table.${c}) (stringToCharacters str);

      # List of base-256 numbers
      numbers256 = concatLists (
        genList (
          i:
          let
            v = foldl' (acc: el: acc * 64 + el) 0 (sublist (i * 4) 4 numbers64);
          in
          [
            (mod (v / 256 / 256) 256)
            (mod (v / 256) 256)
            (mod v 256)
          ]
        ) (length numbers64 / 4)
      );

    in
    # Converts base-256 numbers to ascii
    concatMapStrings (
      n:
      # Can't represent the null byte in Nix..
      substring (n - 1) 1 ascii
    ) numbers256;
}
