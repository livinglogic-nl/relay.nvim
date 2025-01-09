local M = {}

require('relay.state').assign(M, 'adhoc', {
  adhocs = {},
})

M.addAdhoc = function(source)
  M.adhocs[source.name] = require('relay.runtime').start(source)
end

M.clearAdhocs = function()
  for _, job in pairs(M.adhocs) do
    require('relay.runtime').stop(job)
  end
  M.adhocs = {}
end

M.getAdhocs = function()
  return vim.tbl_keys(M.adhocs)
end

return M
