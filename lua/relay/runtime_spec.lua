local tu = require('relay.test_utils')

describe('runtime', function()
  local runtime = require('relay.runtime')
  local getpid = function(job)
    return job.ctx.systemObj.pid
  end
  it('Can start a job from a source', function()
    local ctx = tu.prepare({})
    local job = runtime.start(tu.defaultSources[1])
    assert(string.match(job.ctx.systemObj.pid, '[0-9]+'))
  end)

  it('Restarts job if job of that source was already started', function()
    local ctx = tu.prepare({})
    local job1 = runtime.start(tu.defaultSources[1])
    local job2 = runtime.start(tu.defaultSources[1])
    assert(getpid(job1) ~= getpid(job2))
    assert.equals(runtime.jobCount(), 1)
  end)

  it('Can start multiple jobs from differing sources', function()
    local ctx = tu.prepare({})
    local job1 = runtime.start(tu.defaultSources[1])
    local job2 = runtime.start(tu.defaultSources[2])
    assert(getpid(job1) ~= getpid(job2))
  end)

  it('Regenerates unhealty jobs on demand', function()
    local ctx = tu.prepare({})
    local job = runtime.start({
      name = 'a',
      app = require('relay.apps.shell').create({ 'date' }),
    })

    vim.wait(100, function() end)
    assert(job.ctx.healthy == false)

    local a = job.ctx.job
    runtime.regenerateJobs()
    local b = runtime.getJob('a').ctx.job

    assert(a ~= b)
  end)
end)
