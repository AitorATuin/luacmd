local assert = require 'luassert'
local say = require 'say'

local function tequal(_, arguments)
  local t = {}
  local n = #arguments
  for _, v in ipairs(arguments) do
    t[v] = true
  end
  return function (value)
    if #value ~= n then return false end
    for _, v in ipairs(value) do
      if not t[v] then return false end
    end
    return true
  end
end

say:set('assertion.tequal.positive',
        'Execped table \'%s\' to be equal to \'%s\'')
say:set('assertion.tequal.negative',
        'Execped table \'%s\' not to be equal to \'%s\'')

assert:register('assertion', 'tequal', tequal, 'assertion.tequal.positive',
                'assertion.tequal.negative')



