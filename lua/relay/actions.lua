local M = {}

require('relay.state').assign(M, 'actions', {
  win = nil,
  buf = nil,
})

local winValid = function()
  return M.win and vim.api.nvim_win_is_valid(M.win)
end
local bufValid = function()
  return M.buf and vim.api.nvim_buf_is_valid(M.buf)
end

M.namespace = vim.api.nvim_create_namespace('relay.actions')

M.isOpen = function()
  return winValid()
end

M.getWinMinMax = function(jw)
  local info = vim.fn.getwininfo(jw.win)[1]
  local wmin = info.topline - 1
  local wmax = wmin + info.height
  return wmin, wmax
end

M.setStripes = function(buf, wmin, wmax)
  local winlines = vim.api.nvim_buf_get_lines(buf, wmin, wmax, true)
  for i = 1, #winlines, 2 do
    local line = winlines[i]
    local len = string.len(line)
    local tr = wmin + i - 1
    if len > 0 then
      vim.api.nvim_buf_set_extmark(buf, M.namespace, tr, 0, {
        end_col = len,
        hl_group = 'CursorLine',
        hl_mode = 'combine',
      })
    end
  end
end

M.show = function(jobWins)
  M.hide()

  local frame = require('relay.sidebar').calculateActionsFrame()
  M.buf = vim.api.nvim_create_buf(false, true)
  M.win = require('relay.utils').openWindow(M.buf, frame)
  M.sidebarBuffers = vim.tbl_map(function(jw)
    return jw.job.buf
  end, jobWins)

  local alphabet = vim.split("1234567890zxcasdqwevbnfghrtym,.jkluio/;'\\p[]", '')
  local ai = 1
  local letters = {}

  local jobWinsWithAction = vim.tbl_filter(function(jw)
    return jw.job.source.app.action ~= nil
  end, jobWins)

  for _, jw in pairs(jobWinsWithAction) do
    local wmin, wmax = M.getWinMinMax(jw)
    M.setStripes(jw.job.buf, wmin, wmax)

    local rows = jw.frame.h - 1
    table.insert(letters, '')

    for row = 1, rows, 1 do
      if ai > #alphabet then
        table.insert(letters, ' ')
      else
        local winrow = row + wmin
        local letter = alphabet[ai]
        local obj = {
          job = jw.job,
          row = winrow,
        }
        vim.keymap.set('n', letter, function()
          M.hide()
          local m = obj.job.source.app.action
          if m == nil then
            return
          end
          m({ ctx = obj.job.ctx }, obj.row)
        end, { buffer = true })
        table.insert(letters, letter)
        ai = ai + 1
      end
    end
  end

  vim.api.nvim_buf_set_lines(M.buf, 0, -1, true, letters)
  vim.api.nvim_buf_set_extmark(M.buf, M.namespace, 0, 0, {
    end_col = 1,
    end_row = #letters - 1,
    hl_group = 'IncSearch',
  })
end

M.hide = function()
  if winValid() then
    vim.api.nvim_win_hide(M.win)
  end

  if bufValid() then
    vim.api.nvim_buf_delete(M.buf, { force = true })
  end

  if M.sidebarBuffers then
    for _, buf in ipairs(M.sidebarBuffers) do
      vim.api.nvim_buf_clear_namespace(buf, M.namespace, 0, -1)
    end
  end
end

return M
