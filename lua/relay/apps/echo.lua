local M = {}

M.create = function(message)
  local lines = vim.split(message, '\n')
  return {
    start = function()
      return {}
    end,
    stop = function(ctx) end,

    update = function(params)
      vim.api.nvim_buf_set_lines(params.buf, 0, 1, false, lines)
    end,

    view = function(params) end,
  }
end

return M
