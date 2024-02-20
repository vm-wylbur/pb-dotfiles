-- Pull in the wezterm API
local wezterm = require 'wezterm'
local mux = wezterm.mux
local config = wezterm.config_builder()
local smart_splits = wezterm.plugin.require('https://github.com/mrjones2014/smart-splits.nvim')

config.font_dirs = {'/Users/pball/Library/Fonts/'}
config.font = wezterm.font("JetBrains Mono")
config.color_scheme = 'Tango (terminal.sexy)'
config.font_size = 18
config.use_fancy_tab_bar = true

config.leader = { key="b", mods="CTRL" }
config.keys = {
  {
    mods = "LEADER",
    key = "-", -- Split horizontal
    action = wezterm.action{SplitVertical={domain="CurrentPaneDomain"}},
  },
  {
    mods = "LEADER",
    key = "\\", -- Split horizontal
    action = wezterm.action{SplitHorizontal={domain="CurrentPaneDomain"}},
  },
}
smart_splits.apply_to_config(config)


wezterm.on('format-tab-title', function(tab)
  local pane = tab.active_pane
  local title = pane.title
  if pane.domain_name then
    title = pane.domain_name
  end
  return title
end)

-- https://stackoverflow.com/questions/11201262
-- local open = io.open
-- local function read_file(path)
--     local file = open(path, "rb") -- r read mode and b binary mode
--     if not file then return nil end
--     local content = file:read "*a" -- *a or *all reads the whole file
--     file:close()
--     return content
-- end

function rstrip(s)
  if not s then return nil end
  return s:match'^(.*%S)%s*$'
end


wezterm.on('update-right-status', function(window, pane)
  -- Each element holds the text for a cell in a "powerline" style << fade
  local cells = {}
  local meta = pane:get_metadata() or {}

  local remote_resp = meta.since_last_response_ms
  if remote_resp then
    remote_resp = string.format("%1.0f", remote_resp / 1000.0)
  else
    remote_resp = "local"
  end

  local date = wezterm.strftime '%a %b %-d %H:%M '

  local pkd = rstrip(pane:get_user_vars().pkd) or "no pkd"
  local jvals = wezterm.json_parse(pkd)
  wezterm.log_info(date, jvals)

  table.insert(cells, wezterm.hostname())
  -- table.insert(cells, pkd)
  table.insert(cells, jvals.cputemp)
  table.insert(cells, jvals.cpuusage)
  table.insert(cells, jvals.memfree)
  table.insert(cells, remote_resp)

  -- The powerline < symbol
  local LEFT_ARROW = utf8.char(0xe0b3)
  -- The filled in variant of the < symbol
  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

  -- Color palette for the backgrounds of each cell
  local colors = {
    '#3c1361',
    '#52307c',
    '#663a82',
    '#7c5295',
    '#b491c8',
  }

  -- Foreground color for the text across the fade
  local text_fg = '#c0c0c0'

  -- The elements to be formatted
  local elements = {}
  -- How many cells have been formatted
  local num_cells = 0

  -- Translate a cell into elements
  function push(text, is_last)
    local cell_no = num_cells + 1
    if is_last then
      table.insert(elements, { Foreground = { Color = '#000000' } })
    else
      table.insert(elements, { Foreground = { Color = text_fg } })
    end
    table.insert(elements, { Background = { Color = colors[cell_no] } })
    table.insert(elements, { Text = ' ' .. text .. ' ' })
    if not is_last then
      table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
      table.insert(elements, { Text = SOLID_LEFT_ARROW })
    end
    num_cells = num_cells + 1
  end

  while #cells > 0 do
    local cell = table.remove(cells, 1)
    push(cell, #cells == 0)
  end

  window:set_right_status(wezterm.format(elements))
end)


return config
