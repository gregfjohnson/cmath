To install, copy cmath.lua and cmath_anon.lua to any of your standard lua library locations.
One convenient way to see the library locations is to run the command

 - lua -e 'print(package.path)'
 
Pick one of the listed directories and copy cmath.lua and cmath_anon.lua.  (You may need to use sudo.)

It is always possible to "look before you leap", and experiment with cmath.lua before installing it.
Simply copy the two files into any handy directory, enter that directory, and run lua.  You can use

 - require 'cmath'
 
and begin using it immediately.
