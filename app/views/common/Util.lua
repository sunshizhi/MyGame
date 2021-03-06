--region Util.lua
--Author : ssz
--Date   : 2016/9/11
--
--------------------UI
--弹出漂浮的提示文字
function addTipLabel(cont , layer,time)
	cclog("提示文字"..cont)
	time=time or 2
	
	--文本
    local exitLabel = cc.LabelTTF:create(cont,"",32)
    exitLabel:setAnchorPoint(0.5,0.5)
    local txtsize=exitLabel:getContentSize()

    if not layer then
    	layer=cc.Director:getInstance():getRunningScene()
    end

    local sprbg = layer:getChildByTag(8989)
    if sprbg then
        sprbg:removeFromParent(true)
    end

    --缩放背景
    local sprbg=cc.Scale9Sprite:create("res/common/commontip_bg.png", cc.rect(20,20,20,20), cc.rect(0,0,0,0))
    local width=math.min(350,txtsize.width)
    width=math.max(350,txtsize.width)
    
    sprbg:setContentSize(cc.size(width, 98))
	sprbg:setAnchorPoint(0.5,0.5)

    sprbg:addChild(exitLabel)
    exitLabel:setPosition(width/2,98/2)

    layer:addChild(sprbg,1000, 8989)

    sprbg:setPosition(display.cx,display.height*0.7)

    local move    = CCMoveTo:create(1, cc.p(display.cx,display.height*0.68))
    local jump    = CCEaseBounceOut:create(move)
    local fadeout = CCFadeOut:create(time)
    local actremove=cc.CallFunc:create(function ( ... )
       layer:removeChild(sprbg)
    end)

    sprbg:runAction(CCSequence:create(jump,fadeout,actremove))
end

function tableToString(t)
	local retstr= "{"

	local i = 1
	for key,value in pairs(t) do
	    local signal = ","
	    if i==1 then
          signal = ""
		end

		if key==i then
			-- 不加键值

			retstr = retstr..signal..tostringEx(value)
			i = i+1
		else
			if type(key)=='number' then
				retstr = retstr..signal..'['..key.."]="..tostringEx(value)
			else
				retstr = retstr..signal..key.."="..tostringEx(value)
			end
			
			i = -1
		end
	end

 	retstr = retstr.."}"
 	return retstr
end

--延迟执行 time:到第几秒执行 end_t:循环多久
function delayCallFunc(time, end_t, func)
    local t = os.time()
    while os.time() - t < end_t do
        if os.time() - t == time then
            func()
            break
        end
    end
end

function setWidgetAllGray(node,bNor)
	local state=1

	if bNor then
		state=0
	end

    if tolua.type(node) == "ccui.Text" then
       node:setColor(cc.c3b(191,191,191))
       return
    end

	node:getVirtualRenderer():setState(state)
	cclog(node:getName().." state=%d",state)

	local children=node:getChildren()
	for k,v in pairs(children) do
        setWidgetAllGray(v,bNor)
	end
end

--获取卡牌id
function getCardsId()
    local N = 22
	local array = {}
    local noHaveList = {}
    local rs = {}
	for i = 1 , N do
		array[i] = i
	end

	math.randomseed(os.time())
	for i = 1 , 10 do
		local j = math.random(N - i + 1) + i - 1;
		array[i],array[j] = array[j],array[i]
	end

	for i = 1 , 10 do
        table.insert(rs, array[i])
	end

    for j = 1 , N do
        local noHave = true
        local res = array[j]
        for i = 1, 10 do
            local child = rs[i]
            if child == res then
                noHave = false
            end
        end
        if noHave then
            table.insert(noHaveList, res)
        end
    end

    return rs, noHaveList
end