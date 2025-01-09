it('tail sets buffer contents as log lines appear', function()
  local delay = 100
  local tu = require('relay.test_utils')
  local workspace = tu.prepare({})
  local app = require('relay.apps.tail').create('some.log', function(line)
    local obj = vim.fn.json_decode(line)
    return {
      type = obj.level,
      unix = obj.date * 1000,
      text = obj.msg,
      url = obj.url,
    }
  end)

  local buf = vim.api.nvim_create_buf(false, true)
  local ctx = app.start()

  local getLines = function()
    return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  end

  local url = '/tmp/where-the-log-came-from.lua:100'

  local logBatch = vim.tbl_map(vim.fn.json_encode, {
    { level = 'INFO', date = 1735689600, msg = 'first post', url = url },
    { level = 'ERROR', date = 1735689605, msg = 'error 5 seconds later', url = url },
  })

  workspace.setFile('some.log', {
    logBatch[1],
    '',
  })

  vim.wait(delay, function() end)
  app.update({ buf = buf, ctx = ctx })
  assert.same(getLines(), { '| 01:00:00 og-came-from.lua:100 first post' })

  workspace.appendFile('some.log', {
    logBatch[2],
    '',
  })

  vim.wait(delay, function() end)
  app.update({ buf = buf, ctx = ctx })

  assert.same(getLines(), {
    '| 01:00:00 og-came-from.lua:100 first post',
    '█ 01:00:05 og-came-from.lua:100 error 5 seconds later',
  })
end)
