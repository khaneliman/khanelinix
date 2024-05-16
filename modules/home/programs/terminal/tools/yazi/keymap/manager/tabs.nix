_: {
  keymap = [
    # Tabs
    {
      on = [ "t" ];
      run = "tab_create --current";
      desc = "Create a new tab using the current path";
    }
    {
      on = [ "<C-n>" ];
      run = "tab_create --current";
      desc = "Create a new tab using the current path";
    }
    {
      on = [ "1" ];
      run = "tab_switch 0";
      desc = "Switch to the first tab";
    }
    {
      on = [ "2" ];
      run = "tab_switch 1";
      desc = "Switch to the second tab";
    }
    {
      on = [ "3" ];
      run = "tab_switch 2";
      desc = "Switch to the third tab";
    }
    {
      on = [ "4" ];
      run = "tab_switch 3";
      desc = "Switch to the fourth tab";
    }
    {
      on = [ "5" ];
      run = "tab_switch 4";
      desc = "Switch to the fifth tab";
    }
    {
      on = [ "6" ];
      run = "tab_switch 5";
      desc = "Switch to the sixth tab";
    }
    {
      on = [ "7" ];
      run = "tab_switch 6";
      desc = "Switch to the seventh tab";
    }
    {
      on = [ "8" ];
      run = "tab_switch 7";
      desc = "Switch to the eighth tab";
    }
    {
      on = [ "9" ];
      run = "tab_switch 8";
      desc = "Switch to the ninth tab";
    }
    {
      on = [ "[" ];
      run = "tab_switch -1 --relative";
      desc = "Switch to the previous tab";
    }
    {
      on = [ "]" ];
      run = "tab_switch 1 --relative";
      desc = "Switch to the next tab";
    }
    {
      on = [ "<S-Tab>" ];
      run = "tab_switch -1 --relative";
      desc = "Switch to the previous tab";
    }
    {
      on = [ "<Tab>" ];
      run = "tab_switch 1 --relative";
      desc = "Switch to the next tab";
    }
    {
      on = [ "{" ];
      run = "tab_swap -1";
      desc = "Swap the current tab with the previous tab";
    }
    {
      on = [ "}" ];
      run = "tab_swap 1";
      desc = "Swap the current tab with the next tab";
    }
  ];
}
