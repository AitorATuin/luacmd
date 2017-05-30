local Params = require('command.params')

describe('#params specs', function ()
  local args0, args1, args2, args3, p0, p1, p2, p3
  local match = require 'luassert.match'
  before_each(function()
  args0 = {
    '-v ${file1}_{file1}_${file2}',
    '-z ${file2}',
    '-k ${file2}'
  }
  args1 = {
    '-v ${file1}',
    '-o ${file2}',
    '-opts ${opts}',
    '-l ${ugly.var.name}'
  }
  args2 = {
    '-v ${some_var1}',
    '-o ${file2}',
    '-opts ${opts}:${opts2}'
  }
  args3 = {
    '-l ${file1}',
    '-opts ${opts2}:${opts}'
  }
  p0 = Params.new(args0)
  p1 = Params.new(args1)
  p2 = Params.new(args2)
  p3 = Params.new(args3)
  end)
  it('can be created', function ()
    assert.is_not_nil(p1)
  end)
  it('can only be created from tables', function ()
    local p4, err4 = Params.new('from a string')
    local p5, err5 = Params.new(1000)
    local p6, err6 = Params.new(nil)
    local p7, err7 = Params.new(true)
    match.is_all_of(match.is_nil(p4), match.is_nil(p5), match.is_nil(p6), 
                    match.is_nil(p7))
    match.is_all_of(match.are.equals(type(err4), 'string'),
                    match.are.equals(type(err5), 'string'),
                    match.are.equals(type(err6), 'string'),
                    match.are.equals(type(err7), 'string'))
  end)
  it('can be added', function ()
    local p4 = p1:add(p2)
    assert.is_not_nil(p4)
    assert.are_not.equal(p1, p4)
    assert.are_not.equal(p2, p4)
    -- use alias
    local p5 = p1 + p2
    assert.is_not_nil(p5)
    assert.are_not.equal(p4, p5)
    assert.are_not.equal(p1, p5)
    assert.are_not.equal(p2, p5)
    -- Both should contain the same data
    assert.are.same(p4, p5)
  end)
  it('can query for variables inside params', function ()
    pending('Test not implemented')
    assert.are.same(p1('file1'), {{1, 1}}) 
    assert.are.same(p1('file2'), {{1, 2}}) 
    assert.are.same(p1('file3'), {}) 
    assert.are.same(p0('file1'), {{1, 1}, {1, 1}})
    assert.are.same(p0('file2'), {{1, 1,}, {1, 2}, {1, 3}})
  end)
  it('can index variables in params', function ()
    pending('Test not implemented')
    assert.is_nil(p1.file1)
    assert.is_nil(p1.file2)
    assert.is_nil(p1['ugly.var.name'])
    p1:resolve('file1', 'some_file') 
    local p4 = p1 ^ {
      file2 = 'some_other_file', 
      ['ugly.var.name'] = 'ugly.var.value'
    } -- using aliases
    assert.are.equals(p4.file1, 'some_file')
    assert.are.equals(p4.file2, 'some_other_file')
    assert.are.equals(p4['ugy.var.name'], 'ugly.var.value')
  end)
  it('can index variables in params when combined', function ()
    pending('Test not implemented')
    local p4 = p1 + p2 + p3
    local p5 = p4 ^ {
      file1 = 'some_file',
      file2 = 'some_other_file',
      opts = 'abcd',
      opts2 = 'efgh'
    }
    assert.are.equals(p5.file1, 'some_file')
    assert.are.equals(p5.file2, 'some_other_file')
    assert.are.equals(p5.opts, 'abcd')
    assert.are.equals(p5.opts2, 'efgh')
  end)
  it('new param is created when resolving values', function ()
    pending('Test not implemented')
    local p4 = p1 ^ {
      file1 = 'some_file'
    }
    assert.are.not_equals(p4, p1)
  end)
  it('can check if all the variables in params are resolved and resolves variables', function ()
    pending('Test not implemented')
    assert.are.equals(p1:completed(), false)
    assert.are.equals(p2:completed(), false)
    assert.are.equals(p3:completed(), false)
    local args_solved1 =  {
      file2 = 'some_other_file',
      opts = 'abcd',
      ['ugly.var.name'] = 'ugly.var.value'
    }
    local p4 = p1 ^ args_solved1
    assert.are.equals(p4:completed(), false)
    args_solved1.file1 = 'some_file'
    p4 = p1 ^ args_solved1
    assert.are.equals(p4:completed(), true)
    local p5 = p2 ^ {
      some_var = 'some_var_name',
      file2 = 'some_other_file',
      opts = 'abcd',
      opts2 = 'efgh'
    }
    assert.are.equals(p2:completed(), true)
  end)
  it('can check if all the variables in params are resolved and resolves when combined', function ()
    pending('Test not implemented')
    local p4 = (p1 + p2 + p3) ^ {
      file1 = 'some_file',
      file2 = 'some_other_file',
      some_var = 'some_var_name',
      opts = 'abcd',
      opts2 = 'efgh',
      ['ugly.var.name'] = 'ugy.var.value'
    }
    assert.are.equals(p4:completed(), true)
  end)
end)

