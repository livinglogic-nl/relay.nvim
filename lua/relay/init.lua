local M = {}

M.setup = function(global_config)
  local config = require('relay.config')

  config.init(global_config)
  config.loadLocal()

  require('relay.sidebar').listenForResize()
  require('relay.timer').start('runtime', M.update, 80)
  M.addCommands()
end

M.addCommands = function()
  vim.api.nvim_create_user_command('RelayToggle', M.toggle, {})
  vim.api.nvim_create_user_command('RelayNext', M.nextLayout, {})
  vim.api.nvim_create_user_command('RelayPrev', M.prevLayout, {})
  vim.api.nvim_create_user_command('RelayFocus', function(opts)
    M.focusWindow(tonumber(opts.fargs[1]))
  end, { nargs = 1 })
  vim.api.nvim_create_user_command('RelayAction', M.action, {})
end

M.update = function()
  if require('relay.actions').isOpen() then
    return
  end
  require('relay.runtime').update()
  if require('relay.sidebar').isOpen() then
    require('relay.sidebar').update()
  end
end

M.open = function()
  if not require('relay.sidebar').isOpen() then
    require('relay.config').loadLocal()

    M.startLayoutJobs()
    require('relay.runtime').regenerateJobs()
    require('relay.sidebar').open()
  end
end

M.startLayoutJobs = function()
  local layout = require('relay.layout').getActive()

  local sourcesMap = {}
  vim.tbl_map(function(s)
    sourcesMap[s.name] = s
  end, require('relay.config').sources)

  for _, name in ipairs(layout) do
    local s = sourcesMap[name]
    require('relay.runtime').start(s, false)
  end
end

M.close = function()
  require('relay.adhoc').clearAdhocs()
  require('relay.sidebar').close()
  require('relay.actions').hide()
end

M.toggle = function()
  if not require('relay.sidebar').isOpen() then
    return M.open()
  end
  return M.close()
end

M.prevLayout = function()
  require('relay.layout').prev()
  M.activateLayout()
end

M.nextLayout = function()
  require('relay.layout').next()
  M.activateLayout()
end

M.activateLayout = function()
  if require('relay.sidebar').isOpen() then
    M.startLayoutJobs()
    require('relay.sidebar').open()
  end
end

M.action = function()
  local jobWins = require('relay.sidebar').jobWins
  if jobWins == nil then
    return
  end
  require('relay.actions').show(jobWins)
end

M.adhoc = function(source)
  require('relay.adhoc').addAdhoc(source);
  if require('relay.sidebar').isOpen() then
    require('relay.sidebar').open()
  end
end

M.run = function(name, args)
  return M.adhoc({
    name = name,
    app = require('relay.apps.shell').create(args),
  })
end

M.runDefault = function(args)
  M.run('shell', args);
end

M._destroy = function()
  require('relay.runtime')._destroy()
  require('relay.sidebar')._destroy()
  require('relay.timer')._destroy()
end

M.focusWindow = function(nr)
  local sidebar = require('relay.sidebar')
  sidebar.focusWindow(nr)
end

return M
