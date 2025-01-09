local M = {}

M.extend = function(methods)
  local getLog = function(params, row)
    return params.ctx.backlog[row]
  end

  return {
    start = methods.start,
    parse = methods.parse,
    stop = methods.stop,

    update = function(params)
      local logs = methods.parse(params)
      M.update(params, logs)
    end,

    view = function(params)
      params.preview(function(win, buf, row)
        local log = getLog(params, row)
        local lines = vim.split(log.details, '\n')
        vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
      end)

      if not params.focused then
        local buf = vim.api.nvim_win_get_buf(params.win)
        local cursor = vim.api.nvim_buf_line_count(buf)
        vim.api.nvim_set_option_value('wrap', false, { win = params.win })
        vim.api.nvim_win_set_cursor(params.win, { cursor, 0 })
      end
    end,

    action = function(params, row)
      local log = getLog(params, row)
      local parts = vim.split(log.url, ':')
      local file = parts[1]
      local row = parts[2]
      vim.cmd('e ' .. parts[1])
      vim.api.nvim_win_set_cursor(0, { tonumber(parts[2]), 0 })
    end,
  }
end

local typeToHighlight = {
  INFO = '@lsp.type.property',
  WARN = '@lsp.type.number',
  TRACE = '@lsp.type.type',
  ERROR = 'Error',
}
local typeToIcon = {
  INFO = '|',
  WARN = '▌',
  TRACE = '|',
  ERROR = '█',
}

local namespace = vim.api.nvim_create_namespace('relay.nvim')

local trimLastPart = function(parts, maxw)
  local sum = 0
  local i = 0
  return vim.tbl_map(function(part)
    i = i + 1
    if i == #parts then
      local max = maxw - sum
      return part:sub(1, max)
    end
    sum = sum + string.len(part)
    return part
  end, parts)
end

local spaceParts = function(parts)
  local i = 0
  return vim.tbl_map(function(part)
    i = i + 1
    if i == #parts then
      return part
    end
    return part .. ' '
  end, parts)
end

local timezoneOffsetInSeconds = function()
  local timezone = os.date('%z') -- "+0200"
  local signum, hours, minutes = timezone:match('([+-])(%d%d)(%d%d)')
  return (tonumber(signum .. hours) * 3600 + tonumber(signum .. minutes) * 60)
end

local timezoneOffset = timezoneOffsetInSeconds()

local trimStart = function(str, max)
  local len = string.len(str)
  if len < max then
    return str .. ('.'):rep(max - len)
  end
  return str:sub(-max)
end

local logToRun = function(value, cols)
  local time = function(obj)
    if obj.unix == 0 then
      return string.rep('.', 8)
    end
    local s = math.floor(obj.unix / 1000)
    return os.date('%H:%M:%S', s) -- + timezoneOffset);
  end

  local typeIcon = value.typeIcon
  if typeIcon == nil then
    typeIcon = typeToIcon[value.type]
  end

  local url = 'unknown'
  if value.url then
    url = value.url
  end

  local flatText = value.text:gsub('\n *', '·')

  return {
    parts = trimLastPart(
      spaceParts({
        typeIcon,
        time(value),
        trimStart(url, 20),
        flatText,
      }),
      cols
    ),
    colors = {
      typeToHighlight[value.type],
      'Comment',
      'LineNr',
      nil,
    },
  }
end

local logsToRuns = function(logs, cols)
  return vim.tbl_map(function(log)
    return logToRun(log, cols)
  end, logs)
end

M.getLogs = function(params, mapper)
  local maxLogParseCols = 4096
  local logs = require('relay.utils').consumeOutLines(params.ctx, function(line)
    if string.len(line) > maxLogParseCols then
      return { type = 'ERROR', unix = 0, text = 'line > maxLogParseCols: ' .. #line }
    end
    return mapper(line)
  end)
  return logs
end

M.update = function(params, logs)
  if #logs == 0 then
    return
  end

  if params.ctx.backlog == nil then
    params.ctx.backlog = {}
  end
  for _, log in ipairs(logs) do
    table.insert(params.ctx.backlog, log)
  end

  local row = vim.api.nvim_buf_line_count(params.buf)
  if row == 1 then
    local lines = vim.api.nvim_buf_get_lines(params.buf, 0, 1, false)
    if lines[1] == '' then
      row = 0
    end
  end

  local runs = logsToRuns(logs, 256)
  vim.api.nvim_buf_set_lines(
    params.buf,
    row,
    row + #runs,
    false,
    vim.tbl_map(function(run)
      return table.concat(run.parts, '')
    end, runs)
  )

  for r, run in ipairs(runs) do
    local c = 0
    for i, part in ipairs(run.parts) do
      local len = string.len(part)
      local color = run.colors[i]
      if color ~= nil then
        vim.api.nvim_buf_set_extmark(params.buf, namespace, row + r - 1, c, {
          end_col = c + len,
          hl_group = color,
        })
      end
      c = c + len
    end
  end
end

return M
