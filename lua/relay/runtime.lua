local M = {}

require('relay.state').assign(M, 'runtime', {
  jobs = {},
})

M.startSources = function(sources)
  local todo = vim.tbl_filter(function(source)
    return M.jobs[source.name] == nil
  end, sources)

  vim.tbl_map(M.start, todo)
end

M.jobCount = function()
  return #vim.tbl_keys(M.jobs)
end

M.update = function()
  if M.jobs == nil then
    return
  end
  for _, job in pairs(M.jobs) do
    M.updateJob(job)
  end
end

M.getJob = function(name)
  local result = M.jobs[name]
  if result == nil then
    return nil
  end
  if not vim.api.nvim_buf_is_valid(result.buf) then
    result.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(result.buf, 0, -1, true, { 'buffer invalid' })
  end
  return result
end

M.updateJob = function(job)
  job.source.app.update({
    buf = job.buf,
    ctx = job.ctx,
  })
end

M.regenerateJobs = function()
  for _, job in pairs(M.jobs) do
    if job.ctx.healthy == false then
      M.start(job.source)
    end
  end
end

M.start = function(source)
  local job = M.jobs[source.name]
  if job ~= nil then
    M.stop(job)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win = require('relay.sidebar').tempWindow(buf)
  job = {
    source = source,
    ctx = source.app.start({ buf = buf }),
    buf = buf,
  }
  vim.api.nvim_win_hide(win)
  M.jobs[source.name] = job
  M.updateJob(job)
  return job
end

M.stop = function(job)
  job.source.app.stop(job.ctx)
  M.jobs[job.source.name] = nil
end

M._destroy = function()
  for _, value in pairs(M.jobs) do
    M.stop(value)
  end
  M.jobs = {}
end

return M
