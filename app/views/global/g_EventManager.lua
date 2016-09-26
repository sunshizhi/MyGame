--by sunshizhi 2015-8-26
--消息机制类

g_EventManager = {}

g_EventManager.eventType = {}

function g_EventManager:addEventListener(eventName, listener)
    g_EventManager.eventType[eventName] = {listener}--这么改的目的是不考虑一对多的消息映射，一个消息index只对应一个回调就行了，否则重新打开时，由于listener肯定不同，会造成崩溃
	--if g_EventManager.eventType[eventName] == nil then
    --    g_EventManager.eventType[eventName] = {listener}
	--else
    --    local tab = g_EventManager.eventType[eventName]
    --    for i=1, #tab do
    --        if tab[i] == listener then
    --            return
    --        else
    --            tab[#tab + 1] = listener
    --        end
    --    end
	--end
end

function g_EventManager:dispatchEvent(eventName, arg)
	local listenerEvent = g_EventManager.eventType[eventName]
	if listenerEvent == nil then
	   return
	end
	for i=1, #listenerEvent do
	   local ret = listenerEvent[i](arg)
	   if ret == false then  --若返回false则删除已加入的监听，将监听置空
            g_EventManager.eventType[eventName] = nil
	   end
	end
end

function g_EventManager:removeEventListener(eventName, listener)
	if g_EventManager.eventType[eventName] == nil then
	   return
	end
	
	local tab = g_EventManager.eventType[eventName]
	for i=#tab, -1 do
	   if tab[i] == listener then
    	   table.remove(tab,i)
    	   release_print("remove eventName!"..eventName)
	   end
	end
	
	if #tab == 0 then
	   g_EventManager.eventType[eventName] = nil
	end
end


g_EventManager.globalEventType = {}    --Xyang. 8.31 增加即时投递消息类型。在主scene里的update中dispatch
function g_EventManager:addGlobalEventListener(eventName, listener, arg)
    if g_EventManager.globalEventType[eventName] == nil then
        g_EventManager.globalEventType[eventName] = {{listener,arg}}
    else
        local tab = g_EventManager.globalEventType[eventName]
        for i=1, #tab do
            if tab[i][1] == listener and tab[i][2] == arg then
                return
            else
                tab[#tab + 1] = {listener,arg}
            end
        end
    end
end

function g_EventManager:dispatchAllGlobalEvents()
    --local deleteList = {}
    for key, var in pairs(g_EventManager.globalEventType) do
        --release_print(key,var)
        for i=1, #var do
            var[i][1](var[i][2]--[[arg--]])
            g_EventManager:removeGlobalEventListener(key, var[i][1])
        end
        --table.insert(deleteList,table.maxn(deleteList)+1,key)
    end
    --for key, var in pairs(deleteList) do
        --table.remove(g_EventManager.globalEventType,var)
    --end
end

function g_EventManager:removeGlobalEventListener(eventName, listener)
    if g_EventManager.eventType[eventName] == nil then
        return
    end

    local tab = g_EventManager.eventType[eventName]
    for i=#tab, -1 do
        if tab[i] == listener then
            table.remove(tab,i)
            release_print("remove eventName!"..eventName)
        end
    end

    if #tab == 0 then
        g_EventManager.eventType[eventName] = nil
    end
end

function g_EventManager:clearAllData()
    g_EventManager.eventType = {}
end

return g_EventManager
