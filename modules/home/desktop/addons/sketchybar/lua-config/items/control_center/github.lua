local icons = require("icons")
local settings = require("settings")
local colors = require("colors")

local popup_toggle = "sketchybar --set github popup.drawing=toggle"
local popup_off = "sketchybar --set github popup.drawing=off"

local function isempty(s)
  return s == nil or s == ''
end

local github = sbar.add("item", "github", {
  position = "right",
  icon = {
    string = icons.bell,
    color = colors.blue,
    font = {
      family = settings.font,
      style = "Bold",
      size = 15.0,
    }
  },
  background = {
    padding_left = 0,
  },
  label = {
    string = icons.loading,
    highlight_color = colors.blue,
  },
  update_freq = 180,
  popup = {
    align = "right",
  },
})

local github_details = sbar.add("item", "github_details", {
  position = "popup." .. github.name,
  click_script = popup_off,
  background = {
    corner_radius = 12,
    padding_left = 7,
    padding_right = 7
  },
  icon = {
    background = {
      height = 2,
      y_offset = -12,
    }
  }
})

github:subscribe({
    "mouse.clicked"
  },
  function(info)
    if (info.BUTTON == "left") then
      sbar.exec(popup_toggle)
    end

    if (info.BUTTON == "right") then
      sbar.trigger("github_update")
    end
  end)

github:subscribe({
    "mouse.exited",
    "mouse.exited.global"
  },
  function(_)
    github:set({ popup = { drawing = false } })
  end)

github:subscribe({
    "mouse.entered",
  },
  function(_)
    github:set({ popup = { drawing = true } })
  end)

github:subscribe({
    "routine",
    "forced",
    "github_update"
  },
  function(_)
    -- fetch new information
    sbar.exec(
      'gh api notifications | jq -r \'.[] | [.id, .repository.name, .subject.latest_comment_url, .subject.type, .subject.title] | @sh\'',
      function(notifications)
        local count = 0
        for _ in notifications:gmatch("\n") do
          count = count + 1
        end

        -- Clear existing packages
        local existingNotifications = github:query()
        if existingNotifications.popup and next(existingNotifications.popup.items) ~= nil then
          for _, item in pairs(existingNotifications.popup.items) do
            sbar.remove(item)
          end
        end

        -- Add packages to popup
        for notification in notifications:gmatch("[^\n]+") do
          local id, repo, url, type, title = notification:match(
            "'%s*(.-)%s*' '%s*(.-)%s*' '%s*(.-)%s*' '%s*(.-)%s*' '%s*(.-)%s*'")
          local color, icon

          if url == nil then
            url = ""
          else
            local tempUrl = url:gsub("^'", ""):gsub("'$", "")
            -- url = io.popen('gh api "' .. tempUrl .. '" | jq .html_url'):read("*a")
            sbar.exec('gh api "' .. tempUrl .. '" | jq .html_url', function(html_url)
              if isempty(repo) == false then
                sbar.exec('sketchybar -m --set github_notification_repo' ..
                  tostring(id) .. ' click_script="open ' .. html_url .. '"', function()
                    sbar.exec(popup_off)
                  end)
              end

              if isempty(title) == false then
                sbar.exec('sketchybar -m --set github_notification_message.' ..
                  tostring(id) .. ' click_script="open ' .. html_url .. '"', function()
                    sbar.exec(popup_off)
                  end)
              end
            end)
          end

          if type == "Issue" then
            color = colors.green
            icon = icons.git.issue
          elseif type == "Discussion" then
            color = colors.text
            icon = icons.git.discussion
            url = "https://www.github.com/notifications"
          elseif type == "PullRequest" then
            color = colors.maroon
            icon = icons.git.pull_request
          elseif type == "Commit" then
            color = colors.text
            icon = icons.git.commit
          else
            color = colors.text
            icon = icons.git.issue
          end


          if isempty(repo) == false then
            local github_notification_repo = sbar.add("item", "github_notification_repo" .. tostring(id), {
              label = {
                padding_right = settings.paddings,
              },
              icon = {
                string = icon .. " " .. repo,
                color = color,
                font = {
                  family = settings.nerd_font,
                  size = 14.0,
                  style = "Bold"
                },
                padding_left = settings.paddings
              },
              drawing = true,
              click_script = "open " .. url .. "; " .. popup_off,
              position = "popup." .. github.name,
            })
          end

          if isempty(title) == false then
            local github_notification_message = sbar.add("item", "github_notification_message." .. tostring(id), {
              label = {
                string = title,
                padding_right = 10,
              },
              icon = {
                drawing = off,
                padding_left = settings.paddings
              },
              drawing = true,
              click_script = "open " .. url .. "; " .. popup_off,
              position = "popup." .. github.name,
            })
          end
        end

        -- Change icon and color depending on packages
        github:set({
          icon = {
            string = icons.bell_dot
          },
          label = 0
        })

        if count > 0 then
          github:set({
            icon = {
              string = icons.bell
            },
            label = count
          })
        end
      end)
  end)

return github
