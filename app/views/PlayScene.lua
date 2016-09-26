PlayScene = class("PlayScene", cc.load("mvc").ViewBase)
PlayScene.RESOURCE_FILENAME = "PlayScene.csb"

PlayScene.whatRound = {
    one = 1,
    two = 2,
    three = 3
}

PlayScene.attack_type = {  --卡牌攻击类型，近攻，远攻，攻城
    one = 1,
    two = 2,
    three = 3
}

PlayScene.gameStateEnu = {  --游戏状态
    READY = 0,
    BEGIN = 1,
    FINGHT = 2,
    END = 3,
    GIVEUP = 4
}

PlayScene.overType = {  --游戏结束方式
    NOCARDS = 1,    --没有卡牌了
    GIVERUP = 2,    --放弃
}

PlayScene.totalCardNum = 10
PlayScene.gameState = PlayScene.gameStateEnu.READY

function PlayScene:onCreate()
    self.csbLayer = self:getResourceNode()

    local function onNodeEvent(event)
        if event == "enter" then
            self:onEnter()
        elseif event == "exit" then
            self:onExit()
        end
    end

    self:registerScriptHandler(onNodeEvent)

    self:init()
end

function PlayScene:onEnter()
    if Player.last_one == 1 then
        --初始化消息回调
        --g_EventManager:addEventListener(EVENT_WHO_START,handler(self,self.whoStart))  --谁先出牌
        self:whoStart()
    end
end

function PlayScene:onExit()
end

function PlayScene:init()
    self.changeCardTimes = 0
    self.myRoundOneCardNum = 1
    self.myRoundTwoCardNum = 1
    self.myRoundThreeCardNum = 1
    self.round = PlayScene.whatRound.one
    local center = self.csbLayer:getChildByName("center")
    PlayScene.middle = self.csbLayer:getChildByName("middle")
    local bottom = self.csbLayer:getChildByName("bottom")
    local back = self.csbLayer:getChildByName("back")
    local giveup_button = bottom:getChildByName("giveup")  --投降
    g_TouchEvent:new(back, function() self:back() end)
    g_TouchEvent:new(giveup_button, function() self:giveUp() end)

    local b_mySelf = bottom:getChildByName("mySelf")  --自己
    local b_other = bottom:getChildByName("player")  --对手
    PlayScene.mySelf_totalCardNum = b_mySelf:getChildByName("totalCardNum")  --自己三组总分
    PlayScene.other_totalCardNum = b_other:getChildByName("totalCardNum")    --对手三组总分
    PlayScene.mySelf_lastCardNum_node = b_mySelf:getChildByName("lastCardNum")  --自己剩余卡牌数
    PlayScene.other_lastCardNum_node = b_other:getChildByName("lastCardNum")    --对手剩余卡牌
    PlayScene.myName = b_mySelf:getChildByName("name")      --自己称号
    PlayScene.otherName = b_other:getChildByName("name")   --对手称号

    PlayScene.myName:setString(Player.name)
    PlayScene.otherName:setString(OtherPlayer.name)

    PlayScene.mySelf_lastCardNum_node:setString(PlayScene.totalCardNum)
    PlayScene.other_lastCardNum_node:setString(PlayScene.totalCardNum)

    PlayScene.mySelf_lastCardNum = PlayScene.totalCardNum
    PlayScene.other_lastCardNum = PlayScene.totalCardNum

    local mySelf = center:getChildByName("mySelf")  --自己
    local other = center:getChildByName("other")    --对手
    self.typeOne = mySelf:getChildByName("typeOne")
    self.typeTwo = mySelf:getChildByName("typeTwo")
    self.typeThree = mySelf:getChildByName("typeThree")

    PlayScene.otherTypeOne = other:getChildByName("typeOne")
    PlayScene.otherTypeTwo = other:getChildByName("typeTwo")
    PlayScene.otherTypeThree = other:getChildByName("typeThree")

    g_EventManager:addEventListener(EVENT_RESET_DATA_AFTER_GIVEUP,handler(self,self.resetData))  --放弃后重置数据

    PlayScene.mySelf_num1 = center:getChildByName("mySelf_num1")  --自己
    PlayScene.mySelf_num2 = center:getChildByName("mySelf_num2")  --自己
    PlayScene.mySelf_num3 = center:getChildByName("mySelf_num3")  --自己
    
    PlayScene.other_num1 = center:getChildByName("other_num1")  --
    PlayScene.other_num2 = center:getChildByName("other_num2")  --
    PlayScene.other_num3 = center:getChildByName("other_num3")  --

    PlayScene.mySelf_jewel1 = b_mySelf:getChildByName("jewel1")   --宝石
    PlayScene.mySelf_jewel2 = b_mySelf:getChildByName("jewel2")

    PlayScene.other_jewel1 = b_other:getChildByName("jewel1")
    PlayScene.other_jewel2 = b_other:getChildByName("jewel2")

    local cardListNode = self.csbLayer:getChildByName("cardList")
    self.listView = cardListNode:getChildByName("ListView")
    self.shieldLayer = cardListNode:getChildByName("shieldLayer")
    self.listView_show = self.shieldLayer:getChildByName("ListView_show")
    local begin = self.shieldLayer:getChildByName("begin")
    g_TouchEvent:new(begin, function() self:playGameStraightly() end)

    self.listView:removeAllChildren()
    self.listView_show:removeAllChildren()

    math.randomseed(os.time())
    local cardListId, noHaveList = getCardsId()
    self.noHaveList = noHaveList
    local allCardList = cardConfig
    local cardList = {}
    for i = 1, #cardListId do
        local child = allCardList[cardListId[i]]
        table.insert(cardList, child)
    end

    for i = 1, PlayScene.totalCardNum do
        local child = cardList[i]
        local pItemLayout = ccui.Layout:create()
        pItemLayout:setContentSize(75, 125)

        local node = cc.Sprite:create(child.img)
        node:setPosition(cc.p(pItemLayout:getContentSize().width / 2.0, pItemLayout:getContentSize().height / 2.0 - 5))
        
        pItemLayout:addChild(node)
        self.listView:pushBackCustomItem(pItemLayout)
        pItemLayout:setTag(child.id)

        g_TouchEvent:new(node, function() self:clickCard(child) end, g_TouchEvent.handlerType.SCROLL)
    end

    for i = 1, PlayScene.totalCardNum do
        local child = cardList[i]
        local pItemLayout = ccui.Layout:create()
        pItemLayout:setContentSize(130, 200)

        local node = cc.Sprite:create(child.img)
        node:setScale(1.7)
        node:setPosition(cc.p(pItemLayout:getContentSize().width / 2.0, pItemLayout:getContentSize().height / 2.0))
        
        pItemLayout:addChild(node)
        self.listView_show:pushBackCustomItem(pItemLayout)
        pItemLayout:setTag(child.id)

        g_TouchEvent:new(node, function() self:changeCard(child.id) end, g_TouchEvent.handlerType.SCROLL)
    end
end

--重抽卡牌，添加至列表
function PlayScene:addCard(child)
    local pItemLayout = ccui.Layout:create()
    pItemLayout:setContentSize(75, 125)

    local node = cc.Sprite:create(child.img)
    node:setPosition(cc.p(pItemLayout:getContentSize().width / 2.0, pItemLayout:getContentSize().height / 2.0 - 5))
        
    pItemLayout:addChild(node)
    self.listView:pushBackCustomItem(pItemLayout)
    pItemLayout:setTag(child.id)

    g_TouchEvent:new(node, function() self:clickCard(child) end, g_TouchEvent.handlerType.SCROLL)
end

--不重抽卡牌，直接开始游戏
function PlayScene:playGameStraightly()
    self.shieldLayer:removeFromParent()
end

--重抽卡牌
function PlayScene:changeCard(id)
    if self.changeCardTimes == 2 then
        self:playGameStraightly()
        return
    end
    self.changeCardTimes = self.changeCardTimes + 1
    self.listView_show:removeChildByTag(id)
    self.listView:removeChildByTag(id)

    local allCardList = cardConfig
    local randomId = math.random(1, #self.noHaveList)
    local child = allCardList[self.noHaveList[randomId]]
    self:addCard(child)
    table.remove(self.noHaveList, randomId)

    if self.changeCardTimes == 2 then
        self:playGameStraightly()
    end
end

--点击卡牌出牌
function PlayScene:clickCard(child)
    if not PlayScene.myTurn then
        return
    end

    PlayScene.mySelf_lastCardNum = PlayScene.mySelf_lastCardNum -1
    PlayScene.mySelf_lastCardNum_node:setString(PlayScene.mySelf_lastCardNum)

    local data = {type='putCard', to_client_id='all', content=child.id .. '', time=os.time() .. '', cardType=child.attack_type .. '', cardPower = child.power .. ''} 
    Net:sendMsg(data)

    self:afterClickCard(child, true)
end

--出牌后update
function PlayScene:afterClickCard(child, myself)
    if myself then
        if child.attack_type == PlayScene.attack_type.one then
            self:pushCard(child.id, self.typeOne)
        elseif child.attack_type == PlayScene.attack_type.two then
            self:pushCard(child.id, self.typeTwo)
        elseif child.attack_type == PlayScene.attack_type.three then
            self:pushCard(child.id, self.typeThree)
        end
        self.listView:removeChildByTag(child.id)
    else
        if child.attack_type == PlayScene.attack_type.one then
            self:pushCard(child.id, PlayScene.otherTypeOne)
        elseif child.attack_type == PlayScene.attack_type.two then
            self:pushCard(child.id, PlayScene.otherTypeTwo)
        elseif child.attack_type == PlayScene.attack_type.three then
            self:pushCard(child.id, PlayScene.otherTypeThree)
        end
    end
end

--出牌
function PlayScene:pushCard(i, parent)
    local cardInfo = cardConfig[i]
    local card = cc.Sprite:create(cardInfo.img)
    parent:addChild(card)

    --card:runAction(cc.MoveTo:create(1, PlayScene.middle:getPosition()))

    local children = parent:getChildren()

    if #children == 1 then
        card:setPosition(0, 0)
    else
        local child_last = children[#children - 1]
        local pos_x, pos_y = child_last:getPosition()
        card:setPosition(pos_x + 100, pos_y)

        for i = 1, #children do
            local child = children[i]
            local pos_x, pos_y = child:getPosition()
            child:setPositionX(pos_x - 50)
        end
    end
end

--出牌后回调
function PlayScene:putCardRec(data)
    local cardType = tonumber(data.cardType)
    local cardPower = tonumber(data.cardPower)
    local client_id = data.from_client_id
    local cardId = data.content
    local whose_turn = data.whose_turn

    if whose_turn == Player.id then  --代表是对手出了牌,轮到自己了
        if PlayScene.mySelf_lastCardNum > 0 then
            addTipLabel("轮到你了！")
        end
        
        PlayScene.myTurn = true
        PlayScene.other_lastCardNum = PlayScene.other_lastCardNum - 1
        PlayScene.other_lastCardNum_node:setString(PlayScene.other_lastCardNum)
        print("玩家"..data.from_client_name .. "出了卡牌" .. data.content)

        local child = {id = tonumber(cardId), attack_type = tonumber(cardType)}
        self:afterClickCard(child, false)

        if cardType == PlayScene.attack_type.one then
            PlayScene.other_num1:setString(tonumber(PlayScene.other_num1:getString()) + cardPower)
        elseif cardType == PlayScene.attack_type.two then
            PlayScene.other_num2:setString(tonumber(PlayScene.other_num2:getString()) + cardPower)
        else
            PlayScene.other_num3:setString(tonumber(PlayScene.other_num3:getString()) + cardPower)
        end
        self:countOtherTotalNum()
    else
        if PlayScene.other_lastCardNum > 0 then
            addTipLabel("轮到对手！")
        end
        
        PlayScene.myTurn = false
        print("我出了卡牌" .. data.content .. "，类型为" .. cardType)
        if cardType == PlayScene.attack_type.one then
            PlayScene.mySelf_num1:setString(tonumber(PlayScene.mySelf_num1:getString()) + cardPower)
        elseif cardType == PlayScene.attack_type.two then
            PlayScene.mySelf_num2:setString(tonumber(PlayScene.mySelf_num2:getString()) + cardPower)
        else
            PlayScene.mySelf_num3:setString(tonumber(PlayScene.mySelf_num3:getString()) + cardPower)
        end
        self:countMyTotalNum()
    end

    if PlayScene.mySelf_lastCardNum == 0 and PlayScene.other_lastCardNum == 0 then
        self:gameOver(PlayScene.overType.NOCARDS)
    end
end

--返回
function PlayScene:back()
    self:getApp():enterScene("MainScene","FADE",0.1)
end

--计算自己所得分数
function PlayScene:countMyTotalNum()
    local totalNum = tonumber(PlayScene.mySelf_num1:getString()) + tonumber(PlayScene.mySelf_num2:getString())
    + tonumber(PlayScene.mySelf_num3:getString())

    PlayScene.mySelf_totalCardNum:setString(totalNum)
end

--计算对手所得分数
function PlayScene:countOtherTotalNum()
    local totalNum = tonumber(PlayScene.other_num1:getString()) + tonumber(PlayScene.other_num2:getString())
    + tonumber(PlayScene.other_num3:getString())

    PlayScene.other_totalCardNum:setString(totalNum)
end

--有对手加入后更新对手信息
function PlayScene:playerJoin(name)
    if PlayScene.otherName then
        PlayScene.otherName:setString(name)
    end
end

--谁先出牌
function PlayScene:whoStart()
    local data = {type='whoStart', to_client_id='all', time=os.time() .. ''} 
    Net:sendMsg(data)
end

--谁先出牌回调
function PlayScene:whoStartRec(data)
    PlayScene.gameState = PlayScene.gameStateEnu.BEGIN
    local who_start = data.who_start
    if who_start ~= "" then
        if who_start == Player.id then
            PlayScene.myTurn = true
            addTipLabel("我先出牌")
        else
            addTipLabel("对方先出牌")
            PlayScene.myTurn = false
        end
    else
        cclog("who_start is null")
    end
end

--游戏开始
function PlayScene:begin()
    local data = {type='begin', to_client_id='all', time=os.time() .. ''} 
    Net:sendMsg(data)
end

--游戏开始回调
function PlayScene:beginRec(data)
    addTipLabel("游戏开始！")
end

--投降
function PlayScene:giveUp()
    if PlayScene.gameState == PlayScene.gameStateEnu.END or PlayScene.gameState == PlayScene.gameStateEnu.READY then
        --return
    end

    local data = {type='giveUp', to_client_id='all', m_totalCardNum=PlayScene.mySelf_totalCardNum:getString() .. '', 
                 o_totalCardNum=PlayScene.other_totalCardNum:getString() .. '', time=os.time() .. '', mySelf_jewel = Player.jewel_num .. '', other_jewel = OtherPlayer.jewel_num .. ''} 

    --Player.jewel_num = Player.jewel_num - 1
    --setWidgetAllGray(PlayScene.mySelf_jewel2)

--    if Player.jewel_num == 1 then
--        self:gameOver(PlayScene.overType.GIVERUP)
--    elseif Player.jewel_num > 1 then
--        local data = {type='giveUp', to_client_id='all', time=os.time() .. ''} 
--        Net:sendMsg(data)


--    end
    Net:sendMsg(data)
end

--投降回调
function PlayScene:giveUpRec(data)
    local from_client_id = data.from_client_id
    local from_client_name = data.from_client_name
    local round = data.round
    local winer_round = data.winer_round
    local winer = data.winer

    if winer ~= 0 then
        if winer == Player.id then
            addTipLabel("你赢了！")
        else
            addTipLabel("你输了！")
        end
    elseif winer_round ~= 0 then
        if winer_round == Player.id then
            addTipLabel("你赢了这回合！")
        else
            addTipLabel("你输了这回合！")
        end
    else
        if from_client_id ~= Player.id then
            addTipLabel("对方弃权，你可以继续出牌或者弃权！", nil, 4)
        end
    end

    if from_client_id == Player.id then
        --addTipLabel("我放弃了该回合")
        PlayScene.gameState = PlayScene.gameStateEnu.GIVEUP
        Player.fight_state = PlayScene.gameStateEnu.GIVEUP
    else
        --addTipLabel("对方放弃了该回合")
        OtherPlayer.fight_state = PlayScene.gameStateEnu.GIVEUP

--        if OtherPlayer.jewel_num > 1 then
--            OtherPlayer.jewel_num = OtherPlayer.jewel_num - 1
--            setWidgetAllGray(PlayScene.other_jewel2)
--        end
    end

    --双方都弃权了
--    if Player.fight_state == PlayScene.gameStateEnu.GIVEUP and OtherPlayer.fight_state == PlayScene.gameStateEnu.GIVEUP then
--        self:gameOver(PlayScene.overType.GIVEUP)
--    end
--    g_EventManager:dispatchEvent(EVENT_RESET_DATA_AFTER_GIVEUP)
end

--游戏结束
function PlayScene:gameOver(ntype)
    local data = {type='gameOver', ntype=ntype .. '', to_client_id='all', m_totalCardNum=PlayScene.mySelf_totalCardNum:getString() .. '', 
                 o_totalCardNum=PlayScene.other_totalCardNum:getString() .. '', time=os.time() .. '', mySelf_jewel = Player.jewel_num .. '', other_jewel = OtherPlayer.jewel_num .. ''} 

    Net:sendMsg(data)
end

--游戏结束回调
function PlayScene:gameOverRec(data)
    PlayScene.gameState = PlayScene.gameStateEnu.END
    local ntype = tonumber(data.ntype)
    if ntype == PlayScene.overType.GIVERUP then
        local loser = data.loser
        if loser == Player.id then
            PlayScene.gameState = PlayScene.gameStateEnu.GIVEUP
            --addTipLabel("你输了！")
        else
            addTipLabel("对方已弃权！")
        end
    elseif ntype == PlayScene.overType.NOCARDS then
        local winer = data.winer
        if winer == 0 then
            print("平局")
            addTipLabel("平局")
        elseif winer == Player.id then
            print("你赢了")
            addTipLabel("你赢了")
        else
            print("你输了")
            addTipLabel("你输了")
        end
    end
end

--放弃后 数值归零
function PlayScene:resetData()
    PlayScene.mySelf_num1:setString("0")
    PlayScene.mySelf_num2:setString("0")
    PlayScene.mySelf_num3:setString("0")

    PlayScene.other_num1:setString("0")
    PlayScene.other_num2:setString("0")
    PlayScene.other_num3:setString("0")

    PlayScene.mySelf_totalCardNum:setString("0")
    PlayScene.other_totalCardNum:setString("0")

    self.typeOne:removeAllChildren()
    self.typeTwo:removeAllChildren()
    self.typeThree:removeAllChildren()

    PlayScene.otherTypeOne:removeAllChildren()
    PlayScene.otherTypeTwo:removeAllChildren()
    PlayScene.otherTypeThree:removeAllChildren()
end

return PlayScene