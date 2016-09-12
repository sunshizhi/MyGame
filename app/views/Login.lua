--region Login.lua
--Author : ssz
--Date   : 2016/9/9
--登录
Login = class("Login")
import "src.app.models.Player"
import "src.app.views.PlayScene"

Login.name = "b"
    
function Login:ctor(...)
end

function Login:login(name, roomId)
    local t = os.time()
    while os.time() - t < 2 do
        if os.time() - t == 1 then
            break
        end
    end

    local data = {type = 'login', client_name = name .. "", room_id = roomId .. ""}
    Net:sendMsg(data)
end

function Login:loginRec(data)
    local client_name = data.client_name
    local client_list = data.client_list
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
            --获取在等待玩家的信息
            self:getOtherPlayerInfo(client_list)
        end
    else
        OtherPlayer.name = client_name
        print("玩家" .. client_name .. "加入游戏")
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

return Login
