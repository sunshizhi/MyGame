PlayScene = class("PlayScene", cc.load("mvc").ViewBase)
PlayScene.RESOURCE_FILENAME = "PlayScene.csb"

PlayScene.whatRound = {
    one = 1,
    two = 2,
    three = 3
}

PlayScene.cardType = {
    one = 1,
    two = 2,
    three = 3
}

PlayScene.totalCardNum = 10

function PlayScene:onCreate()
    self.csbLayer = self:getResourceNode()
    self:init()
end

function PlayScene:init()
    self.myRoundOneCardNum = 1
    self.myRoundTwoCardNum = 1
    self.myRoundThreeCardNum = 1
    self.round = PlayScene.whatRound.one
    local center = self.csbLayer:getChildByName("center")
    local bottom = self.csbLayer:getChildByName("bottom")
    local back = self.csbLayer:getChildByName("back")
    g_TouchEvent:new(back, function() self:back() end)

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

    PlayScene.mySelf_num1 = center:getChildByName("mySelf_num1")  --自己
    PlayScene.mySelf_num2 = center:getChildByName("mySelf_num2")  --自己
    PlayScene.mySelf_num3 = center:getChildByName("mySelf_num3")  --自己
    
    PlayScene.other_num1 = center:getChildByName("other_num1")  --
    PlayScene.other_num2 = center:getChildByName("other_num2")  --
    PlayScene.other_num3 = center:getChildByName("other_num3")  --

    local cardListNode = self.csbLayer:getChildByName("cardList")
    self.listView = cardListNode:getChildByName("ListView")
    self.listView:removeAllChildren()

    math.randomseed(os.time())
    local cardList = {}
    for i = 1, PlayScene.totalCardNum do
        local child = {}
        child.id = i
        child.type = math.random(1,3)
        child.power = child.type
        child.img = "res/card/card.png"
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
end

--点击卡牌出牌
function PlayScene:clickCard(child)
    addTipLabel("开始游戏")
    PlayScene.mySelf_lastCardNum = PlayScene.mySelf_lastCardNum -1
    PlayScene.mySelf_lastCardNum_node:setString(PlayScene.mySelf_lastCardNum)

    if PlayScene.mySelf_lastCardNum == 0 and PlayScene.other_lastCardNum == 0 then
        self:overRound()
    else
        local data = {type='putCard', to_client_id='all', content=child.id .. '', time=os.time() .. '', cardType=child.type .. '', cardPower = child.power .. ''} 
        Net:sendMsg(data)

        self:afterClickCard(child, true)
    end
end

--出牌后update
function PlayScene:afterClickCard(child, myself)
    if myself then
        if child.type == PlayScene.cardType.one then
            self:pushCard(child.id, self.typeOne)
        elseif child.type == PlayScene.cardType.two then
            self:pushCard(child.id, self.typeTwo)
        elseif child.type == PlayScene.cardType.three then
            self:pushCard(child.id, self.typeThree)
        end
        self.listView:removeChildByTag(child.id)
    else
        if child.type == PlayScene.cardType.one then
            self:pushCard(child.id, PlayScene.otherTypeOne)
        elseif child.type == PlayScene.cardType.two then
            self:pushCard(child.id, PlayScene.otherTypeTwo)
        elseif child.type == PlayScene.cardType.three then
            self:pushCard(child.id, PlayScene.otherTypeThree)
        end
    end
end

--出牌
function PlayScene:pushCard(i, parent)
    local card = cc.Sprite:create("play/mainCard.png")
    parent:addChild(card)

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
    if client_id ~= Player.id then  --代表是对手出了牌
        PlayScene.other_lastCardNum = PlayScene.other_lastCardNum - 1
        PlayScene.other_lastCardNum_node:setString(PlayScene.other_lastCardNum)
        print("玩家"..data.from_client_name .. "出了卡牌" .. data.content)

        local child = {id = tonumber(cardId), type = tonumber(cardType)}
        self:afterClickCard(child, false)

        if cardType == PlayScene.cardType.one then
            PlayScene.other_num1:setString(tonumber(PlayScene.other_num1:getString()) + cardPower)
        elseif cardType == PlayScene.cardType.two then
            PlayScene.other_num2:setString(tonumber(PlayScene.other_num2:getString()) + cardPower)
        else
            PlayScene.other_num3:setString(tonumber(PlayScene.other_num3:getString()) + cardPower)
        end
        self:countOtherTotalNum()
    else
        print("我出了卡牌" .. data.content .. "，类型为" .. cardType)
        if cardType == PlayScene.cardType.one then
            PlayScene.mySelf_num1:setString(tonumber(PlayScene.mySelf_num1:getString()) + cardPower)
        elseif cardType == PlayScene.cardType.two then
            PlayScene.mySelf_num2:setString(tonumber(PlayScene.mySelf_num2:getString()) + cardPower)
        else
            PlayScene.mySelf_num3:setString(tonumber(PlayScene.mySelf_num3:getString()) + cardPower)
        end
        self:countMyTotalNum()
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

--回合结束
function PlayScene:overRound()
    local data = {type='overRound', to_client_id='all', m_totalCardNum=PlayScene.mySelf_totalCardNum:getString() .. '', 
    o_totalCardNum=PlayScene.other_totalCardNum:getString() .. '', time=os.time() .. ''} 
    Net:sendMsg(data)
end

--回合结束回调
function PlayScene:overRoundRec(data)
    local winer = data.winer
    if winer == 0 then
        print("平局")
        addTipLabel("平局")
    elseif winer == Player.id then
        print("这回合我赢了")
        addTipLabel("这回合我赢了")
    elseif winer == "" then
        print("这回合我赢了")
        addTipLabel("这回合我赢了")
    else
        print("这回合我输了")
        addTipLabel("这回合我输了")
    end
end

--有对手加入后更新对手信息
function PlayScene:playerJoin(name)
    PlayScene.otherName:setString(name)
end

return PlayScene
