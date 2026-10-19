--!nonstrict
-- msiissucks - bar widget. A bulb tinted with the current lighting color.
--
--   Left click   on/off
--   Right click  color panel

local status = noctalia.state.get("status") or { state = "unknown", color = "#8B00FF", busy = false }

local function send(action)
  noctalia.state.set("command", { action = action, nonce = noctalia.nowMs() })
end

local function render()
  local on = status.state == "on"
  local glyph = if status.busy then "loader-2" elseif on then "bulb-filled" else "bulb-off"
  local color = if status.error then "error" elseif on then status.color else "on_surface_variant"

  barWidget.render(ui.glyph({ name = glyph, color = color }))

  local stateText = if status.busy then noctalia.tr("state.busy")
    elseif on then noctalia.tr("state.on")
    elseif status.state == "off" then noctalia.tr("state.off")
    else noctalia.tr("state.unknown")
  local rows = {
    { key = "Mystic Light", value = stateText },
    { key = noctalia.tr("label.color"), value = status.color },
  }
  if status.error then
    table.insert(rows, { key = noctalia.tr("label.error"), value = status.error })
  end
  table.insert(rows, { value = noctalia.tr("hint.bar") })
  barWidget.setTooltip(rows)
end

function onClick()
  if status.busy then return end
  send("toggle")
end

function onRightClick()
  noctalia.togglePanel("seveninthem/msiissucks:panel")
end

noctalia.state.watch("status", function(value)
  if type(value) == "table" then
    status = value
    render()
  end
end)

render()
