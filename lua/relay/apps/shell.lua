local M = {}

M.create = function(cmd, opts)
  if opts == nil then
    opts = {}
  end
  return {
    start = function()
      local ok, result = pcall(function()
        local ctx = {}
        ctx.job = vim.fn.termopen(
          cmd,
          vim.tbl_deep_extend('keep', {
            stdout_buffered = false,
            on_exit = function()
              ctx.healthy = false
            end,
          }, opts or {})
        )
        return ctx
      end)
      if ok then
        return result
      end
      return {
        job = vim.fn.termopen({ 'echo', 'Could not open command' }, {
          stdout_buffered = false,
        }),
      }
    end,

    stop = function(ctx)
      vim.fn.jobstop(ctx.job)
    end,

    update = function() end,

    view = function(params)
      if params.focused then
        return
      end
      M.scrollToEnd(params.win)
    end,
  }
end

M.scrollToEnd = function(win)
  local sh = vim.opt.lines:get()
  local buf = vim.api.nvim_win_get_buf(win)
  local maxrow = vim.api.nvim_buf_line_count(buf)
  if maxrow > sh then
    vim.api.nvim_win_set_cursor(win, { maxrow, 0 })
    return
  end

  local cursor = maxrow

  local getLineAtRow = function(buf, row)
    local lines = vim.api.nvim_buf_get_lines(buf, row - 1, row, true)
    return lines[1]
  end
  local lineAtMaxRow = getLineAtRow(buf, maxrow)
  if string.len(lineAtMaxRow) == 0 then
    local minrow = maxrow - sh
    if minrow < 0 then
      minrow = 0
    end
    local lines = vim.api.nvim_buf_get_lines(buf, minrow, maxrow, false)
    for i = #lines, 1, -1 do
      if lines[i]:len() > 0 then
        cursor = i + 0
        break
      end
    end
    if cursor == maxrow then
      cursor = 1
    end
  end
  vim.api.nvim_win_set_cursor(win, { cursor, 0 })
end

return M
