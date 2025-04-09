let
  mkSortKeymap =
    {
      key,
      method,
      desc ? null,
      reverse ? false,
    }:
    let
      defaultDesc = "Sort by ${method}" + (if reverse then " (reverse)" else "");

      description = if desc != null then desc else defaultDesc;

      reverseFlag = if reverse then "--reverse" else "--reverse=no";
      runCmd = "sort ${method} ${reverseFlag}";
    in
    {
      on = [
        ","
        key
      ];
      run = runCmd;
      desc = description;
    };

  sortMethods = [
    {
      key = "a";
      method = "alphabetical";
    }
    {
      key = "A";
      method = "alphabetical";
      reverse = true;
    }
    {
      key = "c";
      method = "btime";
      desc = "Sort by creation time";
    }
    {
      key = "C";
      method = "btime";
      reverse = true;
      desc = "Sort by creation time (reverse)";
    }
    {
      key = "m";
      method = "mtime";
      desc = "Sort by modified time";
    }
    {
      key = "M";
      method = "mtime";
      reverse = true;
      desc = "Sort by modified time (reverse)";
    }
    {
      key = "n";
      method = "natural";
    }
    {
      key = "N";
      method = "natural";
      reverse = true;
    }
    {
      key = "s";
      method = "size";
    }
    {
      key = "S";
      method = "size";
      reverse = true;
    }
  ];
in
{
  keymap = map mkSortKeymap sortMethods;
}
