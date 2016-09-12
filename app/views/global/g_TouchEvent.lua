--by sunshizhi 2015-8-26
--点击事件类，传递sprite过来，给其添加点击事件

g_TouchEvent = class("g_TouchEvent")

g_TouchEvent.touchType={
    BEGIN = "begin";
    MOVE = "moved";
    END = "ended";
}

g_TouchEvent.handlerType = 
{
    CLICK = 1;
    HANDLER = 2;
    SCROLL = 3;
}

--事件传参
g_TouchEvent.paramTab={
    event="";
    pos=nil;
    target=nil;
    delta=0;
}

function g_TouchEvent:ctor(...)
    self.arg = {...}
    self:addTouchEvent(self.arg[2], self.arg[3], self.arg[4], self.arg[5], self.arg[6], self.arg[7], self.arg[9], self.arg[10])
end

function g_TouchEvent:addTouchEvent(node_item, handler, handlerType, boundingBox, boundingBox_target, moveData, changeZOrder, changeZOrder2)
    local function onTouchBegan(touch, event)
        local target = event:getCurrentTarget()
--        if g_Base:isVisible(target) == false then
--            return false
--        end

        self.isClick = true
        local touchLocation = touch:getLocation()
        touchLocation = node_item:getParent():convertToNodeSpace(touchLocation);
        local rect;
        rect = node_item:getBoundingBox()
        if boundingBox ~= nil then
            print("boundingBox")
            rect = boundingBox
        end
        if boundingBox_target ~= nil then
            print("boundingBox_target")

            local boundingBox_t = boundingBox_target:getBoundingBox()
            local w_pos = boundingBox_target:getParent():convertToWorldSpace(cc.p(boundingBox_t.x,boundingBox_t.y))
            w_pos = node_item:getParent():convertToNodeSpace(cc.p(w_pos.x,w_pos.y));
            boundingBox_t.x = w_pos.x
            boundingBox_t.y = w_pos.y

            rect = boundingBox_t
        end

        if cc.rectContainsPoint(rect, touchLocation) then
            self.beginPos = touch:getLocation()
            local tab = clone(g_TouchEvent.paramTab)
            tab.event = g_TouchEvent.touchType.BEGIN
            tab.pos = touch:getLocation()
            tab.target = target
            if self.handlerType == g_TouchEvent.handlerType.HANDLER then self.handler(tab) end

            --anim
            --if self.handlerType == g_TouchEvent.handlerType.CLICK then
                if self.isAnim then
                    node_item:stopActionByTag(self.zoom_action_tag) 
                    local zoomAction = cc.ScaleTo:create(0.05, self.zoom_scaleX,self.zoom_scaleY);
                    node_item:runAction(zoomAction)
                    zoomAction:setTag(self.zoom_action_tag)
                end
            --end

            return true
        end
        return false
    end

    local function onTouchMoved(touch, event)
        if cc.pGetDistance(self.beginPos,touch:getLocation()) > self.clickOffset then
            self.isClick = false
        end
        local target = event:getCurrentTarget()
        local delta = touch:getDelta()
        local posX,posY = target:getPosition()

        local tab = clone(g_TouchEvent.paramTab)
        tab.event = g_TouchEvent.touchType.MOVE
        tab.pos = touch:getLocation()
        tab.target = target
        tab.delta = delta
        if self.handlerType == g_TouchEvent.handlerType.HANDLER then self.handler(tab) end
    end

    local function onTouchEnded(touch, event)
        local target = event:getCurrentTarget()
        local tab = clone(g_TouchEvent.paramTab)
        tab.event = g_TouchEvent.touchType.END
        tab.pos = touch:getLocation()
        tab.target = target
        if self.handlerType == g_TouchEvent.handlerType.HANDLER then 
            self.handler(tab)
        else
            if self.isAnim then
                node_item:stopActionByTag(self.zoom_action_tag)
                local zoomAction = cc.ScaleTo:create(0, self.scaleX,self.scaleY);
                node_item:runAction(zoomAction)
                zoomAction:setTag(self.zoom_action_tag)
            end

            if self.isClick == true then
                self.handler(tab)
            end
        end
        self.beginPos = nil
    end

    self.callBackFunc = nil
    if self.arg[8] ~= nil then self.callBackFunc = self.arg[8] end
    self.handlerType = g_TouchEvent.handlerType.CLICK
    self.swallow = true
    if handlerType then self.handlerType = handlerType end
    if handlerType == g_TouchEvent.handlerType.SCROLL then 
        self.swallow = false 
    end
    if(node_item == nil) then
        print("node_item is nil")
    end
    self.handler = handler
    self.isClick = true
    self.beginPos = nil
    self.clickOffset = 20
    self.scaleX = node_item:getScaleX()
    self.scaleY = node_item:getScaleY()
    self.zoom_scaleX = self.scaleX * 1.1
    self.zoom_scaleY = self.scaleY * 1.1
    self.zoom_action_tag = 77
    self.isAnim = true
    
    local listener1 = cc.EventListenerTouchOneByOne:create()
    listener1:setSwallowTouches(self.swallow)
    listener1:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener1:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener1:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, node_item)
end

return g_TouchEvent