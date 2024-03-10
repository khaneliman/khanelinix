function Manager:render(area)
  local chunks = self:layout(area)

  local bar = function(c, x, y)
    x, y = math.max(0, x), math.max(0, y)
    return ui.Bar(ui.Rect { x = x, y = y, w = ya.clamp(0, area.w - x, 1), h = math.min(1, area.h) }, ui.Bar.TOP)
        :symbol(c)
  end

  return ya.flat {
    -- Borders
    ui.Border(area, ui.Border.ALL):type(ui.Border.ROUNDED):style(THEME.manager.border_style),
    ui.Bar(chunks[1], ui.Bar.RIGHT):style(THEME.manager.border_style),
    ui.Bar(chunks[3], ui.Bar.LEFT):style(THEME.manager.border_style),

    bar("┬", chunks[1].right - 1, chunks[1].y):style(THEME.manager.border_style),
    bar("┴", chunks[1].right - 1, chunks[1].bottom - 1):style(THEME.manager.border_style),
    bar("┬", chunks[2].right, chunks[2].y):style(THEME.manager.border_style),
    bar("┴", chunks[2].right, chunks[1].bottom - 1):style(THEME.manager.border_style),

    -- Parent
    Parent:render(chunks[1]:padding(ui.Padding.xy(1))),
    -- Current
    Current:render(chunks[2]:padding(ui.Padding.y(1))),
    -- Preview
    Preview:render(chunks[3]:padding(ui.Padding.xy(1))),
  }
end
