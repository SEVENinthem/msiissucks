--!nonstrict
-- msiissucks - color panel: power toggle, preset swatches, custom color picker.
-- Every pick applies immediately through the service.

local PRESETS = {
  "#8B00FF", "#FF00FF", "#FF0040", "#FF0000", "#FF6000",
  "#FFD000", "#00FF40", "#00FFD0", "#0040FF", "#FFFFFF",
}

local status = noctalia.state.get("status") or { state = "unknown", color = "#8B00FF", busy = false }
local isOpen = false
local closeButton = true

local function send(action, color)
  noctalia.state.set("command", { action = action, color = color, nonce = noctalia.nowMs() })
end

local function swatch(color)
  local selected = status.state == "on" and status.color == color
  return ui.box({
    key = color,
    width = 52,
    height = 36,
    radius = 10,
    fill = color,
    border = if selected then "on_surface" else "outline",
    borderWidth = if selected then 3 else 1,
    onClick = function()
      if not status.busy then send("on", color) end
    end,
  })
end

local function swatchRow(from, to)
  local children = {}
  for i = from, to do
    table.insert(children, swatch(PRESETS[i]))
  end
  return ui.row({ gap = 10, justify = "center" }, children)
end

local function render()
  if not isOpen then return end
  local on = status.state == "on"

  local header = {
    ui.glyph({ name = "bulb-filled", color = if on then status.color else "on_surface_variant", size = 20 }),
    ui.label({ text = "Mystic Light", fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
  }
  if closeButton then
    table.insert(header, ui.button({ glyph = "close", variant = "ghost", onClick = function() panel.close() end }))
  end

  local stateText = if status.busy then noctalia.tr("state.busy")
    elseif on then noctalia.tr("state.on")
    elseif status.state == "off" then noctalia.tr("state.off")
    else noctalia.tr("state.unknown")

  local footer = if status.error
    then ui.label({ text = status.error, color = "error", maxLines = 2 })
    else ui.label({ text = noctalia.tr("hint.panel"), color = "on_surface_variant" })

  panel.render(ui.column({ flexGrow = 1, gap = 14 }, {
    ui.row({ align = "center", gap = 10 }, header),

    ui.row({ align = "center", gap = 12 }, {
      ui.box({ width = 44, height = 44, radius = 12, fill = status.color, border = "outline", borderWidth = 1 }),
      ui.column({ gap = 2, flexGrow = 1 }, {
        ui.label({ text = stateText, fontWeight = "medium", color = "on_surface" }),
        ui.label({ text = status.color, color = "on_surface_variant" }),
      }),
      ui.toggle({
        checked = on,
        enabled = not status.busy,
        onChange = function(value)
          send(if value == "true" then "on" else "off")
        end,
      }),
    }),

    ui.separator({}),

    swatchRow(1, 5),
    swatchRow(6, 10),

    ui.button({
      text = noctalia.tr("button.custom"),
      glyph = "color-picker",
      variant = "outline",
      enabled = not status.busy,
      onClick = function()
        noctalia.openColorPicker(status.color, function(color)
          if color then send("on", color) end
        end)
      end,
    }),

    ui.spacer({ flexGrow = 1 }),
    footer,
  }))
end

noctalia.state.watch("status", function(value)
  if type(value) == "table" then
    status = value
    render()
  end
end)

function onOpen(_context)
  isOpen = true
  closeButton = noctalia.getSetting("shell.show_close_buttons") ~= false
  status = noctalia.state.get("status") or status
  render()
end

function onClose()
  isOpen = false
end
