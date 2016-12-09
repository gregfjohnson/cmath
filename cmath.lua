-----------------------------------------------------------------------------
-- Copyright (c) Greg Johnson, Gnu Public Licence v. 2.0.
-----------------------------------------------------------------------------
--[[
    Standard usage is:

    require 'cmath'

    This creates a new global variable 'cmath', a table that
    is backward-compatible with the standard lua math library
    but adds complex arithmetic.

    For situations where there is a preference to avoid
    modifications via side effects to the global namespace:

    local ComplexMath= require 'cmath_anon' 

    or even

    math = require 'cmath_anon'

    can be used.
--]]

cmath = require 'cmath_anon'
i, e, pi = cmath.i, cmath.exp(1), cmath.pi

return cmath
