local M = {}

M.consumeOutLines = function(ctx, parse)
  local added = {}
  while true do
    local idx = ctx.out:find('\n')
    if idx == nil then
      idx = ctx.out:find('\r')
    end
    if idx == nil then
      break
    end
    local raw = ctx.out:sub(1, idx - 1)
    local log = parse(raw)
    table.insert(added, log)
    ctx.out = ctx.out:sub(idx + 1)
  end
  return added
end

M.mergeTables = function(a, b)
  if a == nil then
    a = {}
  end
  if b == nil then
    b = {}
  end

  local result = {}
  table.move(a, 1, #a, 1, result)
  table.move(b, 1, #b, #a + 1, result)
  return result
end

M.getOtherWindows = function(wins)
  local all = vim.api.nvim_list_wins()
  if wins == nil then
    return all
  end
  return vim.tbl_filter(function(value)
    return vim.tbl_contains(wins, value) == false
  end, all)
end

M._openWindow = function(buf, dim, border)
  return vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    col = dim.x,
    row = dim.y,
    width = dim.w,
    height = dim.h,
    style = 'minimal',
    border = border,
  })
end

M.openWindow = function(buf, dim)
  return M._openWindow(buf, dim, 'none')
end

M.openSingleBorderWindow = function(buf, dim)
  return M._openWindow(buf, dim, 'single')
end

return M
