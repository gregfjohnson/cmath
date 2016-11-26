-----------------------------------------------------------------------------
-- Copyright (c) Greg Johnson, Gnu Public Licence v. 2.0.
-----------------------------------------------------------------------------
local luamath = math
local c3 = {}

c3.eps = 1e-12

local values = { }
setmetatable(values, { __mode = 'k' })

local is_complex = function(c)
    local fn = function() return values[c] ~= nil end

    local okPcall, result = pcall(fn)

    return okPcall and result
end

local function ctype(c)
    if is_complex(c) then
        return 'complex'
    else
        return luamath.type(c)
    end
end

local re = function(c)
    if ctype(c) == 'complex' then
        return values[c].real
    else
        return c + 0.
    end
end

local im = function(c)
    if ctype(c) == 'complex' then
        return values[c].imag

    elseif luamath.type(c) ~= nil then
        return 0.

    else
        assert(false, "bad argument #1 to 'im' (number expected)")
    end
end

local apply = function(cfn, rfn, name)
    if name ~= nil then
        name = string.format("#1 to '%s' ", tostring(name))
    else
        name = ''
    end

    return function(c)
        assert(ctype(c) ~= nil, 
               string.format("bad argument %s(number expected)", name))

        if ctype(c) == 'complex' then
            return cfn(c)

        else
            return rfn(c)
        end
    end
end

local apply2 = function(cfn, rfn, name)
    if name ~= nil then
        name = string.format("to '%s' ", tostring(name))
    else
        name = ''
    end

    return function(c1, c2)
        assert(ctype(c1) ~= nil, 
               string.format("bad argument #1 %s(number expected)", name))

        assert(ctype(c2) ~= nil, 
               string.format("bad argument #2 %s(number expected)", name))

        if ctype(c1) == 'complex' or ctype(c2) == 'complex' then
            return cfn(c1, c2)

        else
            return rfn(c1, c2)
        end
    end
end

local create = function(...)
    local args = {...}
    local a1 = args[1]
    local a2 = args[2]

    local real, imag

    if #args == 0 then
        real, imag = 0, 0

    elseif #args == 1 then
        if is_complex(a1) then
            real, imag = re(a1), im(a1)

        elseif type(a1) == 'number' then
            real, imag = a1, 0
        end

    elseif #args == 2 then
        if type(a1) == 'number' then real = a1 end
        if type(a2) == 'number' then imag = a2 end
    end

    assert(type(real) == 'number' and type(imag) == 'number',
           'invalid argument(s)')

    local newc = {}
    values[newc] = {real = real, imag = imag}

    setmetatable(newc, c3)

    return newc
end

local I = create(0, 1)

local to_complex = function(c)
    if not is_complex(c) then c = create(c) end

    return c
end

c3.__tostring = function(c)
    local real, addsign, imag = re(c), '+', im(c)

    if luamath.abs(real) < c3.eps then real = 0.0 end
    if luamath.abs(imag) < c3.eps then imag = 0.0 end

    if imag < 0 then addsign, imag = '-', -imag end

    if imag == 0.0 then
        return tostring(real + 0.0)

    elseif real == 0.0 then
        if addsign == '+' then addsign = '' end

        return string.format('%si * %s',
                   addsign,
                   tostring(imag+0.))
    else
        return string.format('%s %s i * %s',
                   tostring(real+0.),
                   addsign,
                   tostring(imag+0.))
    end
end
if TEST then
    test:check('i * 1.0', tostring(create(0,1)), 'tostring(i)')
    test:check('1.0', tostring(create(1,0)), 'tostring(1)')
    test:check('1.0 + i * 1.0', tostring(create(1,1)), 'tostring(1)')

    test:check('-i * 1.0', tostring(create(0,-1)), 'tostring(i)')
    test:check('-1.0', tostring(create(-1,0)), 'tostring(1)')
    test:check('-1.0 - i * 1.0', tostring(create(-1,-1)), 'tostring(1)')
end

c3.__len = function(v1, v2)
    assert(false, 'attempt to get length of a complex value')
end

c3.__add = function(v1, v2)
    v1, v2 = to_complex(v1), to_complex(v2)

    return create(re(v1) + re(v2), im(v1) + im(v2))
end

c3.__sub = function(v1, v2)
    v1, v2 = to_complex(v1), to_complex(v2)

    return create(re(v1) - re(v2), im(v1) - im(v2))
end

c3.__unm = function(v)
    v = to_complex(v)

    return create(-re(v), -im(v))
end

c3.__mul = function(v1, v2)
    v1, v2 = to_complex(v1), to_complex(v2)

    return create(re(v1) * re(v2) - im(v1) * im(v2),
                  re(v1) * im(v2) + im(v1) * re(v2))
end

c3.__eq = function(v1, v2, eps)
    eps = eps or c3.eps

    v1, v2 = to_complex(v1), to_complex(v2)

    return     luamath.abs(re(v1) - re(v2)) < eps
           and luamath.abs(im(v1) - im(v2)) < eps
end

c3.__div = function(v1, v2)
    v2 = to_complex(v2)

    local v2InverseDenom = re(v2) * re(v2) + im(v2) * im(v2)
    local v2Inverse      = create( re(v2) / v2InverseDenom,
                                  -im(v2) / v2InverseDenom)
    return v1 * v2Inverse
end

local abs = apply(
    function(c) return luamath.sqrt(re(c)*re(c) + im(c)*im(c)) end,
    luamath.abs, 'abs')

c3.__pow = function(c, cpow)
    c, cpow = to_complex(c), to_complex(cpow)

    local r     = abs(c)
    local theta = luamath.atan(im(c), re(c))

    local result = r ^ re(cpow)
    result = result * luamath.exp(-im(cpow)*theta)

    local angle = re(cpow)*theta + im(cpow)*luamath.log(r)
    result = result * create(luamath.cos(angle), luamath.sin(angle))

    return result
end

c3.__index = function(t, key)
    assert(false, "error:  " ..
           "attempt to index a complex number.")
end

c3.__newindex =
    function()
        assert(false, "error:  " ..
               "cannot create or change fields in a complex value")
    end

c3.__lt =
    function()
        assert(false, "error:  " ..
               "complex numbers are not totally ordered.")
    end

c3.__le =
    function()
        assert(false, "error:  " ..
               "complex numbers are not totally ordered.")
    end

c3.__mod =
    function()
        assert(false, "error:  " ..
               "modular arithmetic is not defined on complex numbers.")
    end

c3.__idiv =
    function()
        assert(false, "error:  " ..
               "integer division is not defined on complex numbers.")
    end

c3.__metatable = "There is no metatable."

c3.__pairs =
    function() assert(false,
        "bad argument #1 to 'pairs' (table expected, got complex value)")
    end

local angle = apply(
        function(c) return luamath.atan(im(c), re(c)) end,
        function() return 0. end,
        'angle')

local exp = apply(
        function(c) return luamath.exp(1) ^ c end,
        luamath.exp,
        'exp')

local sqrt = apply(
        function(c) return c ^ .5 end,
        function(r) if r < 0 then
                return create(r,0) ^ .5
            else
                return luamath.sqrt(r)
            end
        end,
        'exp')

local log = function(c)
    local theta = angle(c) % (2 * luamath.pi)
    return create(luamath.log(abs(c)), theta)
end

local log = apply(log, luamath.log, 'log')

local log10 = apply(
        function(c) return log(c) / luamath.log(10) end,
        luamath.log10,
        'exp')

local cosh = function (r)
    return (luamath.exp(r) + luamath.exp(-r)) / 2
end

local sinh = function (r)
    return (luamath.exp(r) - luamath.exp(-r)) / 2
end

local complexCos = function(c)
    return create(luamath.cos(re(c)) * cosh(im(c)), -luamath.sin(re(c)) * sinh(im(c)))
end

local complexSin = function(c)
    return create(luamath.sin(re(c)) * cosh(im(c)),  luamath.cos(re(c)) * sinh(im(c)))
end

local cos = apply(complexCos, luamath.cos, 'cos')
local sin = apply(complexSin, luamath.sin, 'sin')

local tan = apply(
    function(c) return complexSin(c) / complexCos(c) end,
    luamath.tan,
    'tan')

local complexAcos = function(c)
    return -I * log(c + I * sqrt(1 - c*c))
end

local complexAsin = function(c)
    return -I * log(I * c + sqrt(1 - c*c))
end

local complexAtan = function(num, den)
    den = den or create(1)

    if den == I * 0 then
        return create(0)
    else
        return I / 2 * log((I + x) / (I - x))
    end
end

local acos = apply(complexAcos, luamath.acos, 'acos')
local asin = apply(complexAsin, luamath.asin, 'asin')
local atan = apply(complexAtan, luamath.atan, 'atan')

cmath = {}

-- cmath operations derived from the math library can only be applied
-- to non-complex numbers by default.

for k,v in pairs(luamath) do
    if type(v) == 'function' then
        cmath[k] = apply(
            function () assert(false, 'invalid operation on complex value') end,
            v)
    else
        cmath[k] = v
    end
end

-- new things in cmath..
cmath.i       = create(0, 1)
cmath.angle   = angle
cmath.re      = re
cmath.im      = im

-- math library functions with extensions to work on complex numbers..
cmath.type    = ctype
cmath.abs     = abs
cmath.exp     = exp
cmath.sqrt    = sqrt
cmath.log     = log
cmath.log10   = log10
cmath.cos     = cos
cmath.sin     = sin
cmath.tan     = tan
cmath.acos    = acos
cmath.asin    = asin
cmath.atan    = atan

-------------------- Test code for cmath --------------------
-- to run:  ./test.lua -a cmath.lua
-------------------------------------------------------------
if TEST or TESTX then
    local cnew = function(r,i) return r + i * cmath.i end
    local re   = function(c) return cmath.re(c) end
    local im   = function(c) return cmath.im(c) end

    if TESTX then
        c = 1 + cmath.i
        test:check('1.0 + i * 1.0', tostring(c), 'tostring')
        test:check(1, re(c), 'real')
        test:check(1, im(c), 'imag')
    end

    if TESTX then
        c = 1 - cmath.i
        test:check('1.0 - i * 1.0', tostring(c), 'tostring')
    end

    if TESTX then
        c = cnew(1,1)
        test:check('complex', cmath.type(c), 'type error')
    end

    if TESTX then
        c = cnew()
        test:check('There is no metatable.', getmetatable(c),  "getmetatable")
    end

    if TESTX then
        c = cnew()
        local fn = function() setmetatable(c, {}) end
        local xx, oops = pcall(fn)
        test:check(false, xx, "can't setmetatable")
    end

    if TESTX then
        c = cnew(0)
        local fn = function() c.foo = 10 end
        local xx, oops = pcall(fn)
        test:check(false, xx, "can't create new indices in c")
    end

    if TESTX then
        c = cnew(2,3) + cnew(20, 30)
        test:check(cnew(22,33), c, 'add complexes')
        test:check(22, re(c), 'add complexes; real')
        test:check(33, im(c), 'add complexes; imag')
    end

    if TESTX then
        c = cnew(2,3) + 20
        test:check(cnew(22,3) , c, 'add number on the right')
        test:check(22, re(c),   'add number on the right')
        test:check( 3, im(c),   'add number on the right')
    end

    if TESTX then
        c = 30 + cnew(2,3)
        test:check(cnew(32, 3), c, 'add number on the left')
    end

    if TESTX then
        c = cnew(0,1) * cnew(0, 1)
        test:check(cnew(-1, 0) , c, 'mult complexes')
    end

    if TESTX then
        c = cnew(-1,0) / cnew(0, 1)
        test:check(cnew(0,1), c, 'mult complexes:  divide real part')
    end

    if TESTX then
        test:check(1, cmath.abs(cmath.i), 'abs')
        test:check(luamath.pi/2, cmath.angle(cmath.i), 'angle')
        test:check(cnew(luamath.exp(2)), cmath.exp(cnew(2)), 'exp')
        test:check(cnew(luamath.sqrt(2)), cmath.sqrt(cnew(2)), 'sqrt(2)')
        test:check(cmath.i, cmath.sqrt(-1), 'sqrt(-1)')
        test:check(cnew(2), cmath.log10(cnew(100)), 'log10')
        test:check(cnew(luamath.cos(.5)), cmath.cos(cnew(.5)), 'cos')
        test:check(cnew(luamath.sin(.5)), cmath.sin(cnew(.5)), 'sin')
        test:check(cnew(luamath.tan(.5)), cmath.tan(cnew(.5)), 'tan')
        test:check(cnew(luamath.acos(.5)), cmath.acos(cnew(.5)), 'acos')
        test:check(cnew(luamath.asin(.5)), cmath.asin(cnew(.5)), 'asin')
    end

    if TESTX then
        test:check(cnew(4),  cnew(2) ^ 2, 'exp 2^2')
        test:check(cnew(-4), cnew(0,2) * cnew(0,2), '2i * 2i')
        test:check(cnew(-4), cnew(0,2) ^ 2, 'exp 2i^2')

        test:check(cnew(-1), luamath.exp(1) ^ cnew(0,luamath.pi), 'exp')

        omega8 = cnew(0,1) ^ .5
        test:check(cnew(luamath.sqrt(2)/2, luamath.sqrt(2)/2), omega8, 'omega8')

        for i = 0,8 do
            local actual = omega8 ^ i
            local angle = i * 2 * luamath.pi / 8
            local expected = cnew(luamath.cos(angle), luamath.sin(angle))
            test:check(expected, actual, '8th roots of unity')
        end
    end
end

return cmath
