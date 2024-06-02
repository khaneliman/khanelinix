_: {
  programs.nixvim = {
    extraConfigLuaPre = # Lua
      ''
        local function in_comment(pattern)
          return function(buf_id)
            local cs = vim.bo[buf_id].commentstring
            if cs == nil or cs == "" then cs = '# %s' end

            -- Extract left and right part relative to '%s'
            local left, right = cs:match('^(.*)%%s(.-)$')
            left, right = vim.trim(left), vim.trim(right)
            -- General ideas:
            -- - Line is commented if it has structure
            -- "whitespace - comment left - anything - comment right - whitespace"
            -- - Highlight pattern only if it is to the right of left comment part
            --   (possibly after some whitespace)
            -- Example output for '/* %s */' commentstring: '^%s*/%*%s*()TODO().*%*/%s*'
            return string.format('^%%s*%s%%s*()%s().*%s%%s*$', vim.pesc(left), pattern, vim.pesc(right))
          end
        end
      '';

    plugins = {
      mini = {
        enable = true;

        modules = {
          hipatterns = {
            highlighters = {
              # TODO: enable again if i find a good TODO Telescope replacement from todo-comments
              # fixme = {
              #   pattern.__raw = # Lua
              #     ''in_comment("FIXME")'';
              #   group = "MiniHipatternsFixme";
              # };
              # fix = {
              #   pattern.__raw = # Lua
              #     ''in_comment("FIX")'';
              #   group = "MiniHipatternsFixme";
              # };
              # hack = {
              #   pattern.__raw = # Lua
              #     ''in_comment("HACK")'';
              #   group = "MiniHipatternsHack";
              # };
              # todo = {
              #   pattern.__raw = # Lua
              #     ''in_comment("TODO")'';
              #   group = "MiniHipatternsTodo";
              # };
              # note = {
              #   pattern.__raw = # Lua
              #     ''in_comment("NOTE")'';
              #   group = "MiniHipatternsNote";
              # };
              extmark_opts = {
                priority = 2000;
              };
              hex_color.__raw = # Lua
                ''require("mini.hipatterns").gen_highlighter.hex_color()'';
            };
          };
        };
      };
    };
  };
}
