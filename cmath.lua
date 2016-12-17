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

cmath = require 'cmath_anon'
i, e, pi = cmath.i, cmath.exp(1), cmath.pi

ctype = function(value)
    if cmath.type(value) ~= nil then
        return 'number'
    else
        return type(value)
    end
end

return cmath
