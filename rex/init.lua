-- Navigation
rex.bind("alt+j", "pane.focus.down")
rex.bind("alt+k", "pane.focus.up")
rex.bind("alt+h", "focus_or_tab", { direction = "left" })
rex.bind("alt+l", "focus_or_tab", { direction = "right" })

for i = 1, 9 do
  rex.bind("alt+" .. i, "client.tab.goto", { index = i })
end

local function collect_rects(node, out)
  if not node then return end
  if node.block_id then
    out[node.block_id] = node.rect
  elseif node.split then
    collect_rects(node.split.before, out)
    collect_rects(node.split.after, out)
  end
end

local function has_neighbor(rects, id, direction)
  local r = rects[id]
  if not r then return true end
  local eps = 1e-3
  for other, o in pairs(rects) do
    if other ~= id and o[2] < r[2] + r[4] - eps and o[2] + o[4] > r[2] + eps then
      if direction == "left" and o[1] + o[3] <= r[1] + eps then return true end
      if direction == "right" and o[1] >= r[1] + r[3] - eps then return true end
    end
  end
  return false
end

rex.action{
  name  = "focus_or_tab",
  title = "Focus Pane or Tab",
  args  = { direction = "string" },
  run   = function(ctx, args)
    local view, err = rex.session.view{}
    if err ~= nil then error(err, 0) end
    local rects = {}
    for _, w in ipairs(view.windows or {}) do
      if w.window_id == view.active_window_id then
        for _, l in ipairs(w.layers or {}) do
          if l.kind == "tiled" then collect_rects(l.layout, rects) end
        end
      end
    end
    if has_neighbor(rects, ctx.block_id, args.direction) then
      rex.client.queue("pane.focus." .. args.direction)
    elseif args.direction == "left" then
      rex.client.queue("client.tab.previous")
    else
      rex.client.queue("client.tab.next")
    end
  end,
}

rex.action{
  name  = "split_alternate",
  title = "Split Pane on Longer Side",
  run   = function(ctx, args)
    local size, err = rex.block.call("com.superlogical.terminal", "size", { block_id = ctx.block_id })
    if err ~= nil then error(err, 0) end
    local cw, ch = size.cell_width_px or 1, size.cell_height_px or 2
    if size.columns * cw >= size.rows * ch then
      rex.client.queue("pane.split.right")
    else
      rex.client.queue("pane.split.down")
    end
  end,
}

-- Blocks
rex.bind("alt+n", "split_alternate")
rex.bind("alt+shift+n", "pane.split.down")
rex.bind("alt+f", "scratch_toggle")
rex.bind("alt+shift+f", "pane.new_floating")
rex.bind("ctrl+shift+e", "scrollback_edit")

-- Tabs
rex.bind("alt+i", "client.tab.move.backward")
rex.bind("alt+o", "client.tab.move.forward")
rex.bind("f2", "client.tab.rename")
rex.bind("shift+cmd+w", "client.tab.close")

-- Sessions
rex.bind("alt+cmd+[", "session.previous")
rex.bind("alt+cmd+]", "session.next")
rex.bind("shift+f2", "session.rename")

-- Prefix
rex.action{
  name  = "scratch_toggle",
  title = "Toggle Floating Shell",
  run   = function(ctx, args)
    local view, err = rex.session.view{}
    if err ~= nil then error(err, 0) end
    local floating = false
    for _, w in ipairs(view.windows or {}) do
      if w.window_id == view.active_window_id then
        for _, l in ipairs(w.layers or {}) do
          if l.kind == "floating" then floating = true end
        end
      end
    end
    if floating then
      rex.client.queue("pane.minimize_all_floating")
    else
      rex.client.queue("pane.new_floating")
    end
  end,
}

local terminal = "com.superlogical.terminal"
local max_tool_lines = 100

local function truncate(s, max)
  local lines, n = {}, 0
  for line in (s .. "\n"):gmatch("(.-)\n") do
    n = n + 1
    if n <= max then lines[#lines + 1] = line end
  end
  if n > max then lines[#lines + 1] = ("[... %d more lines]"):format(n - max) end
  return table.concat(lines, "\n")
end

local function render_opencode(data)
  local out = { "# " .. (type(data.info.title) == "string" and data.info.title or "OpenCode session"), "" }
  for _, m in ipairs(data.messages or {}) do
    if m.type == "user" and type(m.text) == "string" then
      out[#out + 1] = "## User"
      out[#out + 1] = ""
      out[#out + 1] = m.text
      out[#out + 1] = ""
    elseif m.type == "assistant" then
      out[#out + 1] = "## Assistant"
      out[#out + 1] = ""
      for _, p in ipairs(m.content or {}) do
        if p.type == "text" and type(p.text) == "string" then
          out[#out + 1] = p.text
          out[#out + 1] = ""
        elseif p.type == "tool" then
          local st = p.state or {}
          out[#out + 1] = ("### tool: %s (%s)"):format(tostring(p.name), tostring(st.status))
          out[#out + 1] = "````json"
          out[#out + 1] = truncate(rex.json.encode(st.input or {}), max_tool_lines)
          out[#out + 1] = "````"
          for _, c in ipairs(st.content or {}) do
            if c.type == "text" and type(c.text) == "string" then
              out[#out + 1] = "````"
              out[#out + 1] = truncate(c.text, max_tool_lines)
              out[#out + 1] = "````"
            end
          end
          out[#out + 1] = ""
        end
      end
    end
  end
  return table.concat(out, "\n")
end

local function opencode_transcript(fg)
  local title = rex.block.call(terminal, "title", {})
  local name = type(title) == "table" and type(title.title) == "string" and title.title:gsub("^OC | ", "") or ""
  local list = rex.exec({ fg.path, "session", "list" }, { cwd = fg.cwd, timeout = 30 })
  if not list or not list.ok then return nil, "opencode session list failed" end
  local first, match
  for line in list.stdout:gmatch("[^\n]+") do
    local id, t = line:match("^(ses_[^\t]+)\t([^\t]*)")
    if id then
      first = first or id
      if not match and t == name then match = id end
    end
  end
  local id = match or first
  if not id then return nil, "no opencode session found for " .. fg.cwd end
  local exp = rex.exec({ fg.path, "session", "export", id }, { cwd = fg.cwd, timeout = 60 })
  if not exp or not exp.ok then return nil, "opencode session export failed" end
  local data, derr = rex.json.decode(exp.stdout)
  if derr ~= nil or type(data) ~= "table" then return nil, "could not parse the session export" end
  return render_opencode(data)
end

rex.action{
  name  = "scrollback_edit",
  title = "Edit Scrollback in $EDITOR",
  run   = function(ctx, args)
    local text, suffix = nil, ""
    local proc = rex.block.call(terminal, "process", {})
    local fg = type(proc) == "table" and proc.foreground or nil
    if fg and fg.name == "opencode" then
      local err
      text, err = opencode_transcript(fg)
      if not text then error(err, 0) end
      suffix = ".md"
    else
      local dump, err = rex.block.call(terminal, "format", { format = "text", trim = true, unwrap = true })
      if err ~= nil then error(err, 0) end
      text = dump.content
    end
    local tmp, terr = rex.exec(
      { "sh", "-c", 'f=$(mktemp "${TMPDIR:-/tmp}/rex-scrollback.XXXXXX") && g="$f$1" && { [ "$g" = "$f" ] || mv "$f" "$g"; } && cat > "$g" && printf %s "$g"', "sh", suffix },
      { stdin = text }
    )
    if terr ~= nil or not tmp.ok then error(terr or tmp.stderr, 0) end
    local _, lerr = rex.session.new_layer{
      focus  = true,
      bounds = { 0.05, 0.05, 0.9, 0.9 },
      layout = rex.layout.block{
        flavor  = terminal .. ".shell",
        options = { command = { "nvim", "+normal G", tmp.stdout } },
      },
    }
    if lerr ~= nil then error(lerr, 0) end
  end,
}

rex.bind("ctrl+space", "client.mode.enter", { name = "prefix", once = true })
rex.mode("prefix", { exclusive = true })

rex.bind("prefix/h", "pane.focus.left")
rex.bind("prefix/j", "pane.focus.down")
rex.bind("prefix/k", "pane.focus.up")
rex.bind("prefix/l", "pane.focus.right")
rex.bind("prefix/n", "client.tab.new")
rex.bind("prefix/d", "pane.split.down")
rex.bind("prefix/v", "pane.split.right")
rex.bind("prefix/x", "pane.close")
rex.bind("prefix/f", "pane.zoom")
rex.bind("prefix/c", "pane.rename")
rex.bind("prefix/e", "scrollback_edit")
rex.bind("prefix/w", "session.switch")
rex.bind("prefix/p", "client.tab.previous")

-- Others
rex.bind("cmd+b", "client.sidebar.toggle")
