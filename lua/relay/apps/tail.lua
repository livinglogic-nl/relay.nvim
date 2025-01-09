local M = {}

M.create = function(url, mapper)
  return require('relay.apps.log_base').extend({
    start = function(params)
      local ctx = {
        out = '',
      }
      ctx.job = vim.system({ 'tail', '-80', '-f', url }, {
        stdout = function(_, str)
          if str == nil then
            return
          end
          ctx.out = ctx.out .. str
        end,
      })
      return ctx
    end,

    stop = function(ctx)
      ctx.job:kill(15)
    end,

    parse = function(params)
      local maxLogParseCols = 4096
      local logs = require('relay.utils').consumeOutLines(params.ctx, function(line)
        if string.len(line) > maxLogParseCols then
          return { type = 'ERROR', unix = 0, text = 'line > maxLogParseCols: ' .. #line }
        end
        return mapper(line)
      end)
      return logs
    end,
  })
end

return M
