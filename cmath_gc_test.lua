package.path = './?.lua'
require 'cmath'

function nct()
    local n = 0
    for _,_ in pairs(_G) do n = n+1 end
    print('_G count', n)
end

state();nct()

collectgarbage(); print(collectgarbage('count'))

function doit()
    size = 10000
    t = {}
    for j = 1, size do
        t[j] = j + i
    end
    for j = 1, 10 do
        print(t[j])
    end
    print(collectgarbage('count'))
    state();nct()
end

collectgarbage(); print(collectgarbage('count'))

state();nct()

for j = 1, 10 do
    collectgarbage(); print(collectgarbage('count'))
end

function cleanit()
    size = nil
    t = nil
    --reset()
end
collectgarbage(); print(collectgarbage('count'))
collectgarbage(); print(collectgarbage('count'))

collectgarbage(); print(collectgarbage('count'))
collectgarbage(); print(collectgarbage('count'))


doit(); cleanit(); collectgarbage(); print(collectgarbage('count')); state();nct()
doit(); cleanit(); collectgarbage(); print(collectgarbage('count')); state();nct()
doit(); cleanit(); collectgarbage(); print(collectgarbage('count')); state();nct()
doit(); cleanit(); collectgarbage(); print(collectgarbage('count')); state();nct()
