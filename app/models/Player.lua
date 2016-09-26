--region Player.lua
--Author : ssz
--Date   : 2016/9/9
--玩家类
Player = {
    id = 0,
    name = "",
    last_one = 0,           --1代表最后进入房间的 
    jewel_num = 2,          --宝石次数，初始为2
    fight_state = 0,        --战斗时的状态
}

OtherPlayer = clone(Player)

return Player


--endregion
