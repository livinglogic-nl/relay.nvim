it('Merges tables', function()
  local result = require('relay.utils').mergeTables({ 'a' }, { 'b' })
  assert.same(result[1], 'a')
  assert.same(result[2], 'b')
end)
