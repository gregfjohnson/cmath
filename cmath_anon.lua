-----------------------------------------------------------------------------
-- Copyright (c) Greg Johnson, Gnu Public Licence v. 2.0.
-----------------------------------------------------------------------------

--[[
    for situations where

    local myComplexNamespace = require 'cmath_anon' 

    is preferred.

    Unlike require 'cmath', which adds the name cmath to the
    global namespace, requiring this file does not make any
    changes to the global namespace as side effects.
--]]

local path = package.searchpath('cmath', package.path)

-- environment entries that cmath.lua needs when loading
local env = {
    package      = package,
    type         = type,
    assert       = assert,
    setmetatable = setmetatable,
    math         = math,
    pairs        = pairs
}

return loadfile(path, 't', env)()
