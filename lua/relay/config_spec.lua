local tu = require('relay.test_utils')

describe('config', function()
  local config = require('relay.config')

  it('Sets _global_config', function()
    local ctx = tu.prepare({})
    config.init(tu.defaultConfig)
    assert(config._global_config, '_global_config is defined')
  end)

  it('Sets _local_config', function()
    local ctx = tu.prepare({})
    config.init(tu.defaultConfig)
    assert(config._local_config, '_local_config is defined')
  end)

  it('Combines global and local config, local gets prio', function()
    local ctx = tu.prepare({})
    ctx.setFile('relay.lua', {
      'return {',
      'layouts = {',
      '{ "c", "d" },',
      '}',
      '}',
    })

    config.init(tu.defaultConfig)
    config.loadLocal()
    assert.same(config.layouts, {
      { 'c', 'd' },
      { 'a', 'b' },
    })
  end)
end)
