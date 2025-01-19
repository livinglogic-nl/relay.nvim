local tu = require('relay.test_utils')

describe('sidebar', function()
  local wincount = function()
    return #vim.api.nvim_list_wins()
  end

  local sidebar = require('relay.sidebar')
  it('starts off closed', function()
    require('relay').setup(tu.defaultConfig)
    assert(wincount(), 1)
  end)

  it('opens on request', function()
    local ctx = tu.prepare({})
    require('relay').setup(vim.tbl_deep_extend('force', tu.defaultConfig, {
      sources = { tu.defaultSources[1] },
      layouts = {
        { 'a' },
      },
    }))
    assert.equals(wincount(), 1)
    require('relay').open()
    assert.equals(wincount(), 2)
  end)

  it('shows the correct content in the windows', function()
    local ctx = tu.prepare({})
    require('relay').setup(vim.tbl_deep_extend('force', tu.defaultConfig, {
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

    require('relay').open()
    local buffers = tu.getSidebarBuffers()
    assert.same(buffers, {
      { 'content for a' },
      { 'content for b' },
    })
  end)

  it('closes on request', function()
    local ctx = tu.prepare({})
    require('relay').setup(vim.tbl_deep_extend('force', tu.defaultConfig, {
      sources = { tu.defaultSources[1] },
      layouts = {
        { 'a' },
      },
    }))
    assert.equals(wincount(), 1)
    require('relay').open()
    assert.equals(wincount(), 2)
    require('relay').close()
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
    require('relay').setup(tu.defaultConfig)
    sidebar.open()
    local after = vim.api.nvim_get_current_win()
    assert.equal(before, after)
  end)
end)
