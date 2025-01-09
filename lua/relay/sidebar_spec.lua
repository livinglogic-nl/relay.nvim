local tu = require('relay.test_utils')

describe('sidebar', function()
  local config = require('relay.config')
  local wincount = function()
    return #vim.api.nvim_list_wins()
  end
  local sidebar = require('relay.sidebar')
  it('starts off closed', function()
    require('relay').init(tu.defaultConfig)
    assert(wincount(), 1)
  end)

  it('opens on request', function()
    local ctx = tu.prepare({})
    require('relay').init(vim.tbl_deep_extend('force', tu.defaultConfig, {
      sources = { tu.defaultSources[1] },
      layouts = {
        { 'a' },
      },
    }))
    assert.equals(wincount(), 1)
    sidebar.open()
    assert.equals(wincount(), 2)
  end)

  it('shows the correct content in the windows', function()
    local ctx = tu.prepare({})
    require('relay').init(vim.tbl_deep_extend('force', tu.defaultConfig, {
      sources = {
        {
          name = 'a',
          app = require('relay.apps.echo').create('content for a'),
        },
        {
          name = 'b',
          app = require('relay.apps.echo').create('content for b'),
        },
      },
      layouts = {
        { 'a', 'b' },
      },
    }))

    sidebar.open()
    local buffers = tu.getSidebarBuffers()
    assert.same(buffers, {
      { 'content for a' },
      { 'content for b' },
    })
  end)

  it('closes on request', function()
    local ctx = tu.prepare({})
    require('relay').init(vim.tbl_deep_extend('force', tu.defaultConfig, {
      sources = { tu.defaultSources[1] },
      layouts = {
        { 'a' },
      },
    }))
    assert.equals(wincount(), 1)
    sidebar.open()
    assert.equals(wincount(), 2)
    sidebar.close()
    assert.equals(wincount(), 1)
  end)

  it('calculates job frames', function()
    local result = sidebar.calculateJobFrames({ w = 80, h = 22 }, {
      {},
      {},
    })
    assert.same(result, {
      {
        job = {},
        frame = { x = 40, y = 0, w = 40, h = 11 },
      },
      {
        job = {},
        frame = { x = 40, y = 11, w = 40, h = 11 },
      },
    })
  end)

  it('sidebar open() puts focus back to the original window', function()
    local before = vim.api.nvim_get_current_win()
    require('relay').init(tu.defaultConfig)
    sidebar.open()
    local after = vim.api.nvim_get_current_win()
    assert.equal(before, after)
  end)

  it('TODO: test job windows have a win bar', function() end)
  it('TODO: test sidebar.isOpen', function() end)
end)
