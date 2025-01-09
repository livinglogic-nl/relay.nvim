local M = {}

M.defaultConfig = {
  sidebar_width = 60,
  bottom_margin = 2,
  cwd_config_path = 'relay.lua',
}

M.resolved = {}

setmetatable(M, {
  __index = function(t, k)
    if M.resolved[k] then
      return M.resolved[k]
    end
    return M.defaultConfig[k]
  end,
})

local emptyConfig = function()
  return {
    sources = {},
    layouts = {},
  }
end

local getLocalConfig = function()
  local loaded = loadfile(M.cwd_config_path)
  -- does not exist, no problem
  if loaded == nil then
    return emptyConfig()
  end

  local ok, result = pcall(loaded)
  if not ok then
    -- does exist but triggers an error
    require('relay.log').info(result)
    return emptyConfig()
  end
  return result
end

local mergeConfigs = function()
  local config = vim.tbl_deep_extend('force', {}, M._global_config)
  config.layouts =
    require('relay.utils').mergeTables(M._local_config.layouts, M._global_config.layouts)
  config.sources =
    require('relay.utils').mergeTables(M._local_config.sources, M._global_config.sources)
  M.resolved = config
end

M.init = function(global_config)
  M._global_config = global_config
  M._local_config = {}
  mergeConfigs()
end

M.loadLocal = function()
  M._local_config = getLocalConfig()
  mergeConfigs()
  return M._local_config
end

return M
