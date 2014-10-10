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

		[4] = function(...) self:ptpLineEffect(unpack(...)) end
	}
	-- 特效事件分发
	local func = switch[tonumber(effectInfo.Type)]
	if func then
		func(effectInfo, master, target)
	else
		print("no Effect function")
		return
	end



	-- if DataManager:getEffectData(effectID) == nil then
	-- 	print("effect not exit")
	-- 	return
	-- end
	-- cc.FileUtils:getInstance():addSearchPath("res/effect/")
	-- display.addSpriteFrames("redLightAnimation0.plist", "redLightAnimation0.png") --添加帧缓存
	-- local sp = display.newSprite("#red_light_1.png", display.cx, display.cy)
	-- display.getRunningScene():addChild(sp)
	-- local frames = display.newFrames("red_light_%d.png", 1, 8)
	-- local animation = display.newAnimation(frames, 0.5/8)
	-- sp:setScaleX(display.width/sp:getContentSize().width)
	-- sp:playAnimationOnce(animation, true)


	-- if self.effect then
	-- 	self.effect:removeSelf()
	-- end

	-- self.effect = ccs.Armature:create("blueLightAnimation")
	-- local scene = display.getRunningScene()
	-- scene:addChild(self.effect)
	-- self.effect:setLocalZOrder(10000)
	-- local heroPos = cc.p(scene.hero:getPosition())
	-- heroPos.y = heroPos.y + 50
	-- local enemyPos = cc.p(scene.enemy:getPosition())
	-- enemyPos.y = enemyPos.y - 30
	-- local distance = cc.pGetDistance(heroPos, enemyPos)	
	-- self.effect:setScaleX(distance/self.effect:getContentSize().width)
	-- self.effect:setScaleY(0.5)
	-- local angle = cc.pToAngleSelf(cc.pSub(enemyPos, heroPos))
	-- print("angle = " .. angle)
	-- self.effect:setPosition(cc.pMidpoint(heroPos, enemyPos))
	-- self.effect:setRotation(-math.deg(angle))
	-- self.effect:getAnimation():play("stealmp")

end

-- 点到点的线性特效
function Effect:ptpLineEffect(effectInfo, master, target, ...)
	self:removeEffect(effectInfo.ID, master)
	-- 准备特效文件
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(effectInfo.ConfigName)
	-- 创建特效，添加到场景
	local effect = ccs.Armature:create(effectInfo.ArmatureName)
	-- 播放完成后自动删除
	if tonumber(effectInfo.C_Remove) > 0 then
		local function animationEvent(armatureBack,movementType,movementID)
			if movementType == ccs.MovementEventType.complete then				
				effect:removeSelf()
			end
		end

		effect:getAnimation():setMovementEventCallFunc(animationEvent)
	else
		-- 记录特效到特效列表
		DataManager.effect.effectList[master:getID() .."_" .. effectInfo.ID] = effect
	end
	local scene = display.getRunningScene()
	scene:addChild(effect)
	-- 调整特效位置和角度
	effect:setLocalZOrder(master:getLocalZOrder())
	local masterPos = cc.p(master:getPosition())
	masterPos.y = masterPos.y + 50
	local targetPos = cc.p(target:getPosition())
	targetPos.y = targetPos.y - 30
	local distance = cc.pGetDistance(masterPos, targetPos)
	effect:setScaleX(distance/effect:getContentSize().width)
	if tonumber(effectInfo.ScaleY) ~= 0 then
		effect:setScaleY(effectInfo.ScaleY)
	end
	local angle = cc.pToAngleSelf(cc.pSub(targetPos, masterPos))
	effect:setPosition(cc.pMidpoint(masterPos, targetPos))
	effect:setRotation(-math.deg(angle))
	effect:getAnimation():play(effectInfo.AnimationName)
end

function Effect:removeEffect(effectID, master)
	local effect = DataManager.effect.effectList[master:getID() .."_" .. effectID]
	if effect == nil then
		return
	end

	effect:removeSelf()
end

return Effect