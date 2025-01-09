local M = {}

require('relay.state').assign(M, 'timer', {
  timers = {},
})

local makeTimer = function(callback, delay)
  local ctx = { stopped = false }
  ctx.loop = function()
    if ctx.stopped then
      return
    end
    callback()
    vim.defer_fn(ctx.loop, delay)
  end
  ctx.loop()
  return {
    stop = function()
      ctx.stopped = true
    end,
  }
end

M.start = function(name, callback, interval)
  if M.timers[name] ~= nil then
    return
  end
  M.timers[name] = makeTimer(callback, interval)
end

M._destroy = function()
  for _, timer in pairs(M.timers) do
    timer.stop()
  end
  M.timers = {}
end

return M
