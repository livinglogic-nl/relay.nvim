local M = {}

require('relay.state').assign(M, 'sidebar', {
  jobWins = nil,
  canvas = { w = 80, h = 24 },
})

M.calculateCanvas = function()
  local sw = vim.opt.columns:get()
  local sh = vim.opt.lines:get()
  local config = require('relay.config')
  return { w = sw, h = sh - config.bottom_margin }
end

M.listenForResize = function()
  M.resize_id = vim.api.nvim_create_autocmd({
    'WinResized',
  }, {
    pattern = '*',
    callback = M.onResize,
  })
  M.onResize()
end

M.onResize = function()
  M.canvas = M.calculateCanvas()
  if M.isOpen() then
    M.open()
  end
end

M.open = function()
  M.close() -- ensure only on instance open
  M.openJobWins(M.getJobFrames())
  M.update()
end

M.getJobFrames = function()
  local layout = require('relay.layout').getActive()
  local names = require('relay.utils').mergeTables(layout, require('relay.adhoc').getAdhocs())
  local jobs = vim.tbl_map(require('relay.runtime').getJob, names)
  return M.calculateJobFrames(M.canvas, jobs)
end

M.openJobWins = function(jobFrames)
  local owin = vim.api.nvim_get_current_win()
  local jobWins = {}
  for i, jf in ipairs(jobFrames) do
    local win = require('relay.utils').openWindow(jf.job.buf, jf.frame)
    M.setWinbar({ nr = i, win = win, job = jf.job })
    table.insert(jobWins, {
      job = jf.job,
      frame = jf.frame,
      win = win,
    })
  end
  vim.api.nvim_set_current_win(owin)
  M.jobWins = jobWins
end

M.close = function()
  if M.jobWins == nil then
    return
  end
  for _, jw in ipairs(M.validJobWins()) do
    vim.api.nvim_win_hide(jw.win)
  end

  M.jobWins = nil
  require('relay.preview').hide()
end

M.toggle = function()
  if M.isOpen() then
    return M.close()
  end
  return M.open()
end

M.isOpen = function()
  return M.jobWins ~= nil
end

M.validJobWins = function()
  return vim.tbl_filter(function(jw)
    return vim.api.nvim_win_is_valid(jw.win)
  end, M.jobWins)
end

M.update = function()
  local cur = vim.api.nvim_get_current_win()

  local jwins = M.validJobWins()
  for _, jw in ipairs(jwins) do
    local focused = jw.win == cur
    local preview = function(next) end
    if focused then
      local row = vim.api.nvim_win_get_cursor(jw.win)[1]
      preview = function(next)
        local win, buf = require('relay.preview').show()
        next(win, buf, row)
      end
    end

    jw.job.source.app.view({
      ctx = jw.job.ctx,
      win = jw.win,
      focused = jw.win == cur,
      preview = preview,
    })
  end

  local anyFocused = vim.tbl_filter(function(jw)
    return jw.win == cur
  end, jwins)

  if #anyFocused == 0 then
    require('relay.preview').hide()
  end
end

M.setWinbar = function(params)
  local values = {
    params.job.source.name,
    params.win,
    params.job.buf,
  }
  local icon = params.job.source.icon
  if icon ~= nil then
    table.insert(values, 1, icon)
  end

  vim.api.nvim_set_option_value('winbar', table.concat(values, ' '), { win = params.win })
end

M.getJobWindowWidth = function(canvas)
  return math.floor(canvas.w / 2)
end

M.calculatePreviewFrame = function()
  local canvas = M.canvas
  local margin = 0
  local sidebarWidth = M.getJobWindowWidth(canvas)
  local previewWidth = canvas.w - sidebarWidth - margin
  return {
    x = margin,
    y = 0,
    w = previewWidth,
    h = canvas.h,
  }
end

M.calculateActionsFrame = function()
  local canvas = M.canvas
  return {
    x = canvas.w - M.getJobWindowWidth(canvas),
    y = 0,
    w = 1,
    h = canvas.h,
  }
end

M.calculateJobFrames = function(canvas, jobs)
  local result = {}

  local w = M.getJobWindowWidth(canvas)
  local ox = canvas.w - w
  local y = 0

  local step = math.floor(canvas.h / #jobs)
  local remain = canvas.h - #jobs * step

  for _, job in ipairs(jobs) do
    local h = step
    if remain > 0 then
      h = h + 1
      remain = remain - 1
    end
    table.insert(result, {
      job = job,
      frame = {
        x = ox,
        y = y,
        w = w,
        h = h,
      },
    })
    y = y + h
  end
  return result
end

M.tempWindow = function(buf)
  local w = M.getJobWindowWidth(M.canvas)
  return require('relay.utils').openWindow(buf, { x = 0, y = 0, w = w, h = M.canvas.h })
end

M.getWindow = function(nr)
  if nr == 0 then
    local wins = require('relay.utils').getOtherWindows(M.validJobWins())
    return wins[1]
  end
  local jw = M.validJobWins()[nr]
  return jw.win
end

M.focusWindow = function(nr)
  local win = M.getWindow(nr)
  if win then
    vim.api.nvim_set_current_win(win)
  end
end

M._destroy = function()
  M.close()

  if M.resize_id ~= nil then
    vim.api.nvim_del_autocmd(M.resize_id)
    M.resize_id = nil
  end
end

return M
