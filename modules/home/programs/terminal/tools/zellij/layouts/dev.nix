{
  config = {
    programs = {
      zellij = {
        layouts = {
          dev = {
            layout = {
              _children = [
                {
                  default_tab_template = {
                    _children = [
                      {
                        pane = {
                          size = 1;
                          borderless = true;
                          plugin = {
                            location = "zellij:tab-bar";
                          };
                        };
                      }
                      { "children" = { }; }
                      {
                        pane = {
                          size = 2;
                          borderless = true;
                          plugin = {
                            location = "zellij:status-bar";
                          };
                        };
                      }
                    ];
                  };
                }
                {
                  tab = {
                    _props = {
                      name = "Project";
                      focus = true;
                    };
                    _children = [
                      {
                        pane = {
                          command = "nvim";
                        };
                      }
                    ];
                  };
                }
                {
                  tab = {
                    _props = {
                      name = "Git";
                    };
                    _children = [
                      {
                        pane = {
                          command = "lazygit";
                        };
                      }
                    ];
                  };
                }
                {
                  tab = {
                    _props = {
                      name = "Jujutsu";
                    };
                    _children = [
                      {
                        pane = {
                          command = "jjui";
                        };
                      }
                    ];
                  };
                }
                {
                  tab = {
                    _props = {
                      name = "Files";
                    };
                    _children = [
                      {
                        pane = {
                          # Get at least some image previews in zellij
                          command = "sh";
                          args = [
                            "-c"
                            "TERM=xterm-kitty yazi"
                          ];
                        };
                      }
                    ];
                  };
                }
                {
                  tab = {
                    _props = {
                      name = "Shell";
                    };
                    _children = [
                      {
                        pane = {
                          command = "zsh";
                        };
                      }
                    ];
                  };
                }
              ];
            };
          };
        };
      };
    };
  };
}
