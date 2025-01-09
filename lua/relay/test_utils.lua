local M = {}

local getUuid = function()
  local handle = io.popen('uuidgen')
  local result = handle:read('*a')
  handle:close()
  return vim.trim(result):lower()
end

M.makeTempDir = function(prefix)
  local uuid = getUuid()
  local tmp = '/tmp/test-relay/' .. prefix .. '-' .. uuid
  os.execute('mkdir -p ' .. tmp)
  return tmp
end

M.prepare = function(params)
  require('relay')._destroy()
  local cwd = M.makeTempDir('prep')
  vim.fn.chdir(cwd)
  local setFile = function(url, lines)
    local fh = io.open(cwd .. '/' .. url, 'w')
    fh:write(table.concat(lines, '\n'))
    fh:close()
  end
  local appendFile = function(url, lines)
    local fh = io.open(cwd .. '/' .. url, 'a')
    fh:write(table.concat(lines, '\n'))
    fh:close()
  end
  return {
    setFile = setFile,
    appendFile = appendFile,
  }
end

M.flexAssert = function(count, predicate, expect)
  vim.wait(1000, function()
    local a = vim.fn.json_encode(predicate())
    local b = vim.fn.json_encode(expect)
    local ok = a == b
    if ok then
      assert(true)
    elseif count == 0 then
      assert(false, 'count = ' .. count)
    else
      require('relay.log').info({ count = count })
      M.flexAssert(count - 1, predicate, expect)
    end
  end)
end

M.getSidebarBuffers = function()
  local result = {}
  local jobWins = require('relay.sidebar').jobWins
  if jobWins == nil then
    return {}
  end
  for _, jw in ipairs(jobWins) do
    local buf = vim.api.nvim_win_get_buf(jw.win)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    table.insert(result, lines)
  end
  return result
end

M.defaultApp = {
  start = function()
    return {
      systemObj = vim.system({ 'date' }, {}),
    }
  end,

  stop = function(ctx)
    ctx.systemObj:kill(15)
  end,

  update = function(params) end,

  view = function(params) end,
}

M.defaultLayouts = { { 'a', 'b' } }
M.defaultSources = {
  {
    name = 'a',
    app = M.defaultApp,
  },
  {
    name = 'b',
    app = M.defaultApp,
  },
}

M.defaultConfig = {
  cwd_config_path = 'relay.lua',
  sources = M.defaultSources,
  layouts = M.defaultLayouts,
}

return M
