-----------------------------------------------------------------------------
-- Copyright (c) Greg Johnson, Gnu Public Licence v. 2.0.
-----------------------------------------------------------------------------
-- Version 0.1.0.
--[[
    Standard usage is:

    require 'cmath'

    This creates a new global name 'cmath', a table that is
    backward-compatible with the standard lua math library but adds
    complex arithmetic.
    
    It also adds ctype(), an update to type() that understands complex
    values, and the constants e, i, and pi.

    To avoid modifications to the global namespace:

    local ComplexMath= require 'cmath_anon' 
--]]

local cmath = {}

local luamath = math
local complex_mt = {}

local makeComplex

-- <key, value> pairs in the values table represent complex values.
-- the key is the object that represents an instance of
-- a complex value.
-- the key is an empty table whose only salient feature
-- is its (unique) address.  This empty table is a
-- handy place to attach the metatable that defines
-- complex arithmetic operations.
-- the value is a two-element table containing the
-- real and imaginary part of the complex value.
--
-- making "complex numbers" empty tables simplifies
-- the design goal of opacity:  you can't do anything
-- to the internals of a complex value, including
-- looking at it.
--
-- values is a key-weak table; complex values that
-- are inaccessible other than via a values table
-- entry are eligible for garbage collection.

local kmode = { __mode = 'k' }
local vmode = { __mode = 'v' }

local values = {}
setmetatable(values, kmode)

-- as with strings, we would like multiple instances of
-- the same complex number to have the same reference.
--
-- that permits, for example, "t[i+1] = 10; t[i+1] == 10".
--
-- so when we are about to construct a new complex number
-- with real part x and imaginary part y, we want to see
-- if we already have that value, and if so we reuse
-- the existing copy.
--
-- if values[c] is {real = x, imag = y}, then
-- inverseValues[x][y] is c
--
-- inverseValues[x] is a value-weak table.

local inverseValues = {}
setmetatable(inverseValues, vmode)

--[[
-- print state of values[c] and inverseValues[real][imag].
--
-- if all complex values have been deleted, the content of these tables
-- should be garbage-collected and empty.
--
function dbstate()
    print('values:')
    for k,v in pairs(values) do print(k,v) end

    print('inverse values:')
    for k,v in pairs(inverseValues) do
        print(k, '(real table)')
        for k1,v1 in pairs(inverseValues[k]) do
            print(k, k1,v1)
        end
    end
end
--]]

cmath.eps = 1e-12

-- consider two numbers (float or int) to be approximately equal if
-- they are within epsilon of each other or if their
-- relative error is within epsilon.
-- if epsilon is zero, this function reduces to exact equality.
function near(x,y)
    if cmath.eps == 0 then return x == y end

    if 1 <= luamath.abs(x) and luamath.abs(x) <= luamath.abs(y) then
        x, y = 1, y/x

    elseif 1 <= luamath.abs(y) and luamath.abs(y) <= luamath.abs(x) then
        x, y = x/y, 1
    end

    return luamath.abs(x-y) <= cmath.eps
end

local is_complex = function(c)
    return values[c] ~= nil
end

local function cmath_type(c)
    if is_complex(c) then
        return 'complex'

    elseif luamath.type then
        return luamath.type(c)

    elseif type(c) ~= 'number' then
        return nil

    elseif luamath.fmod(c, 1) == 0 then
        return 'integer'

    else
        return 'float'
    end
end

local re = function(c)
    if cmath_type(c) == 'complex' then
        return values[c].real
    else
        return c
    end
end

local im = function(c)
    if cmath_type(c) == 'complex' then
        return values[c].imag

    elseif type(c) == 'number' then
        return 0

    else
        error("bad argument #1 to 'im' (number expected)")
    end
end

local function closeToInt(r)
    local int, _ = math.modf(r)

    return near(int, r) or near(int+1, r) or near(int-1, r)
end

local function toIntIfPossible(r)
    if not closeToInt(r) then return r end

    local int, _ = math.modf(r)
    local result

    if near(int, r) then
        result = int

    elseif near(int + 1, r) then
        result = int + 1

    else
        result = int - 1
    end

    return result
end
if TESTX then
    local eps2 = cmath.eps / 2
    test:check( 4, toIntIfPossible( 4 + eps2), 'toIntIfPossible  4+eps')
    test:check( 4, toIntIfPossible( 4 - eps2), 'toIntIfPossible  4-eps')
    test:check(-4, toIntIfPossible(-4 + eps2), 'toIntIfPossible -4+eps')
    test:check(-4, toIntIfPossible(-4 - eps2), 'toIntIfPossible -4-eps')
end

-- if a complex value is close enough to the real line, make it real.
-- if either real part of complex part is close to an integer, make
-- it an integer.

local simplifyNumber = function(c)
    local result

    if near(im(c), 0) then
        result = toIntIfPossible(re(c))
    else
        result = c 
    end

    return result
end

-- create a function for insertion into the cmath
-- table, that examines the type of its argument
-- and either applies the math.lua version of the
-- function or a local version for complex values.

local applyOldOrNew = function(cfn, rfn, name)
    if name ~= nil then
        name = string.format("#1 to '%s' ", tostring(name))
    else
        name = ''
    end

    return function(c)
        assert(cmath_type(c) ~= nil, 
               string.format("bad argument %s(number expected)", name))

        if cmath_type(c) == 'complex' then
            return simplifyNumber(cfn(c))

        else
            return rfn(c)
        end
    end
end

-- create a new complex value.
--
-- if no argument, create 0 + 0i.
-- if one real argument x, create complex x + 0i
-- if one complex value, return the value.
-- if two real values x and y, create x + iy.
--
-- if we make a new complex number, make x and y ints if possible.

makeComplex = function(...)
    local args = {...}
    local a1 = args[1]
    local a2 = args[2]

    local real, imag

    if #args == 0 then
        real, imag = 0, 0

    elseif #args == 1 then
        if is_complex(a1) then
            return a1
        else
            real, imag = a1, 0
        end

    elseif #args == 2 then
        real, imag = a1, a2
    end

    assert(type(real) == 'number' and type(imag) == 'number',
           'invalid argument(s)')

    local result

    real = toIntIfPossible(real)
    imag = toIntIfPossible(imag)

    if inverseValues[real] and inverseValues[real][imag] then
        result = inverseValues[real][imag]

    else
        local newc = {}
        setmetatable(newc, complex_mt)

        values[newc] = {real = real, imag = imag}

        if inverseValues[real] == nil then
            inverseValues[real] = {}
            setmetatable(inverseValues[real], vmode)
        end

        -- when no complex numbers exist with a given
        -- real part, we want to garbage collect the
        -- first-level table of inverseValues, which
        -- will be an empty table at that point.

        values[newc].inverseRef = inverseValues[real]

        inverseValues[real][imag] = newc

        result = newc
    end

    return result
end

local I = makeComplex(0, 1)

local to_complex = function(c)
    if not is_complex(c) then c = makeComplex(c) end

    return c
end

local function isInt(n)
    if luamath.type then
        return luamath.type(n) == 'integer'
    else
        local _,frac = luamath.modf(n)
        return frac == 0
    end
end

cmath.format = "%.3f"

local function realToString(re)
    if isInt(re) then
        return tostring(re)
    else
        return string.format(cmath.format, re)
    end
end

local function imagToString(im)
    if im == 1 then
        return 'i'
    else
        return 'i * ' .. realToString(im)
    end
end

complex_mt.__tostring = function(c)
    local real, addsign, imag = re(c), '+', im(c)

    if near(real, 0) then real = 0 end
    if near(imag, 0) then imag = 0 end

    if imag < 0 then addsign, imag = '-', -imag end

    if imag == 0 then
        return tostring(realToString(real))

    elseif real == 0 then
        if addsign == '+' then addsign = '' end

        return string.format('%s%s',
                   addsign,
                   imagToString(imag))
    else
        return string.format('%s %s %s',
                   realToString(real),
                   addsign,
                   imagToString(imag))
    end
end

complex_mt.__len = function(v1, v2)
    error('attempt to get length of a complex value')
end

complex_mt.__add = function(v1, v2)
    v1, v2 = to_complex(v1), to_complex(v2)

    return simplifyNumber(makeComplex(re(v1) + re(v2), im(v1) + im(v2)))
end

complex_mt.__sub = function(v1, v2)
    v1, v2 = to_complex(v1), to_complex(v2)

    return simplifyNumber(makeComplex(re(v1) - re(v2), im(v1) - im(v2)))
end

complex_mt.__unm = function(v)
    v = to_complex(v)

    return simplifyNumber(makeComplex(-re(v), -im(v)))
end

complex_mt.__mul = function(v1, v2)
    v1, v2 = to_complex(v1), to_complex(v2)

    return simplifyNumber(makeComplex(re(v1) * re(v2) - im(v1) * im(v2),
                                      re(v1) * im(v2) + im(v1) * re(v2)))
end

-- equality with tolerance; real parts must be closer
-- than tolerance, and so must imaginary parts.
-- (could have computed L2 distance between the points,
-- but that would be computationally expensive and not
-- really worth it anyway.)

complex_mt.__eq = function(v1, v2, eps)
    eps = eps or cmath.eps

    v1, v2 = to_complex(v1), to_complex(v2)

    return     luamath.abs(re(v1) - re(v2)) < eps
           and luamath.abs(im(v1) - im(v2)) < eps
end

complex_mt.__div = function(v1, v2)
    v2 = to_complex(v2)

    local v2InverseDenom = re(v2) * re(v2) + im(v2) * im(v2)

    local v2Inverse = makeComplex( re(v2) / v2InverseDenom,
                                  -im(v2) / v2InverseDenom)

    return simplifyNumber(v1 * v2Inverse)
end

local abs = applyOldOrNew(
    function(c) return luamath.sqrt(re(c)*re(c) + im(c)*im(c)) end,
    luamath.abs, 'abs')

complex_mt.__pow = function(c, cpow)
    c, cpow = to_complex(c), to_complex(cpow)

    local r     = abs(c)
    local theta = luamath.atan2(im(c), re(c))

    local result = r ^ re(cpow)
    result = result * luamath.exp(-im(cpow)*theta)

    local angle = re(cpow)*theta + im(cpow)*luamath.log(r)
    result = result * makeComplex(luamath.cos(angle), luamath.sin(angle))

    return simplifyNumber(result)
end

complex_mt.__index = function(t, key)
    error("error:  " ..
           "attempt to index a complex number.")
end

complex_mt.__newindex =
    function()
        error("error:  " ..
               "cannot create or change fields in a complex value")
    end

complex_mt.__lt =
    function()
        error("error:  " ..
               "complex numbers are not totally ordered.")
    end

complex_mt.__le =
    function()
        error("error:  " ..
               "complex numbers are not totally ordered.")
    end

complex_mt.__mod =
    function()
        error("error:  " ..
               "modular arithmetic is not defined on complex numbers.")
    end

complex_mt.__idiv =
    function()
        error("error:  " ..
               "integer division is not defined on complex numbers.")
    end

complex_mt.__metatable = "There is no metatable."

complex_mt.__pairs =
    function()
        error("bad argument #1 to 'pairs' (table expected, got complex value)")
    end

local angle = applyOldOrNew(
    function(c) return luamath.atan2(im(c), re(c)) % (2*luamath.pi) end,
    function(c) return c >= 0 and 0. or luamath.pi end,
    'angle')

local exp = applyOldOrNew(
        function(c) return luamath.exp(1) ^ c end,
        luamath.exp,
        'exp')

local sqrt = applyOldOrNew(
    function(c) return c ^ .5 end,
    function(r) return r < 0 and makeComplex(r,0) ^ .5 or luamath.sqrt(r) end,
    'exp')

local log = function(c)
    local theta = angle(c) % (2 * luamath.pi)
    return simplifyNumber(makeComplex(luamath.log(abs(c)), theta))
end

local log = applyOldOrNew(
    log,
    function(r) return r > 0 and luamath.log(r) or log(r) end,
    'log')

local log10 = applyOldOrNew(
    function(c) return log(c) / luamath.log(10) end,
    function(r) return r > 0 and luamath.log10(r) or log(r) / luamath.log(10) end,
    'exp')

local cosh = function (r)
    return (luamath.exp(r) + luamath.exp(-r)) / 2
end

local sinh = function (r)
    return (luamath.exp(r) - luamath.exp(-r)) / 2
end

local complexCos = function(c)
    return simplifyNumber(makeComplex(luamath.cos(re(c)) * cosh(im(c)),
                                     -luamath.sin(re(c)) * sinh(im(c))))
end

local complexSin = function(c)
    return simplifyNumber(makeComplex(luamath.sin(re(c)) * cosh(im(c)),
                                      luamath.cos(re(c)) * sinh(im(c))))
end

local cos = applyOldOrNew(complexCos, luamath.cos, 'cos')
local sin = applyOldOrNew(complexSin, luamath.sin, 'sin')

local tan = applyOldOrNew(
        function(c) return complexSin(c) / complexCos(c) end,
        luamath.tan,
        'tan')

local complexAcos = function(c)
    return -I * log(c + I * sqrt(1 - c*c))
end

local normalizeAsin = function(c, low, high)
    local r = re(c)
    local i = im(c)

    -- get r in [-pi .. pi)
    while r < -luamath.pi do r = r + 2*luamath.pi end
    while r >= luamath.pi do r = r - 2*luamath.pi end

    -- get r >= low, flipping around low.  (sin function is symmetric there.)
    while r < low do r = 2*low - r end

    -- get r < high, flipping around high.  (sin function is symmetric there.)
    while r >= high do r = 2*high - r end

    return makeComplex(r, i)
end

local complexAsin = function(c)
    return  simplifyNumber(normalizeAsin(-I * log(I * c + sqrt(1 - c*c)),
                                         -luamath.pi/2, luamath.pi/2))
end

local normalizeAtan = function(c, low, high)
    local r = re(c)
    local i = im(c)

    -- get r >= low
    while r < low do r = r + luamath.pi end

    -- get r < high
    while r >= high do r = r - luamath.pi end

    return makeComplex(r, i)
end

local complexAtan = function(num, den)
    den = den or 1

    if den == I * 0 then
        return 0
    else
        local x = num / den
        return simplifyNumber(normalizeAtan(I / 2 * log((I + x) / (I - x)),
                                           -luamath.pi/2, luamath.pi/2))
    end
end

local acos  = applyOldOrNew(
    complexAcos,
    function(r) return luamath.abs(r) > 1 and complexAcos(r) or luamath.acos(r) end,
    'acos')

local asin  = applyOldOrNew(
    complexAsin,
    function(r) return luamath.abs(r) > 1 and complexAsin(r) or luamath.asin(r) end,
    'asin')

local atan  = applyOldOrNew(complexAtan, luamath.atan,  'atan')

local atan2 = applyOldOrNew(
    complexAtan,
    function(num, den) den = den or 1; return luamath.atan2(num, den) end,
    'atan2')

-- cmath operations derived from the math library can only be applied
-- to non-complex numbers by default.

for k,v in pairs(luamath) do
    if type(v) == 'function' then
        cmath[k] = applyOldOrNew(
            function () error('invalid operation on complex value') end,
            v)
    else
        cmath[k] = v
    end
end

-- new things in cmath..
cmath.i       = makeComplex(0, 1)
cmath.angle   = angle
cmath.re      = re
cmath.im      = im
-- cmath.eps defined above.

-- math library functions with extensions to work on complex numbers..
cmath.type    = cmath_type
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
cmath.atan2   = atan2

return cmath
