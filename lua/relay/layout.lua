local M = {}

require('relay.state').assign(M, 'layout', {
  index = 1,
})

M.getActive = function()
  local layouts = require('relay.config').layouts
  return layouts[M.index]
end

M.changeFunc = function(dir)
  return function()
    local idx = M.index + dir
    local layouts = require('relay.config').layouts
    if idx < 1 then
      idx = #layouts
    end
    if idx > #layouts then
      idx = 1
    end
    M.index = idx
  end
end

M.next = M.changeFunc(1)
M.prev = M.changeFunc(-1)

return M
