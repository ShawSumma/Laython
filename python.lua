loadstring = loadstring or load
lua = {}
lua_vars = _G
for k,v in pairs(lua_vars) do
  lua[k] = v
end
k = nil
v = nil
lua_vars = nil

function str(args, kwargs)
  local self = {
      ['py_type'] = 'str',
      ['py_data'] = tostring(args[1]['py_data']),
  }
  self['__str__'] = function()
    return self
  end
  self['__repr__'] = function()
    return str({py_str('<python str object>')})
  end
  return self
end

function NoneType()
  local self = {
    ['py_type'] = 'None',
    ['py_data'] = 'None'
  }
  self['__str__'] = function()
    return 'None'
  end
  self['__repr__'] = function()
    return str({py_str('<python NoneType object>')})
  end
  return self
end

function py_str(py_string)
  local self = {
      ['py_data'] = py_string
  }
  self['__str__'] = function()
    return {['py_data']=py_string}
  end
  return self
end

function int(args, kwargs)
  local arg1 = args[1]
  local self = {
      ['py_type'] = 'int',
      ['py_data'] = tonumber(arg1['py_data'])
  }
  self['__str__'] = function()
    local ret = str({py_str(lua.tostring(self['py_data']))})
    return ret
  end
  self['__repr__'] = function()
    return str({py_str('<python int object>')})
  end
  return self
end

function py_int(num)
  return {
      ['py_data'] = tonumber(num)
  }
end

function len(args, kwa)
  return int({py_int(py_len(args[1]['py_data']))})
end

function py_len(obj)
  local count = 0
  for k,v in pairs(obj) do
    count = count + 1
  end
  return count
end

function pyobj(obj)
  local ret
  if lua.type(obj) == 'table' then
    ret = list({py_list(obj)})
  elseif lua.type(obj) == 'number' then
    ret = int({py_int(obj)})
  elseif lua.type(obj) == 'string' then
    ret = str({py_str(obj)})
  elseif lua.type(obj) == 'function' then
    ret = obj
  else
  end
  return py_load(ret, '_pyobj')
end

function list(args, kwargs)
  local self = {
    ['py_type'] = 'list',
    ['py_data'] = {}
  }
  local count = 1
  for k,v in pairs(args[1]['py_data']) do
    self['py_data'][count] = v
    count = count + 1
  end
  self['__str__'] = function(args, kwargs)
    local ret = '['
    for k,v in pairs(self['py_data']) do
      ret = ret .. v.__str__()['py_data']
      if k ~= len({self}) then
        ret = ret .. ', '
      end
    end
    ret = ret .. ']'
    ret = str({py_str(ret)})
    return ret
  end
  self['__repr__'] = function(args, kwargs)
    return str({py_str('<python list object>')})
  end
  self['append'] = function(args, kwargs)
    self['py_data'][count] = args[1]
    count = count + 1
  end
  return self
end

function bool(args, kwargs)
  local arg1 = args[1]
  self = {
      ['py_type'] = 'bool',
      ['py_data'] = py_to_bool(arg1['py_data'])
  }
  self['__str__'] = function()
    if self['py_data'] then
      local ret =  str({py_str('True')})
    else
      local ret =  str({py_str('False')})
    end
    return ret
  end
  self['__repr__'] = function()
    return str({py_str('<python bool object>')})
  end
  return self
end

function py_to_bool(val)
  local ret = val
  if val == nil then
    ret = false
  elseif val == 0 then
    ret = false
  elseif val == '' then
    ret = false
  elseif lua.type(val) == 'table' then
    if val['py_type'] == nil then
      ret = py_bool(py_len(val['py_data']))
    else
      if val['__nonzero__'] ~= nil then
        ret = val['__nonzero__']() ~= false
      elseif val['__bool__'] ~= nil then
        ret = val['__bool__']() ~= false
      else
        ret = py_bool(val['py_data'])
      end
    end
  end
  return ret
end

function py_bool(num)
  return {
      ['py_data'] = py_to_bool(num)
  }
end

function operator()
  local self = {}
  local ops = {
    ['lt'] = '<',
    ['gt'] = '>',
    ['le'] = '<=',
    ['ge'] = '>=',
    ['eq'] = '==',
    ['ne'] = '~=',
  }
  self['add'] = function(args)
    if args[1]['py_type'] == 'int' then
      local ret = args[1]['py_data'] + args[2]['py_data']
      ret = int({py_int(ret)})
    elseif args[1]['py_type'] == 'str' then
      local ret = args[1]['py_data'] .. args[2]['py_data']
      ret = str({py_str(ret)})
    else
      local ret = {}
      local cc = 1
      for k,v in lua.pairs(args[1]['py_data']) do
        ret[cc] = v
        local cc = cc + 1
      end
      for k,v in lua.pairs(args[2]['py_data']) do
        ret[cc] = v
        local cc = cc + 1
      end
      local ret = list({py_list(ret)})
    end
    return ret
  end
  self['mul'] = function(args)
    local ret = {}
    if args[1]['py_type'] == 'int' then
      ret = args[1]['py_data'] * args[2]['py_data']
      ret = int({py_int(ret)})
    elseif args[1]['py_type'] == 'str' then
      ret = ''
      for i=1, args[2]['py_data'] do
        ret = ret..args[1]['py_data']
      end
      ret = str({py_str(ret)})
    else
      ret = {}
      local cc = 1
      for i=1, args[2]['py_data'] do
        for k,v in lua.pairs(args[1]['py_data']) do
          ret[cc] = v
          cc = cc + 1
        end
      end
      ret = list({py_list(ret)})
    end
    return ret
  end
  self['usub'] = function(args)
    local ret = 0 - args[1]['py_data']
    local ret = int({py_int(ret)})
    return ret
  end
  self['sub'] = function(args)
    local ret = args[1]['py_data'] - args[2]['py_data']
    local ret = int({py_int(ret)})
    return ret
  end
  self['mod'] = function(args)
    local ret = args[1]['py_data'] % args[2]['py_data']
    local ret = int({py_int(ret)})
    return ret
  end
  self['div'] = function(args)
    local ret = args[1]['py_data'] / args[2]['py_data']
    local ret = int({py_int(ret)})
    return ret
  end
  self['all'] = function(args)
    local ret = true
    for k,v in pairs(args) do
      local v = py_to_bool(v['py_data'])
      if ret then
        local ret = v
      end
    end
    return bool({py_bool(ret)})
  end
  for k, v in pairs(ops) do
    local uname = '__'..k..'__'
    self[k] = function(args)
      local pre = args[1]
      local post = args[2]
      if pre[uname] == nil then
        pre = pre['py_data']
        post = post['py_data']
        local ret = false
        if v == '==' then
          ret = pre == post
        elseif v == '~=' then
          ret = pre ~= post
        elseif v == '<=' then
          ret = pre <= post
        elseif v == '>=' then
          ret = pre >= post
        elseif v == '<' then
          ret = pre < post
        elseif v == '>' then
          ret = pre > post
        end
      else
        local ret = pre[uname](post)
      end
      return bool({py_bool(ret)})
    end
  end
  return self
end
operator = operator()

function py_list(lis)
  return {
    ['py_type'] = 'py_list',
    ['py_data'] = lis
  }
end

function print(args, kwargs)
  local kwargs = kwargs or {}
  kwargs['sep'] = kwargs['sep'] or str({py_str(' ')})
  kwargs['end'] = kwargs['end'] or str({py_str('\n')})
  -- local nosep = py_len(args)
  for k,v in lua.pairs(args) do
    lua.io.stdout:write(v.__str__()['py_data'])
  end
  lua.print()
end

function getattr(args, kwargs)
  local ret = py_load(args[1][args[2]], '_getattr')
  if ret == nil and lua.type(args[1]['py_data']) == 'table' then
    ret = py_load(args[1]['py_data'][args[2]], '_getattr')
  end
  return
end

function repr(args, kwargs)
  return args[1].__repr__()
end

function type(args)
  return str({py_str(args[1]['py_type'])})
end

function dir(args)
  ret = {}
  for k,v in pairs(args[1]) do
    ret[#ret+1] = k
  end
  ret = list({py_list(ret)})
  return ret
end

function py_import(file, asname)
  local self = {}
  self['__repr__'] = function()
    return str({py_str('<Module object "'..asname..'">')})
  end
  self['__str__'] = self['__repr__']
  self['py_data'] = file
  self['py_type'] = 'Module'
  return py_load(self, asname)
end

function py_subscript(args)
  local ret = {}
  if args[2]['py_type'] ~= 'raw_slice' then
    if args[1]['py_type'] == 'str' then
      local frt = args[2]['py_data']+1
      ret = str({py_str(args[1]['py_data']:sub(frt, frt))})
    else
      ret = args[1]['py_data'][args[2]['py_data']+1]
    end
  else
    if args[2]['to'] == nil then
      args[2]['to'] = int({py_int(0)})
    end
    while args[2]['from']['py_data'] < args[2]['to']['py_data'] do
      local cpl = args[2]['from']['py_data']
      if cpl < 0 then
        cpl = #args[1]['py_data']+cpl
      end
      if args[1]['py_type'] == 'str' then
        ret[#ret+1] = args[1]['py_data']:sub(cpl+1, cpl+1)
      else
        ret[#ret+1] = args[1]['py_data'][cpl+1]
      end
      if ret[#ret] == nil then
        lua.print('index out of range')
      end
      args[2]['from']['py_data'] = args[2]['from']['py_data'] + args[2]['step']['py_data']
    end
    if args[1]['py_type'] == 'str' then
      local strout = ''
      for k,v in pairs(ret) do
        strout = strout .. v
      end
      ret = str({py_str(strout)})
    else
      ret = list({py_list(ret)})
    end
  end
  return ret
end

function py_call(fn, args, kwargs)
  local ret = false
  if type(fn) == 'function' then
    ret = fn(unpack(args))
  else
    ret = fn['py_data'](args, kwargs)
  end
end

function py_load(name, named)
  if name == nil then
    named = named or 'unk'
    lua.print('the name loaded was nil know as "' .. tostring(named) .. '"')
    os.exit()
  elseif lua.type(name) == 'function' then
  elseif lua.type(name) == 'table' then
    if name['py_type'] == nil then
      name = list({py_list(name)})
    end
  end
  return name
end
