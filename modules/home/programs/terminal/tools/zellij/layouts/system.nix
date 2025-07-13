{
  config = {
    programs = {
      zellij = {
        layouts = {
          system = {
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
                  tab_template = {
                    _props = {
                      name = "dev_tab";
                    };
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
                      {
                        pane = {
                          split_direction = "Vertical";
                          _children = [
                            {
                              pane = {
                                size = "15%";
                                _props = {
                                  name = "Filetree";
                                };
                                plugin = {
                                  location = "zellij:strider";
                                };
                              };
                            }
                          ];
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
                  pane_template = {
                    _props = {
                      name = "term";
                    };
                    _children = [
                      {
                        pane = {
                          split_direction = "horizontal";
                          _children = [
                            { "children" = { }; }
                            {
                              pane = {
                                command = "zsh";
                                size = "25%";
                                _props = {
                                  name = "Shell";
                                };
                              };
                            }
                          ];
                        };
                      }
                    ];
                  };
                }
                {
                  tab = {
                    _props = {
                      name = "khanelinix";
                      focus = true;
                      cwd = "$HOME/khanelinix/";
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
                      split_direction = "horizontal";
                      cwd = "$HOME/khanelinix/";
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
                      name = "Files";
                      split_direction = "horizontal";
                      cwd = "$HOME";
                    };
                    _children = [
                      {
                        pane = {
                          command = "yazi";
                        };
                      }
                    ];
                  };
                }
                {
                  tab = {
                    _props = {
                      name = "Shell";
                      split_direction = "horizontal";
                      cwd = "$HOME/khanelinix/";
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
                {
                  tab = {
                    _props = {
                      name = "Processes";
                      split_direction = "vertical";
                      cwd = "$HOME";
                    };
                    _children = [
                      {
                        pane = {
                          command = "btop";
                        };
                      }
                    ];
                  };
                }
                {
                  tab = {
                    _props = {
                      name = "Media";
                      split_direction = "vertical";
                      cwd = "$HOME/Music";
                    };
                    _children = [
                      {
                        pane = {
                          split_direction = "horizontal";
                          _props = {
                            name = "Player";
                          };
                          _children = [
                            {
                              pane = {
                                command = "musikcube";
                              };
                            }
                          ];
                        };
                      }
                      {
                        pane = {
                          split_direction = "horizontal";
                          _props = {
                            name = "Mixer";
                          };
                          _children = [
                            {
                              pane = {
                                size = "35%";
                                command = "pulsemixer";
                              };
                            }
                          ];
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
