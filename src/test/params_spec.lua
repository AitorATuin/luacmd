local params = require('params')

describe('#params specs', function ()
  local args1, args2, args3, p1, p2, p3
  before_each(function()
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
  p1 = params(args1)
  p2 = params(args2)
  p3 = params(args3)
  end)
  it('can be created', function ()
    pending('Test not implemented') 
    assert.is_not_nil(p1)
  end)
  it('can be added', function ()
    pending('Test not implemented')
    local p4 = p1:add(p2)
    assert.is_not_nil(p4)
    assert.are.not.equals(p1, p4)
    assert.are.not.equals(p2, p4)
    -- use alias
    local p5 = p1 + p2
    assert.is_not_nil(p5)
    assert.are.not.equals(p4, p5)
    assert.are.not.equals(p1, p5)
    assert.are.not.equals(p2, p5)
  end)
  it('can index variables in params', function ()
    pending('Test not implemented')    
    assert.is_nil(p1.file1)
    assert.is_nil(p1.file2)
    assert.is_nil(p1['ugy.var.name'])
    p1:resolve('file1', 'some_file') 
    p1 ^ {
      file2 = 'some_other_file', 
      ['ugly.var.name'] = 'ugly.var.value'
    } -- using aliases
    assert.are.equals(p1.file1, 'some_file')
    assert.are.equals(p1.file2, 'some_other_file')
    assert.are.equals(p1['ugy.var.name'], 'ugly.var.value')
  end)
  it('can index variables in params when combined', function ()
    pending('Test not implemented')
    local p4 = p1 + p2 + p3
    p4 ^ {
      file1 = 'some_file',
      file2 = 'some_other_file',
      opts = 'abcd',
      opts2 = 'efgh'
    }
    assert.are.equals(p4.file1, 'some_file')
    assert.are.equals(p4.file2, 'some_other_file')
    assert.are.equals(p4.opts, 'abcd')
    assert.are.equals(p4.opts2, 'efgh')
  end)
  it('new param is created when resolving values', function ()
    local p4 = p1 ^^ {
      file1 = 'some_file'
    }
    assert.are.not.equals(p4, p1)
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

