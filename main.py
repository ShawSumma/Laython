import ast
def indent(string):
    ret = ''
    for i in string.split('\n'):
        ret += '  '+i+'\n'
    ret = ret[:-1]
    return ret

def endlist(string):
    if string[-2:] == ', ':
        return string[:-2]
    return string

def string_safe(ret):
    replaces = [
        ['\n', '\\n'],
        ['\'', '\\\''],
        ['\"', '\\\"'],
        ['\t', '\\t'],
        ['\a', '\\a'],
    ]
    for i in replaces:
        ret = ret.replace(i[0], i[1])
    return ret

def smart_assign(code):
    strout = ', '.join('')
    ret = '%s' % main(code.value)
    return ret

def tuple_assign(tup):
    ret = []
    for t in tup.elts:
        if isinstance(t, ast.Tuple):
            ret += tuple_assign(t)
        else:
            ret.append(t)
    return ret

def flat_assign(code):
    ret = []
    for t in code.targets:
        if isinstance(t, ast.Tuple):
            ret += tuple_assign(t)
        else:
            ret.append(t)
    return ret

def main(code):
    if isinstance(code, ast.Module):
        ret = ''
        for i in code.body:
            ret += main(i)+'\n'
        return ret
    if isinstance(code, ast.Assign):
        # ret += main(code.targets[0])
        # ret += '  '
        # ret += main(code.value)
        return smart_assign(code)
    if isinstance(code, ast.Import):
        ret = ''
        for name in code.names:
            asn = name.asname if name.asname != None else name.name
            ret += '%s = require "%s"\n' % (asn, name.name)
            # ret += '%s = py_import(%s, "%s")' % (asn, name.name, asn)
        return ret
    if isinstance(code, ast.Slice):
        ret = ''
        step = 'int({py_int(1)})' if code.step == None else main(code.step)
        fr = 'int({py_int(0)})' if code.lower == None else main(code.lower)
        to = 'nil' if code.upper == None else main(code.upper)
        ret += '{["py_type"]="raw_slice", ["from"]=%s, ["to"]=%s, ["step"]=%s}' % (fr, to, step)
        return ret
    if isinstance(code, ast.FunctionDef):
        ret = ''
        ret += 'function %s(args, kwargs)\n' % code.name
        ind = ''
        ind += main(code.args)
        for i in code.body:
            ind += '\n%s' % main(i)
        ret += indent(ind[1:])
        ret += '\nend'
        return ret
    if isinstance(code, ast.arguments):
        ret = ''
        count = 1
        inds = {}
        for i in code.args:
            ret += '\n%s = args[%s]' % (main(i), count)
            inds[main(i)] = count
            count += 1
        for pl, i in enumerate(code.defaults):
            # print(main(i))
            name = main(code.args[count-len(code.defaults)+pl-1])
            ret += '\n%s = kwargs[%s] or %s or %s' % (name, name, name, main(i))
        return ret
        # return ret
    if isinstance(code, ast.arg):
        return code.arg
    if isinstance(code, ast.AugAssign):
        ret = ''
        name = main(code.target)
        ret += '%s = ' % code.target.id
        o = code.op
        if isinstance(o, ast.Add):
            op = 'add'
        ret += 'operator.%s' % op
        ret += '({%s, %s})' % (name, main(code.value))
        return ret
    if isinstance(code, ast.Subscript):
        ret = ''
        ret += 'py_subscript({%s, %s})' % (main(code.value), main(code.slice))
        return ret
    if isinstance(code, ast.Index):
        ret = ''
        ret += '%s' % main(code.value)
        return ret
    if isinstance(code, ast.ImportFrom):
        print('import from does not work yet')
        exit()
    if isinstance(code, ast.Name):
        return "py_load(%s, \"%s\")" % (str(code.id), str(code.id))
    if isinstance(code, ast.Num):
        return 'int({py_int('+str(code.n)+')})'
    if isinstance(code, ast.Str):
        return 'str({py_str("'+string_safe(code.s)+'")})'
    if isinstance(code, ast.Tuple):
        ret = 'list({py_list({'
        for i in code.elts:
            ret += main(i)
            ret += ', '
        ret = endlist(ret)
        ret += '})})'
        return ret
    if isinstance(code, ast.Compare):
        ret = ''
        ret += 'operator.all({'
        orig = main(code.left)
        for i in code.comparators:
            o = code.ops[0]
            if isinstance(o, ast.Eq):
                op = 'eq'
            elif isinstance(o, ast.Lt):
                op = 'lt'
            elif isinstance(o, ast.Gt):
                op = 'gt'
            elif isinstance(o, ast.LtE):
                op = 'le'
            elif isinstance(o, ast.GtE):
                op = 'ge'
            elif isinstance(o, ast.NotEq):
                op = 'ne'
            mn = main(i)
            ret += 'operator.%s({%s, %s}), ' % (op, orig, mn)
            orig = mn
        ret = endlist(ret)
        ret += '})'
        return ret
    if isinstance(code, ast.Expr):
        ret = ''
        ret += main(code.value)
        return ret
    if isinstance(code, ast.Call):
        ret = ''
        ret += main(code.func)
        ret += '({'
        for i in code.args:
            ret += main(i)
            ret += ', '
        ret = endlist(ret)
        ret += '},{'
        for i in code.keywords:
            ret += main(i)
            ret += ', '
        ret = endlist(ret)
        ret += '})'
        return ret
    if isinstance(code, ast.keyword):
        ret = ''
        ret += '["%s"] = %s' % (code.arg, main(code.value))
        return ret
    if isinstance(code, ast.If):
        test = main(code.test)
        then = [main(i)+'\n' for i in code.body]
        orelse = [main(i)+'\n' for i in code.orelse]
        if len(then) > 0:
            then[-1] = then[-1][:-1]
        if len(orelse) > 0:
            orelse[-1] = orelse[-1][:-1]
        then = indent(''.join(then))
        orelse = indent(''.join(orelse))
        test = 'py_to_bool(%s)[\'py_data\']' % test
        ret = 'if %s then\n%s\nelse\n%s\nend' % (test, then, orelse)
        return ret
    if isinstance(code, ast.List):
        ret = 'list({py_list({'
        for i in code.elts:
            ret += main(i)
            ret += ', '
        ret = endlist(ret)
        ret += '})})'
        return ret
    if isinstance(code, ast.NameConstant):
        val = code.value
        if val == False:
            return 'bool({py_bool(false)})'
        if val == False:
            return 'bool({py_bool(true)})'
        if val == None:
            return 'NoneType()'
    if isinstance(code, ast.While):
        then = [main(i)+'\n' for i in code.body]
        test = main(code.test)
        if len(then) > 0:
            then[-1] = then[-1][:-1]
        then = indent(''.join(then))
        test = 'py_to_bool(%s)[\'py_data\']' % test
        ret = 'while %s do\n%s\nend' % (test, then)
        return ret
    if isinstance(code, ast.UnaryOp):
        opt = code.op
        if isinstance(opt, ast.USub):
            op = 'usub'
        operand = main(code.operand)
        ret = 'operator.%s({%s})' % (op, operand)
        return ret
    if isinstance(code, ast.BinOp):
        opt = code.op
        pre = main(code.left)
        post = main(code.right)
        if isinstance(opt, ast.Add):
            op = 'add'
        elif isinstance(opt, ast.Sub):
            op = 'sub'
        elif isinstance(opt, ast.Div):
            op = 'div'
        elif isinstance(opt, ast.Pow):
            op = 'pow'
        elif isinstance(opt, ast.Mod):
            op = 'mod'
        elif isinstance(opt, ast.Mult):
            op = 'mul'
        ret = 'operator.%s({%s, %s})' % (op, pre, post)
        return ret
    if isinstance(code, ast.Attribute):
        return 'getattr({%s, "%s"})' % (main(code.value), string_safe(code.attr))
    print(code)
    print(vars(code))
    raise err()
    exit()
class err(Exception):
    pass
code = open('input.py').read()
code = ast.parse(code)
open('out.lua', 'w').write('require "python"\n'+main(code))
