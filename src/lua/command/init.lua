------------
-- command.init
-- module to run shell commands in a nice way
-- module: command
-- author: AitorATuin
-- license: MIT

local Params   = require 'command.params'
local result   = require 'command.result'
local util     = require 'command.util'
local posix    = require 'posix'
local unistd   = require 'posix.unistd'
local sys_wait = require 'posix.sys.wait'
local sys_stat = require 'posix.sys.stat'
local bit32    = bit32 or require 'bit32'
local sprintf  = string.format

-- resolves path for program `binary` using $PATH
-- treturn: ?string|nil path for an executable program `binary`
local function find_binary_path(binary)
  local function can_be_executed(st_mode)
    return bit32.band(st_mode, sys_stat.S_IXUSR) == sys_stat.S_IXUSR and
      bit32.band(st_mode, sys_stat.S_IFDIR) ~= sys_stat.S_IFDIR
  end
  local paths = os.getenv('PATH')
  for path in paths:gmatch('[^:]+') do
    local candidate_path = path .. '/' .. binary
    local lstat = sys_stat.lstat(candidate_path)
    if lstat and can_be_executed(lstat.st_mode) then
      return candidate_path
    end
  end
  return nil, sprintf('command %s not found', binary)
end

local function prepare_params(argt)
  local function add_index(t, field, idx)
    local tt = (t[field] or {})
    tt[#tt+1] = idx
    return tt
  end
  -- argt[1] has always the command, ignore it
  local p = {}
  for i=2, #argt do
    for capture in string.gmatch(argt[i], "${([%w-_]+)}") do
      p[capture] = add_index(p, capture, i)
    end
  end
  return setmetatable(argt, {
    __index = function(_, v)
      return p[v]
    end,
    __call = function(_)
      return p
    end
  })
end

--- funtion that given a string creates a table with path and arguments ready
-- to be used by fork_command
-- treturn: ?table table with the path for command and the arguments for command
local function prepare_command(command)
  local cmdt = {}
  local err
  if type(command) ~= 'function' and type(command) ~= 'string' then
    return nil, sprintf('Commands can not be created from a %s', type(command))
  end
  for item in command:gmatch('[^%s]+') do
    cmdt[#cmdt + 1] = item
  end
  if not cmdt[1] then
    return nil, 'command not specified!'
  end
  cmdt[1], err = find_binary_path(cmdt[1])
  if not cmdt[1] then
    return nil, err
  end
  return prepare_params(cmdt)
end

--- reads all available data for fd
-- treturn: string string containing the data in fd
local function read_data(fd)
  local buffer = 2048
  local function rec_read_data(_fd, data, count)
    if count < buffer then
      return data
    else
      local _data = unistd.read(_fd, buffer)
      return rec_read_data(_fd, data .. _data, #_data)
    end
  end
  return rec_read_data(fd, "", buffer)
end

--- closes a bunch of fds
local function close_fds(...)
  local fds = {...}
  for _, fd in ipairs(fds) do
    unistd.close(fd)
  end
end

--- forks the process creating a new child and spawn a new command on it
-- In the child process STDIN, STDOUT and STDERR are duplicated
-- table: argt argument list using posix.unistd.execp format
-- stdin: stdin STDIN fd to use in child process
-- stdout: stdout STDOUT fd to use in child process
-- stderr: stderr STDERR fd to use in child process
-- treturn: ?int|nil child process's pid or nil
-- treturn: ?string error string in case of error
local function fork_command(cmd, stdin, stdout, stderr)
  local pid
  local argt, errmsg = prepare_command(cmd)
  if not argt then
    return nil, errmsg
  end
  pid, errmsg = unistd.fork()
  if not pid then return nil, errmsg end
  if pid == 0 then
    -- child process here, spawn a new command!
    unistd.dup2(stdout, unistd.STDOUT_FILENO)
    unistd.dup2(stderr, unistd.STDERR_FILENO)
    if stdin then
      unistd.dup2(stdin, unistd.STDIN_FILENO)
    end
    local exit_code, _ = posix.spawn(argt)
    os.exit(exit_code)
  else
    return pid, errmsg
  end
end

------------
-- command
-- command class wrapping shell commands
-- classmod: command
-- author: AitorATuin
-- license: GPL3

-- class table
local Command = {}

local function wrap_command(cmd)
  local argt, errmsg = prepare_command(cmd)
  if not argt then
    return nil, errmsg
  end
  local command_wrapper = function(current_params)
    local child_pid
    local stdout_r, stdout_w = posix.pipe()
    local stderr_r, stderr_w = posix.pipe()
    local stdin_r, stdin_w = nil
    if (current_params or {}).stdin then
      stdin_r, stdin_w = posix.pipe()
      unistd.write(stdin_w, current_params.stdin)
      close_fds(stdin_w)
    end
    child_pid, errmsg = fork_command(cmd, stdin_r, stdout_w, stderr_w)
    if not child_pid then
      -- Error forking child!
      close_fds(stderr_r, stderr_w, stdout_r, stdout_w, stdin_r, stdin_w)
      return result('', errmsg, 127)
    elseif child_pid ~= 0 then
      -- Child is running!
      close_fds(stdout_w, stderr_w, stdin_r)
      local _, _, exit_code = sys_wait.wait(child_pid)
      local output_data = read_data(stdout_r)
      local err_data = read_data(stderr_r)
      close_fds(stdout_r, stderr_r)
      return result(output_data, err_data, exit_code)
    end
  end
  return command_wrapper, Params.new(argt)
end

function Command.run(self, params)
    return self._runner(params)
end

function Command.pipe(self, other)
  if not util.eq_mt(self, other) then
    return nil, 'Only commands can be piped, second argument is not an Command'
  end
  local command_fn = function (params)
    local res = self:run()
    if res.exit_code == 0 then
      params = params or {}
      params.stdin = res.stdout
      return other:run(params)
    else
      return result.stdout, result.stderr, result.exit_code
    end
  end

  local params = self._params:add(other._params)
  return Command.new(command_fn, params)
end

function Command.number_of_commands(self)
  return #self._params
end

function Command.parameters(self)
  local params = {}
  local _params = {}
  for _, command_params in ipairs(self._params) do
    for p in pairs(command_params()) do
      if not _params[p] then
        _params[p] = true
        params[#params+1] = p
      end
    end
  end
  return params
end

function Command.tostring(self)
  local function targs_to_string(targs, default_value)
    local cmd = string.match(targs[1] or "", '.+/([^/]+)$')
    for i=2, #targs do
      cmd = sprintf("%s %s", cmd, targs[i])
    end
    return cmd or default_value
  end

  local cmd
  if not self._params or not self._params[1] then
    cmd = sprintf('%s', tostring(self._runner))
  else
    -- it must exist at least one command!
    cmd = targs_to_string(self._params[1], 'fun')
    for i=2, #self._params do
      cmd = sprintf('%s | %s', cmd, targs_to_string(self._params[i], 'fun'))
    end
  end
  return cmd
end

--- Creates a new Command
-- The argument `command` can be a string representing the command to execute
-- (with optional arguments) like "ls -la" or a function which must return:
-- (string, string, int) [(stdout, stderr, exit_code)
--
-- string|function: command command or function to execute
-- treturn: Command
function Command.new(command, params)
  local command_fn
  if type(command) == 'function' then
    -- If command is a function we can pass optionaly a list of params
    command_fn = command
  else
    -- Function to run the command and parameters to resolve before
    -- running th command
    command_fn, params = wrap_command(command)
  end
  if not command_fn then
    -- params contains error string in case of error
    return nil, params
  end
  local t = {
    _runner = command_fn,
    _params = params or Params.new({})
  }
  return setmetatable(t, Command)
end

Command.__index = function(_, f)
  if f == 'new' then return nil end
  return Command[f]
end
Command.__call = Command.run
--[[
  bitwise operators can not return error strings in case of error, they just
  return nil.
  TODO: Should this be wrapper calling error in case of error?
--]]
if _VERSION == 'Lua 5.3' then
  Command.__bor = Command.pipe
else
  Command.__div = Command.pipe
end
Command.__tostring = Command.tostring

return {
  command = Command.new
}
