--屏蔽层
g_NoTouchLayer = class("g_NoTouchLayer")

--param func
function g_NoTouchLayer:ctor(...)
	local function onTouchBegan(touch, event)
		local target = event:getCurrentTarget()
		if g_Base:isVisible(target) == false then
		    return false
		end
		if self.callBackFunc ~= nil then
			performWithDelay(self.layer,function ()
				self.callBackFunc(touch, event)
			end,0.01)
			--self.callBackFunc(touch, event)
		end
	    return true
	end 
	self.callBackFunc = nil
	local arg = {...}
	if arg[2] ~= nil then self.callBackFunc = arg[2] end
	self.layer = cc.LayerColor:create()
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	local eventDispatcher = self.layer:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.layer)
end