--region Login.lua
--Author : ssz
--Date   : 2016/9/9
--登录
Login = class("Login")
import "src.app.models.Player"
import "src.app.views.PlayScene"
import "src.app.config.cardConfig"

Login.name = "a"
Login.roomId = "333"
    
function Login:ctor(...)
end

function Login:login(name, roomId)
    delayCallFunc(1, 2, function() 
        local data = {type = 'login', client_name = name .. "", room_id = roomId .. ""}
        Net:sendMsg(data)
    end)
end

function Login:loginRec(data)
    local client_name = data.client_name
    local client_list = data.client_list
    local who_start = data.who_start

    if Player.id == 0 then
        Player.id = data.client_id
        Player.name = client_name
        print("我" .. client_name .. "加入游戏")

        local client_list_num = 0
        for k, v in pairs(client_list) do
            client_list_num = client_list_num + 1
        end
        --代表已经有玩家在等待
        if client_list_num >1 then
            Player.last_one = 1
            --获取在等待玩家的信息
            self:getOtherPlayerInfo(client_list)
        end
    else
        OtherPlayer.name = client_name
        print("玩家" .. client_name .. "加入游戏")
        addTipLabel("玩家" .. client_name .. "加入游戏")
        PlayScene:playerJoin(client_name)
    end
end

--获取对手信息
function Login:getOtherPlayerInfo(list)
    for k, v in pairs(list) do
        if k ~= Player.id then
            OtherPlayer.id = k
            OtherPlayer.name = v
            break
        end
    end
end

--退出
function Login:logoutRec(data)
    local client_name = data.from_client_name
    addTipLabel("玩家" .. client_name .. "退出游戏！")
end

return Login
