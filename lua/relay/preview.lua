local M = {}

require('relay.state').assign(M, 'preview', {
  win = nil,
  buf = nil,
})

local winValid = function()
  return M.win and vim.api.nvim_win_is_valid(M.win)
end
local bufValid = function()
  return M.buf and vim.api.nvim_buf_is_valid(M.buf)
end

M.show = function()
  if not winValid() then
    M.hide()

    M.buf = vim.api.nvim_create_buf(false, true)
    local frame = require('relay.sidebar').calculatePreviewFrame()

    local owin = vim.api.nvim_get_current_win()
    M.win = require('relay.utils').openWindow(M.buf, frame)
    vim.api.nvim_set_current_win(owin)
  end
  return M.win, M.buf
end

M.hide = function()
  if winValid() then
    vim.api.nvim_win_hide(M.win)
  end

  if bufValid() then
    vim.api.nvim_buf_delete(M.buf, { force = true })
  end
end

return M
