
-- 消息枚举名称
--如果send_msg_name为nil,则代表消息为服务端主动推送，只需要写好回调函数接收即可，在需要接收的地方调用回调
NetMessage = {
    -- msg_type                 send_msg_name                   receive_msg_name                    function
    
    ["ping"       ] =  {},    -- 心跳
    ["login"      ] = {function (data) Login:loginRec(data) end},    -- 登录
    ["logout"     ] = {function (data) Login:logoutRec(data) end},    -- 退出
    ["begin"      ] = {function (data) PlayScene:beginRec(data) end},    -- 游戏开始
    ["whoStart"  ] = {function (data) PlayScene:whoStartRec(data) end},    -- 谁先出牌
    ["putCard"   ] = {function (data) PlayScene:putCardRec(data) end},    -- 出牌
    ["giveUp"   ] = {function (data) PlayScene:giveUpRec(data) end},    -- 投降
    ["gameOver" ] = {function (data) PlayScene:gameOverRec(data) end},    -- 游戏结束
}