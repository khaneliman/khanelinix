{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.lsd;
in
{
  options.khanelinix.tools.lsd = with types; {
    enable = mkBoolOpt false "Whether or not to enable lsd.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lsd
    ];

    khanelinix.home.extraOptions.home.shellAliases = {
      ls = "lsd -al --color=always --group-directories-first"; # preferred listing                   
      la = "lsd -a --color=always --group-directories-first"; # all files and dirs                  
      ll = "lsd -l --color=always --group-directories-first"; # long format                         
      lt = "lsd -a --tree --color=always --group-directories-first -I .git"; # tree listing          
      lst = "lsd -al --tree --color=always --group-directories-first -I .git"; # tree listing        
      llt = "lsd -l --tree --color=always --group-directories-first -I .git"; # tree listing         
      l = "lsd -a | egrep '^\.'"; # show only dotfilesalias ls='lsd -a' 
    };
  };
}
