
package.path = './lib/?/init.lua;./lib/?.lua;' .. package.path

table.inspect = require('inspect')
local posix = require('posix')
require('irc')
require('selene')

--find conf

local home = os.getenv("HOME")

local f,err = loadfile(home .. "/.config/selene/selene.conf")

if f then 
    selene = Selene(f())
else
    print (err .. ", Trying global config")
    f = loadfile("/etc/selene/selene.conf")
    if f then
        selene = Selene(f())
    end
end

if selene then
    posix.signal(posix.SIGINT, function() selene:quit() end)
    selene:run()
else
    print("Unable to find config")
end
