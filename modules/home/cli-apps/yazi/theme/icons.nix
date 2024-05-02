_:
let
  catppuccin = import ../../../desktop/theme/catppuccin.nix;
in
{
  icon = {
    rules = [ ];

    append_rules = [
      # Default
      {
        name = "*";
        text = "";
      }
      {
        name = "*/";
        text = "󰉋";
      }
    ];

    prepend_rules = [
      # Orphan symbolic links
      {
        name = "*";
        is = "orphan";
        text = "";
        fg = catppuccin.colors.red.hex;
      }
      {
        name = "*";
        is = "exec";
        text = "";
      }
      {
        name = "*";
        is = "sock";
        text = "󰟩";
      }
      {
        name = "*";
        is = "fifo";
        text = "󰟥";
      }
      {
        name = "*";
        is = "char";
        text = "󰕵";
      }
      {
        name = "*";
        is = "block";
        text = "󱛟";
      }
      {
        name = "*";
        is = "sticky";
        text = "";
      }
      # Home
      {
        name = "*.config/";
        text = "";
      }
      {
        name = "*.ssh/";
        text = "󰢬";
      }
      {
        name = "*Applications/";
        text = "";
      }
      {
        name = "*Desktop/";
        text = "";
      }
      {
        name = "*Development/";
        text = "";
      }
      {
        name = "*Documents/";
        text = "";
      }
      {
        name = "*Downloads/";
        text = "󰉍";
      }
      {
        name = "*Dropbox/";
        text = "󰇣";
      }
      {
        name = "*Google Drive/";
        text = "󰊶";
      }
      {
        name = "*Library/";
        text = "";
      }
      {
        name = "*Movies/";
        text = "";
      }
      {
        name = "*Music/";
        text = "󱍙";
      }
      {
        name = "*Pictures/";
        text = "󰉏";
      }
      {
        name = "*Videos/";
        text = "";
      }
      {
        name = "*Public/";
        text = "";
      }

      # Git
      {
        name = "*.git/";
        text = "";
      }
      {
        name = "*.gitignore";
        text = "";
      }
      {
        name = "*.git-blame-ignore-revs";
        text = "";
      }

      {
        name = "*.gitmodules";
        text = "";
      }
      {
        name = "*.gitattributes";
        text = "";
      }
      {
        name = "*CODEOWNERS";
        text = "";
      }

      # Dotfiles
      {
        name = "*.DS_Store";
        text = "";
      }
      {
        name = "*.bashrc";
        text = "";
      }
      {
        name = "*.bashprofile";
        text = "";
      }
      {
        name = "*.zshrc";
        text = "";
      }
      {
        name = "*.zshenv";
        text = "";
      }
      {
        name = "*.zprofile";
        text = "";
      }
      {
        name = "*.vimrc";
        text = "";
      }

      # Text
      {
        name = "*.txt";
        text = "";
      }
      {
        name = "*.md";
        text = "";
      }
      {
        name = "*.rst";
        text = "";
      }
      {
        name = "*COPYING";
        text = "󰿃";
      }
      {
        name = "*LICENSE";
        text = "󰿃";
      }

      # Archives
      {
        name = "*.zip";
        text = "";
      }
      {
        name = "*.tar";
        text = "";
      }
      {
        name = "*.gz";
        text = "";
      }
      {
        name = "*.7z";
        text = "";
      }
      {
        name = "*.bz2";
        text = "";
      }
      {
        name = "*.xz";
        text = "";
      }

      # Documents
      {
        name = "*.csv";
        text = "";
      }
      {
        name = "*.doc";
        text = "";
      }
      {
        name = "*.doct";
        text = "";
      }
      {
        name = "*.docx";
        text = "";
      }
      {
        name = "*.dot";
        text = "";
      }
      {
        name = "*.ods";
        text = "";
      }
      {
        name = "*.ots";
        text = "";
      }
      {
        name = "*.pdf";
        text = "";
      }
      {
        name = "*.pom";
        text = "";
      }
      {
        name = "*.pot";
        text = "";
      }
      {
        name = "*.ppm";
        text = "";
      }
      {
        name = "*.pps";
        text = "";
      }
      {
        name = "*.ppt";
        text = "";
      }
      {
        name = "*.potx";
        text = "";
      }
      {
        name = "*.ppmx";
        text = "";
      }
      {
        name = "*.ppsx";
        text = "";
      }
      {
        name = "*.pptx";
        text = "";
      }
      {
        name = "*.xlc";
        text = "";
      }
      {
        name = "*.xlm";
        text = "";
      }
      {
        name = "*.xls";
        text = "";
      }
      {
        name = "*.xlt";
        text = "";
      }
      {
        name = "*.xlsm";
        text = "";
      }
      {
        name = "*.xlsx";
        text = "";
      }

      # Audio
      {
        name = "*.mp3";
        text = "";
      }
      {
        name = "*.flac";
        text = "";
      }
      {
        name = "*.wav";
        text = "";
      }
      {
        name = "*.aac";
        text = "";
      }
      {
        name = "*.ogg";
        text = "";
      }
      {
        name = "*.m4a";
        text = "";
      }
      {
        name = "*.mp2";
        text = "";
      }

      # Video
      {
        name = "*.mp4";
        text = "";
      }
      {
        name = "*.mkv";
        text = "";
      }
      {
        name = "*.avi";
        text = "";
      }
      {
        name = "*.mov";
        text = "";
      }
      {
        name = "*.webm";
        text = "";
      }

      # Images
      {
        name = "*.jpg";
        text = "";
      }
      {
        name = "*.jpeg";
        text = "";
      }
      {
        name = "*.png";
        text = "";
      }
      {
        name = "*.gif";
        text = "";
      }
      {
        name = "*.webp";
        text = "";
      }
      {
        name = "*.avif";
        text = "";
      }
      {
        name = "*.bmp";
        text = "";
      }
      {
        name = "*.ico";
        text = "";
      }
      {
        name = "*.svg";
        text = "";
      }
      {
        name = "*.xcf";
        text = "";
      }
      {
        name = "*.HEIC";
        text = "";
      }

      # Programming
      {
        name = "*.c";
        text = "";
      }
      {
        name = "*.cpp";
        text = "";
      }
      {
        name = "*.h";
        text = "";
      }
      {
        name = "*.m";
        text = "";
      }
      {
        name = "*.hpp";
        text = "";
      }
      {
        name = "*.rs";
        text = "";
      }
      {
        name = "*.go";
        text = "";
      }
      {
        name = "*.py";
        text = "";
      }
      {
        name = "*.hs";
        text = "";
      }
      {
        name = "*.js";
        text = "";
      }
      {
        name = "*.ts";
        text = "";
      }
      {
        name = "*.tsx";
        text = "";
      }
      {
        name = "*.jsx";
        text = "";
      }
      {
        name = "*.rb";
        text = "";
      }
      {
        name = "*.php";
        text = "";
      }
      {
        name = "*.java";
        text = "";
      }
      {
        name = "*.sh";
        text = "";
      }
      {
        name = "*.fish";
        text = "";
      }
      {
        name = "*.swift";
        text = "";
      }
      {
        name = "*.vim";
        text = "";
      }
      {
        name = "*.lua";
        text = "";
      }
      {
        name = "*.html";
        text = "";
      }
      {
        name = "*.css";
        text = "";
      }
      {
        name = "*.sass";
        text = "";
      }
      {
        name = "*.scss";
        text = "";
      }
      {
        name = "*.json";
        text = "";
      }
      {
        name = "*.toml";
        text = "";
      }
      {
        name = "*.yml";
        text = "";
      }
      {
        name = "*.yaml";
        text = "";
      }
      {
        name = "*.ini";
        text = "";
      }
      {
        name = "*.conf";
        text = "";
      }
      {
        name = "*.dconf";
        text = "";
      }
      {
        name = "*.lock";
        text = "";
      }
      {
        name = "*.nix";
        text = "";
      }
      {
        name = "*Containerfile";
        text = "󰡨";
      }
      {
        name = "*Dockerfile";
        text = "󰡨";
      }
      {
        name = "*.dockerignore";
        text = "󰡨";
      }
      {
        name = "*Jenkinsfile";
        text = "";
      }
      {
        name = "*CHANGELOG";
        text = "";
      }
      {
        name = "*makefile";
        text = "";
      }

      # Keys
      {
        name = "*.gpg";
        text = "󱆄";
      }
      {
        name = "*.pub";
        text = "󱆄";
      }
      {
        name = "*.KEY";
        text = "󱆄";
      }
      {
        name = "*.pfx";
        text = "󱆄";
      }
      {
        name = "*.p12";
        text = "󱆄";
      }
      {
        name = "*.pem";
        text = "󱆄";
      }

      # Certs
      {
        name = "*.cer";
        text = "󱆆";
      }
      {
        name = "*.der";
        text = "󱆆";
      }

      # Misc
      {
        name = "*.bin";
        text = "";
      }
      {
        name = "*.exe";
        text = "";
      }
      {
        name = "*.pkg";
        text = "";
      }
      {
        name = "*.otf";
        text = "";
      }
      {
        name = "*.ttf";
        text = "";
      }
    ];
  };
}
