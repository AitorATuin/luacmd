------------
-- params
-- params class in commands
-- classmod: params
-- author: AitorATuin
-- license: MIT

local util = require 'command.util'
local sprintf = string.format

-- class table
local Params = {}

Params.__index = Params

local function get_paramst_mt(paramst)
  local function add_index(t, field, idx)
    local tt = (t[field] or {})
    tt[#tt+1] = idx
    return tt
  end
  -- argt[1] has always the command, ignore it
  local p = {}
  for i=2, #paramst do
    for capture in string.gmatch(paramst[i], "${([%w-_]+)}") do
      p[capture] = add_index(p, capture, i)
    end
  end
  return {
    __index = function(_, v)
      return p[v]
    end,
    __call = function(_)
      return p
    end
  }
end

Params.new = function(paramst)
  if type(paramst) ~= 'table' then
    return nil, sprintf('Unable to create Params from \'%s\'', type(paramst))
  end
  return setmetatable({
    setmetatable(paramst, get_paramst_mt(paramst))
  }, Params)
end

Params.add = function(self, other)
  local t = util.copy_table(self)
  for _, v in pairs(other) do
    t[#t+1] = v
  end
  return setmetatable(t, Params)
end

Params.resolve = function(_, _)
  return nil
end

Params.__pow = function(this, values)
  return this:resolve(values)
end

Params.__add = function(this, other)
  if not util.eq_mt(this, other) then
    return nil, 'Only params can be added, second argument is not Params'
  end
  return this:add(other)
end

return Params
