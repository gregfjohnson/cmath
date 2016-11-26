# cmath
cmath.lua is an extension of the lua standard math library to include complex arithmetic.

It is intended to be a drop-in replacement for math.lua in thoses cases where complex arithmetic is needed.  Other than
using (for example) "cmath.sin()" instead of "math.sin()", the intent is that you should not need to change how you do
math in lua in any way.  Normal usage begins with

 require 'cmath'

For the courageous, you could try

 math = require 'cmath'
 
For those who prefer not to do requires that implicitly change the global namespace:

 complex = require 'cmath_anon'

In those cases where a function can be extended to handle
complex values, the original function in math.lua is given additional functionality.
For example, cmath.sqrt(-1) returns i * 1.0.

In addition to all of the standard functions and values in math.lua, four new things have been added to cmath:

 - cmath.i
 - cmath.angle()
 - cmath.re()
 - cmath.im()
 
Complex values are built up with standard arithmetic using the one new constant cmath.i:

 - i, e, pi = cmath.i, cmath.exp(1), cmath.pi    -- a few handy shortcuts
 - print(3 + 4 * i)
 - omega = e ^ (2 * pi * i / 1024)
 
cmath.lua is intended to be 'airtight'.  Any operation that fails on standard lua numbers is intended to fail in 
the same way on complex numbers.  (If you find a case where that is not true, please report it!  That would be a bug
in cmath.lua.)

Complex values are immutable, in the same way that standard lua numbers
are immutable.  Complex values are (almost) opaque.  You cannot examine or change anything about them without going
to extreme means via, for example, the debug library.  As with standard lua numbers, you cannot use metatables with them.


Known issues

Currently, type(c) returns 'table' for complex values.  I'm not sure how to fix that.  It would be nice if type(c) could
be made to report 'number' even for complex values.  However, cmath.type(c) does correctly
return 'complex' for complex values.

In the current version of cmath.lua, attempts to compare complex values with standard numbers do not work.
I.e., 

 - e ^ (pi * i) == -1

incorrectly returns false.  Equality works as expected
if both values are complex:

 - e ^ (pi * i) == -1 + 0*i
 
correctly returns true.

