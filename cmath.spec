package = "cmath"
version = "0.1.0"
source = {
   url = "http://github.com/gregfjohnson/cmath.git",
   tag = "v1.0",
}
description = {
   summary = "Pure-lua implementation of complex numbers",
   detailed = [[
   cmath.lua is an extension of the lua standard math library that includes
   complex arithmetic.  The design goal is to be complete, minimal, and
   unobtrusive.
    Complete:     Things that work with regular numbers also work with complex numbers.
    Minimal:      Almost no "new" stuff is added; just use lua the way you are used to,
                    and things should work the way you expect:
                    cmath.sqrt(-1) == i; t[3 + 4*i] = 12; e^(i*pi) == -1
    Unobtrusive:  There is almost nothing new you have to learn.  Complex functionality
                  is integrated into normal lua operations.  Complex numbers work
                  just like normal lua numbers.

    cmath is not "industrial-grade" from from the perspectives of high performance
    or high numerical accuracy.  It is intended to be fun, easy to install and use,
    and good for playing around with complex numbers on small to moderate projects.
   ]],
   homepage = "http://github.com/gregfjohnson/cmath",
   license = "GPL/2.0"
}
dependencies = {
   "lua >= 5.1, < 5.4",
}

build = {
   type = "builtin",
   modules = {
      cmath = "cmath.lua",
      }
   },
   copy_directories = { }
}
