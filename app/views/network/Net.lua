Net = class("Net")

local json = import("..json.json")

import ".NetMessage"
import ".NetConfig"

local timerLocal = nil
local wsSendText   = nil
local wsSendBinary = nil
local wsError      = nil
local sendTextStatus  = nil
local sendBinaryStatus = nil
local errorStatus  = nil
local receiveTextTimes = 0
local receiveBinaryTimes = 0

function Net:ctor(...)
    
end

function Net:init()
    wsSendText   = cc.WebSocket:create(server_host)
    wsSendBinary = cc.WebSocket:create(server_host)
    wsError      = cc.WebSocket:create("ws://invalid.url.com")

    local function wsSendTextOpen(strData)
    end

    local function wsSendTextMessage(strData)
        receiveTextTimes= receiveTextTimes + 1  
        --print("someone say : " .. strData)
        local data = json.decode(strData)
        local type = data.type

        if type ~= nil then
            if NetMessage[type] ~= "ping" and NetMessage[type] ~= "close" then
                if NetMessage[type][1] ~= nil then
                    NetMessage[type][1](data)
                end
            else
                release_print ("-----not register msg type: "..tostring(type))
            end
        end
    end

    local function wsSendTextClose(strData)
    end

    local function wsSendTextError(strData)
        print("sendText Error was fired")
    end

    if nil ~= wsSendText then
        wsSendText:registerScriptHandler(wsSendTextOpen,cc.WEBSOCKET_OPEN)
        wsSendText:registerScriptHandler(wsSendTextMessage,cc.WEBSOCKET_MESSAGE)
        wsSendText:registerScriptHandler(wsSendTextClose,cc.WEBSOCKET_CLOSE)
        wsSendText:registerScriptHandler(wsSendTextError,cc.WEBSOCKET_ERROR)
    end
    return true
end

function Net:sendMsg(data)
    local jsonTest = json.encode(data)      --table转json
    --print('JSON encoded test is: ' .. jsonTest) 
    if wsSendText:getReadyState() == cc.WEBSOCKET_STATE_OPEN then 
        wsSendText:sendString(jsonTest)
    else
        print("connect failed")
        Login:login(Login.name, "111")
    end
end

return Net