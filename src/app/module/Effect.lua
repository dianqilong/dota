--
-- Author: yjun
-- Date: 2014-09-25 18:18:55
--
local scheduler = require("framework.scheduler")

local Effect = class("Effect")

function Effect:ctor()
	self.effectList = {}
end

function Effect:createEffect(effectID, master, target, ...)
	local effectInfo = DataManager:getEffectConf(effectID)
	if effectInfo == nil then
		print("effect config not exit")
		return nil
	end

	local switch = {
		[1] = function(effectInfo, master, target) return self:ptpLineEffect(effectInfo, master, target) end,

		[2] = function(...) return self:ptpLineEffect(unpack(...)) end,

		[3] = function(...) return self:ptpLineEffect(unpack(...)) end,

		[4] = function(effectInfo, master, target) return self:PositionEffect(effectInfo, master, target) end,

		[5] = function(effectInfo, master, target) return self:BuffEffect(effectInfo, master, target) end
	}
	-- 特效事件分发
	local func = switch[effectInfo.Type]
	if func then
		return func(effectInfo, master, target)
	else
		print("no Effect function")
		return nil
	end

	return nil
end

-- 删除特效
function Effect:removeEffect(effectID, master)
	local key = master:getIndex() .. effectID;
	local effect = DataManager.effect.effectList[key]
	if effect == nil then
		-- print(effectID .. " not exist")
		return
	end

	effect:removeSelf()
	DataManager.effect.effectList[key] = nil
end

-- 点到点的线性特效
function Effect:ptpLineEffect(effectInfo, master, target, ...)
	self:removeEffect(effectInfo.ID, master)
	-- 准备特效文件
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(effectInfo.ConfigName)
	-- 创建特效，添加到场景
	local effect = ccs.Armature:create(effectInfo.ArmatureName)
	-- 播放完成后自动删除
	if effectInfo.C_Remove > 0 then
		local function animationEvent(armatureBack,movementType,movementID)
			if movementType == ccs.MovementEventType.complete then				
				effect:removeSelf()
			end
		end

		effect:getAnimation():setMovementEventCallFunc(animationEvent)
	else
		-- 记录特效到特效列表
		DataManager.effect.effectList[master:getIndex() .. effectInfo.ID] = effect
	end
	local scene = display.getRunningScene()
	scene:addChild(effect)
	-- 调整特效位置和角度
	effect:setLocalZOrder(master:getLocalZOrder())
	local masterPos = cc.p(master:getPosition())
	masterPos.y = masterPos.y + 50
	local targetPos = cc.p(target:getPosition())
	targetPos.y = targetPos.y + 50
	local distance = cc.pGetDistance(masterPos, targetPos)
	effect:setScaleX(distance/effect:getContentSize().width)
	if effectInfo.ScaleY ~= 0 then
		effect:setScaleY(effectInfo.ScaleY)
	end
	local angle = cc.pToAngleSelf(cc.pSub(targetPos, masterPos))
	effect:setPosition(cc.pMidpoint(masterPos, targetPos))
	effect:setRotation(-math.deg(angle))
	effect:getAnimation():play(effectInfo.AnimationName)

	return effect
end

-- 指定位置的特效
function Effect:PositionEffect(effectInfo, master, target)
	-- 准备特效文件
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(effectInfo.ConfigName)

	-- 创建特效，添加到场景
	local effect = ccs.Armature:create(effectInfo.ArmatureName)

	-- 播放完成后自动删除
	local function animationEvent(armatureBack,movementType,movementID)
		if movementType == ccs.MovementEventType.complete then				
			effect:removeSelf()
		end
	end

	effect:getAnimation():setMovementEventCallFunc(animationEvent)

	local scene = display.getRunningScene()
	scene:addChild(effect)
	effect:setLocalZOrder(master:getLocalZOrder()-1)
	local targetPos = cc.p(master:getPosition())
	local offset = 100

	if master.armature:getScaleX() < 0 then
		effect:setScaleX(-1)
		offset = -100
	end

	effect:setPosition(targetPos.x + offset, targetPos.y)
	effect:getAnimation():play(effectInfo.AnimationName)

	return effect
end

-- buff特效
function Effect:BuffEffect(effectInfo, master, target)
	self:removeEffect(effectInfo.ID, target)
	-- 准备特效文件
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(effectInfo.ConfigName)

	-- 创建特效，添加到对象
	local effect = ccs.Armature:create(effectInfo.ArmatureName)
	target:addChild(effect)

	local size = target.armature:getContentSize()
    size.width = size.width * math.abs(target.armature:getScaleX())
    size.height = size.height * math.abs(target.armature:getScaleY())
    
    effect:setPosition(0, size.height)
    effect:getAnimation():play(effectInfo.AnimationName)
	-- 记录特效到特效列表
	DataManager.effect.effectList[target:getIndex() .. effectInfo.ID] = effect

	return effect
end

-- 头顶飘字
function Effect:HeadFlyText(master, content)
	local label = cc.ui.UILabel.new({
		UILabelType = 1, 
		text = -content, 
		font = "font/red_digits.fnt",
		align = cc.ui.UILabel.TEXT_ALIGN_CENTER})	
	label:setAnchorPoint(cc.p(0.5, 0.5))
	label:setScale(0.1)
	display.getRunningScene():addChild(label)

	label:setPosition(cc.p(master:getPositionX(), master:getPositionY() + 150))
	label:setLocalZOrder(master:getLocalZOrder())

	local action = transition.sequence(
		{cc.ScaleTo:create(0.2, 0.8),
		cc.MoveTo:create(1, cc.p(label:getPositionX(), label:getPositionY() + 80)),
		cc.CallFunc:create(function() label:removeSelf() end)})
	label:runAction(action)
end

return Effect