--!nonstrict
-- msiissucks - headless service. The only entry that runs the script.
--
--   "command" (in)  { action = "on" | "off" | "toggle", color = "#RRGGBB"?, nonce }
--   "status"  (out) { state = "on" | "off" | "unknown", color = "#RRGGBB", busy, error? }
--
-- OpenRGB takes ~5 s per apply, so commands arriving while one runs are coalesced:
-- only the newest one is kept and runs next.

local status = { state = "unknown", color = "#8B00FF", busy = false, error = nil }
local running = false
local queued = nil

local function stateDir()
  local xdg = noctalia.getenv("XDG_STATE_HOME")
  if xdg == nil or xdg == "" then
    xdg = noctalia.expandPath("~/.local/state")
  end
  return `{xdg}/msiissucks`
end

local function normalizeColor(c)
  if type(c) ~= "string" then return nil end
  local hex = string.match(noctalia.string.trim(c), "^#?(%x%x%x%x%x%x)$")
  return if hex then "#" .. string.upper(hex) else nil
end

local function publish()
  noctalia.state.set("status", {
    state = status.state,
    color = status.color,
    busy = running,
    error = status.error,
  })
end

-- Pull state/color written by the script (ours, the TUI, or the boot unit).
local function readFiles()
  local dir = stateDir()
  local st = noctalia.readFile(`{dir}/state`)
  local color = noctalia.readFile(`{dir}/color`)
  local changed = false
  if st then
    st = noctalia.string.trim(st)
    if (st == "on" or st == "off") and st ~= status.state then
      status.state = st
      changed = true
    end
  end
  local c = normalizeColor(color)
  if c and c ~= status.color then
    status.color = c
    changed = true
  end
  return changed
end

local function lastLine(s)
  local line = ""
  for l in string.gmatch(s or "", "[^\n]+") do
    line = l
  end
  return line
end

local run

local function finish(result, cmd)
  running = false
  if result.exitCode == 0 then
    status.error = nil
    status.state = if cmd.action == "off" then "off" else "on"
    if cmd.color then status.color = cmd.color end
  else
    local err = lastLine(result.stderr)
    if err == "" then err = lastLine(result.stdout) end
    if result.timedOut then err = noctalia.tr("error.timeout") end
    if result.exitCode == 127 then err = noctalia.tr("error.not_found") end
    status.error = err
    noctalia.notifyError("msiissucks", err)
  end
  readFiles()
  publish()
  if queued then
    local next = queued
    queued = nil
    run(next)
  end
end

run = function(cmd)
  if running then
    queued = cmd
    return
  end
  if cmd.action == "toggle" then
    cmd = { action = if status.state == "on" then "off" else "on", color = cmd.color }
  end

  local bin = noctalia.expandPath(noctalia.getConfig("command") or "~/.local/bin/msiissucks")
  local argv = { bin, if cmd.action == "off" then "OFF" else "ON" }
  if cmd.action == "on" and cmd.color then
    table.insert(argv, string.sub(cmd.color, 2))
  end

  running = true
  status.error = nil
  publish()
  local ok = noctalia.runAsync(argv, function(result)
    finish(result, cmd)
  end, 60000)
  if not ok then
    finish({ exitCode = 1, stdout = "", stderr = noctalia.tr("error.launch"), timedOut = false }, cmd)
  end
end

local function handle(cmd)
  if type(cmd) ~= "table" then return end
  local action = cmd.action
  if action ~= "on" and action ~= "off" and action ~= "toggle" then return end
  run({ action = action, color = normalizeColor(cmd.color) })
end

noctalia.state.watch("command", handle)

-- Cheap file poll so CLI/TUI changes reach the bar without a click.
function update()
  noctalia.setUpdateInterval(3000)
  if not running and readFiles() then
    publish()
  end
end

-- noctalia msg plugin seveninthem/msiissucks:service all on [RRGGBB] | off | toggle
function onIpc(event, payload)
  handle({ action = string.lower(event or ""), color = payload })
end

readFiles()
publish()
