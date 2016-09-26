MainScene = class("MainScene", cc.load("mvc").ViewBase)
import ".network.Net"
import ".Login"

MainScene.RESOURCE_FILENAME = "MainScene.csb"

import ".global.g_TouchEvent"

function MainScene:onCreate()
    self.csbLayer = self:getResourceNode()
    local playButton = self.csbLayer:getChildByName("PlayButton")

    g_TouchEvent:new(playButton, function() self:play() end)

    if Player.id == 0 then
        if Net:init() then
            Login:login(Login.name, Login.roomId)
        end
    end
end 

function MainScene:play()
    print("play")
    self:getApp():enterScene("PlayScene","FADE",0.1)
end

return MainScene