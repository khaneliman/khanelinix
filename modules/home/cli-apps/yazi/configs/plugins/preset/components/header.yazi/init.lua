function Header:host()
  if ya.target_family() ~= "unix" then
    return ui.Line {}
  end
  return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("green")
end

function Header:render(area)
  ya.dbg(ya.target_family())
  ya.dbg(ya.user_name())
  ya.dbg(ya.host_name())

  self.area = area

  -- TODO: readd count after nixpkgs version bump
  -- local right = ui.Line { self:count(), self:tabs() }
  local right = ui.Line { self:tabs() }
  local left = ui.Line { self:host(), self:cwd(math.max(0, area.w - right:width())) }

  return {
    ui.Paragraph(area, { left }),
    ui.Paragraph(area, { right }):align(ui.Paragraph.RIGHT),
  }
end
