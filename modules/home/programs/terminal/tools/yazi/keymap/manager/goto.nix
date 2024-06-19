{ config, namespace, ... }:
{
  keymap = [
    # Goto
    {
      on = [
        "g"
        "/"
      ];
      run = "cd /";
      desc = "Go to the root directory";
    }
    {
      on = [
        "g"
        "h"
      ];
      run = "cd ~";
      desc = "Go to the home directory";
    }
    {
      on = [
        "g"
        "c"
      ];
      run = "cd ~/.config";
      desc = "Go to the config directory";
    }
    {
      on = [
        "g"
        "t"
      ];
      run = "cd /tmp";
      desc = "Go to the temporary directory";
    }
    {
      on = [
        "g"
        "<Space>"
      ];
      run = "cd --interactive";
      desc = "Go to a directory interactively";
    }
    {
      on = [
        "g"
        "D"
      ];
      run = "cd ~/Downloads";
      desc = "Go to the downloads directory";
    }
    {
      on = [
        "g"
        "G"
      ];
      run = "cd ~/Documents/gitlab";
      desc = "Go to the GitLab directory";
    }
    {
      on = [
        "g"
        "M"
      ];
      run = "cd /mnt";
      desc = "Go to the /mnt directory";
    }
    {
      on = [
        "g"
        "c"
      ];
      run = "cd ~/.config";
      desc = "Go to the ~/.config directory";
    }
    {
      on = [
        "g"
        "d"
      ];
      run = "cd ~/Documents";
      desc = "Go to the Documents directory";
    }
    {
      on = [
        "g"
        "e"
      ];
      run = "cd /etc";
      desc = "Go to the /etc directory";
    }
    {
      on = [
        "g"
        "g"
      ];
      run = "cd ~/Documents/github";
      desc = "Go to the GitHub directory";
    }
    {
      on = [
        "g"
        "h"
      ];
      run = "cd ~";
      desc = "Go to the home directory";
    }
    {
      on = [
        "g"
        "i"
      ];
      run = "cd /run/media/${config.${namespace}.user.name}";
      desc = "Run command to change to media directory";
    }
    {
      on = [
        "g"
        "l"
      ];
      run = "cd ~/.local/";
      desc = "Go to the ~/.local/ directory";
    }
    {
      on = [
        "g"
        "m"
      ];
      run = "cd /media";
      desc = "Go to the /media directory";
    }
    {
      on = [
        "g"
        "o"
      ];
      run = "cd /opt";
      desc = "Go to the /opt directory";
    }
    {
      on = [
        "g"
        "t"
      ];
      run = "cd /tmp";
      desc = "Go to the /tmp directory";
    }
    {
      on = [
        "g"
        "p"
      ];
      run = "cd ~/Pictures";
      desc = "Go to the Pictures directory";
    }
    {
      on = [
        "g"
        "r"
      ];
      run = "cd /run";
      desc = "Go to the /run directory";
    }
    {
      on = [
        "g"
        "s"
      ];
      run = "cd /srv";
      desc = "Go to the /srv directory";
    }
    {
      on = [
        "g"
        "u"
      ];
      run = "cd /usr";
      desc = "Go to the /usr directory";
    }
    {
      on = [
        "g"
        "v"
      ];
      run = "cd /var";
      desc = "Go to the /var directory";
    }
    {
      on = [
        "g"
        "w"
      ];
      run = "cd ~/.local/share/wallpapers";
      desc = "Go to the wallpapers directory";
    }
  ];
}
