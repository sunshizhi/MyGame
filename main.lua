
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
require "cocos.init"
require "src.app.views.common.Util"

cccclog=print

if 0==cc.Application:getInstance():getTargetPlatform() then
		local f = io.open(".\\debug.txt", 'w')
		f:write("\n")
		f:close()
        --增加打印日志到文件的功能
        cclog = function(...)
        	local params={...}
        	if type(params[1])=="table" then
                local f = io.open(".\\debug.txt", 'a+')
        		local str=tableToString(params[1])
        		cccclog(str)
                f:write(str)
                f:close()
        	else
            	local str=string.format(...)
            	cccclog(str)
            	local f = io.open(".\\debug.txt", 'a+')
            	f:write(str.."\n")
            	f:close()
            end
        end
else 
	cclog = function(...)
            local params={...}
            if type(params[1])=="table" then
                for k,v in pairs(params) do
                    cccclog(k,v)
                end
            else
                local str=string.format(...)
                cccclog(str)
            end
        end
end

print=cclog

local function main()
    require("app.MyApp"):create():run()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
    cclog(msg)
end
