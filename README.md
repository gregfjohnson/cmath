# cmath
cmath.lua is an extension of the lua standard math library that includes
complex arithmetic.  It has been tested on lua 5.1 through 5.3.

It is intended to be a drop-in replacement for math.lua in thoses cases
where complex arithmetic is needed.  Other than using the new name,
(i.e., "cmath.sin()" instead of "math.sin()", the intent is that you
should not need to change how you do math in lua in any way.

To download from github, you can use the following command:

 - git clone http://github.com/gregfjohnson/cmath

Normal usage begins with

> require 'cmath'

This defines new names 'cmath' and 'ctype'.  For convenience, it also
defines the important constants 'pi', 'i', and 'e'.

For those who prefer not to do requires that make changes to the
global namespace:

> cc = require 'cmath_anon'

In those cases where a function can be extended to handle complex values,
the original function in math.lua is given additional functionality.
For example, cmath.sqrt(-1) returns i.

In addition to all of the standard functions and values in math.lua,
five new things have been added to cmath:

 - cmath.i
 - cmath.angle()
 - cmath.re()
 - cmath.im()
 - cmath.format             -- defaults to '%.3f'
 
Requiring 'cmath' also provides the following name bindings for convenience:

 - ctype()      -- similar to type(), but returns 'number' for complex values
 - i, e, pi     -- short names for important constants

Complex values are built up with standard arithmetic using the new
constant cmath.i.

For example, here is one of the most famous equations in mathematics:

> e ^ (pi * i) == -1
true

> print(3 + 4 * i)
3 + 4 * i

> omega = e ^ (2 * pi * i / 1024)
> omega ^ 256
i
 
Complex values can be used as table keys, just like standard numbers:

> t = {}
> t[1 + i] = 10
> t[1 + i]
10

This leads to a compact way to represent matrices:

> mat = {}
> m[1 +   i] = 11
> m[1 + 2*i] = 12
> m[2 +   i] = 21
> m[2 + 2*i] = 22

Here is a terse way to create the 64x64 DFT matrix:

dftMat = {}
omega = e ^ (-2 * pi * i / 64)

for r = 0, 63 do
    for c = 0, 63 do
        dftMat[r + i * c] = omega ^ (r*c)
    end
end

cmath.lua is intended to be zipped up and 'airtight'.

Complex numbers are supposed to work just like standard lua numbers in
every way.  What works with regular numbers should work with complex
numbers.

Any operation that fails on standard lua numbers is intended to fail in
the same way on complex numbers.  (If you find a case where that is not
true, please report it!  That would be a bug in cmath.lua.)

Complex values are immutable, in the same way that standard lua numbers
are immutable.  Complex values are (almost) opaque.  You cannot examine
or change anything about them without going to extreme means via, for
example, the debug library.  As with standard lua numbers, you cannot
use metatables with them.

Known issues

This module is optimized for convenience of installation and ease of use,
not performance or numerical accuracy.

It is intended to be a fun way to experiment with and learn about complex
numbers for small to moderate applications.

If you need to optimize performance or you need high-quality numerical
results, please consider using lcomplex at
    http://webserver2.tecgraf.puc-rio.br/~lhf/ftp/lua.
