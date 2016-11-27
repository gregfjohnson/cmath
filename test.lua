#!/usr/bin/env lua
-----------------------------------------------------------------------------
-- Copyright (c) Greg Johnson, Gnu Public Licence v. 2.0.
-----------------------------------------------------------------------------
--[[
    Lightweight test infrastructure.  put tests inline with your lua code.
    -- add tests like this into your code:
    if TESTX then
        local expected, actual = 'foo', 'bar'
        test:check(expected, actual, 'compare foo to bar')
    end

    -- for the function you are working on at the moment, delete the "X":
    if TEST then
        local expected, actual = 'foo', 'bar'
        test:check(expected, actual, 'compare foo to bar')
    end

    -- run the tests; "-a" will run all tests, no "-a" will run just "TEST" tests.
    test.lua [-a] foobar.lua
--]]

test = {}

local function printf(fmt, ...)
    io.write(string.format(fmt, ...))
end

local onFirstFail

local failedTests, passedTests = 0, 0
local cumeFailedTests, cumePassedTests = 0, 0

local checkFirstFail = function()
    if onFirstFail then
        printf("%s\n", onFirstFail)

        isFirstFail = nil
    end
end

printStackTrace = false

function test:checkPredicate(e, a, msg, pred)
    if pred(e, a) then
        passedTests = passedTests + 1

    else
        failedTests = failedTests + 1

        checkFirstFail()
        printf("%s\nexpected:\n%s\nactual:\n%s\n",
               msg,
               tostring(e), 
               tostring(a))

        if printStackTrace then
            print(debug.traceback())
        end
    end
end

function test:check(e, a, msg)
    self:checkPredicate(e,a,msg, function(a,b) return a == b end)
end

test.eps = 1e-12

function test:checkNear(e, a, msg)
    local near = function(a,b) return math.abs(a-b) < self.eps end
    self:checkPredicate(e,a,msg, near)
end

local function isConfigArg(arg)
    return #arg > 0 and arg:sub(1,1) == '-'
end

local function main()
    local dash_a = ''
    TEST = true
    local maxName = 2

    for i = 1, #arg do
        if arg[i] == '-a' then
            TESTX = true
            dash_a = '-a '

        elseif arg[i] == '-v' then
            printStackTrace = true

        else
            if maxName < #arg[i] then maxName = #arg[i] end
        end
    end

    local spacing = ''
    for i = 1, maxName do spacing = spacing .. ' ' end

    results = ''
    local testCount = 0

    for i = 1, #arg do
        if not isConfigArg(arg[i]) then
            testCount = testCount + 1

            onFirstFail = 
                string.format('test.lua %s%s:%s',
                       dash_a, arg[i], spacing:sub(#arg[i]))

            local chunk, oops = loadfile(arg[i])

            if not chunk then
                failedTests = failedTests + 1
                checkFirstFail()
                printf("chunk %s not loaded:  %s\n", arg[i], oops)

            else
                local fn = function() chunk() end
                local ok, oops = pcall(fn)

                if not ok then
                    failedTests = failedTests + 1
                    checkFirstFail()
                    printf("chunk %s assertion failure:  %s\n", arg[i], oops)
                end
            end

            results = results ..
                string.format('test.lua %s%s:%s%4d passed, %4d failed\n',
                       dash_a, arg[i], spacing:sub(#arg[i]),
                       passedTests, failedTests)


            cumeFailedTests = cumeFailedTests + failedTests
            cumePassedTests = cumePassedTests + passedTests

            failedTests = 0
            passedTests = 0
        end
    end

    printf('%s', results)

    if cumeFailedTests == 0 then
        print('all tests passed')

    elseif testCount > 1 then
        printf('%d tests passed, %d tests failed\n',
               cumePassedTests, cumeFailedTests)
    end
end

main()
