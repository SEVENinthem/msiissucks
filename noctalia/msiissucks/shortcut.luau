--!nonstrict
-- msiissucks - control-center tile. Click = on/off, right click = color panel.

local status = noctalia.state.get("status") or { state = "unknown", busy = false }

local function render()
  shortcut.setLabel(if status.busy then noctalia.tr("state.busy") else noctalia.tr("tile"))
  shortcut.setIcon("bulb-filled", "bulb-off")
  shortcut.setActive(status.state == "on")
  shortcut.setEnabled(not status.busy)
end

function onClick()
  noctalia.state.set("command", { action = "toggle", nonce = noctalia.nowMs() })
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
