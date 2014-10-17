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
		return
	end

	local switch = {
		[1] = function(effectInfo, master, target) self:ptpLineEffect(effectInfo, master, target) end,

		[2] = function(...) self:ptpLineEffect(unpack(...)) end,

		[3] = function(...) self:ptpLineEffect(unpack(...)) end,

		[4] = function(effectInfo, master, target) self:PositionEffect(effectInfo, master, target) end
	}
	-- 特效事件分发
	local func = switch[effectInfo.Type]
	if func then
		func(effectInfo, master, target)
	else
		print("no Effect function")
		return
	end
end

-- 删除特效
function Effect:removeEffect(effectID, master)
	local key = master:getID() .. effectID .. master.side;
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
		DataManager.effect.effectList[master:getID() .. effectInfo.ID .. master.side] = effect
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
	effect:setLocalZOrder(master:getLocalZOrder())
	local targetPos = cc.p(master:getPosition())
	local offset = 100

	if master.armature:getScaleX() < 0 then
		effect:setScaleX(-1)
		offset = -100
	end

	effect:setPosition(targetPos.x+offset, targetPos.y)
	effect:getAnimation():play(effectInfo.AnimationName)
end

return Effect