local M = {}

M.states = {}

M.assign = function(mod, name, init)
  if M.states[name] == nil then
    M.states[name] = vim.tbl_deep_extend('force', {}, init)
  end

  local state = M.states[name]
  setmetatable(mod, {
    __index = function(t, k)
      return state[k]
    end,

    __newindex = function(t, k, v)
      state[k] = v
    end,
  })
end

return M
