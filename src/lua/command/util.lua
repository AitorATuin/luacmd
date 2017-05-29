------------
-- luacmd.util
-- Some util functions
-- module: luacmd.util
-- author: AitorATuin
-- license: MIT

local util = {}

util.copy_table = function(orig_t)
  local new_t = {}
  for i, v in pairs(orig_t) do
    if type(v) == 'table' then
      local t_cp = util.copy_table(v)
      local mt = getmetatable(v)
      if mt then
        new_t[i] = setmetatable(t_cp, util.copy_table(mt))
      else
        new_t[i] = t_cp
      end
    else
      new_t[i] = v
    end
  end
  return new_t
end

-- Compares two object metatables
util.eq_mt = function(obj1, obj2)
  return getmetatable(obj1) == getmetatable(obj2)
end


return util
