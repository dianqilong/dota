--
-- Author: yjun
-- Date: 2014-09-24 16:37:46
--
local Buff = import("..module.Buff")
local Effect = import("..module.Effect")
local scheduler = require("framework.scheduler")

local Skill = class("Skill")

function Skill:ctor()
end

-- 使用技能
function Skill:UseSkill(master, skillID)
	local skillInfo = DataManager:getSkillConf(skillID)
	if skillInfo == nil then
		print("skill config not exit")
		return
	end

	local switch = {
		[1] = function(info, m) self:PointSkill(info, m) end,

		[2] = function(info, m) self:ptpLineEffect(info, m) end,

		[3] = function(info, m) self:ptpLineEffect(info, m) end,

		[4] = function(info, m) self:ptpLineEffect(info, m) end
	}
	-- 技能事件分发
	local func = switch[tonumber(skillInfo.Type)]
	if func then
		func(skillInfo, master)
	elseif self[skillID] then
		local func = self[skillID]
		self[skillID](self, skillInfo, master)
	else
		print("no Skill function")
		return
	end

	-- 记录当前技能id
	master.curSkill = skillID
end

-- 结束技能
function Skill:EndSkill(master)
	if master.curSkill == nil then
		return
	end

	local skillInfo = DataManager:getSkillConf(master.curSkill)
	if skillInfo == nil then
		print("skill config not exit")
		return
	end

	Effect:removeEffect(skillInfo.Effect, master)
	if master.skillhandle then
		scheduler.unscheduleGlobal(master.skillhandle)
		master.skillhandle = nil
	end

	master.curSkill = nil
end

-- 单体技能
function Skill:PointSkill(skillinfo, master)

	local function onPointSkillDamage()
		local scene = display.getRunningScene()
		-- 获取距离最近的敌人
		local enemy = scene.enemy

		-- 添加buff
		if skillinfo.AddBuff then
			Buff:AddBuff(master, skillinfo.AddBuff)
		end

		-- 计算伤害
		if skillinfo.EffProp then
			-- enemy:ReduceHp(skillinfo.Damage)
		end

		-- 播放特效
		if skillinfo.Effect then
			Effect:createEffect(skillinfo.Effect, master, enemy)
		end

		master:DelFrameCallBack("onDamageEvent")
	end

	if skillinfo.PreAction then
		master:AddFrameCallBack("onDamageEvent", onPointSkillDamage)
		master:DoAttack()
	else
		onPointSkillDamage()
	end
end

-- 抽蓝
function Skill:s_stealmp(skillinfo, master)
	local function onDamage()
		master:DelFrameCallBack("onDamageEvent")
		local scene = display.getRunningScene()
		-- 获取距离最近的敌人
		local enemy = scene.enemy

		-- 添加buff
		if skillinfo.AddBuff then
			Buff:AddBuff(master, skillinfo.AddBuff)
		end

		-- 计算伤害
		if skillinfo.EffProp then
			-- enemy:ReduceHp(skillinfo.Damage)
		end

		-- 播放特效
		if skillinfo.Effect then
			Effect:createEffect(skillinfo.Effect, master, enemy)
		end

		local function skillEnd()
			-- Effect:removeEffect(skillinfo.Effect, master)
			master:doEvent("stop")
		end

		if skillinfo.DurationTime and tonumber(skillinfo.DurationTime) > 0 then
			master.skillhandle = scheduler.performWithDelayGlobal(skillEnd, skillinfo.DurationTime)
		end
	end

	if skillinfo.PreAction then
		master:AddFrameCallBack("onDamageEvent", onDamage)
		master:DoMagic()
	else
		onDamage()
	end
end

-- 穿刺
function Skill:s_puncture(skillinfo, master)
	local function onDamage()
		local scene = display.getRunningScene()
		-- 获取距离最近的敌人
		local enemy = scene.enemy

		-- 播放特效
		if skillinfo.Effect and string.len(skillinfo.Effect) > 0 then
			Effect:createEffect(skillinfo.Effect, master, enemy)
		end

		local pos = cc.p(enemy.armature:getPosition())
		local moveAction = cc.JumpTo:create(0.7, pos, 100, 1)

		enemy.armature:runAction(moveAction)

		master:DelFrameCallBack("onDamageEvent")
	end

	if skillinfo.PreAction then
		master:AddFrameCallBack("onDamageEvent", onDamage)
		master:DoAttack()
	else
		onDamage()
	end
end

-- 变羊
function Skill:s_sheep(skillinfo, master)
	local function onDamage()
		local scene = display.getRunningScene()
		-- 获取距离最近的敌人
		local enemy = scene.enemy

		-- 隐藏本体
		enemy.armature:setVisible(false)

		local pos = cc.p(enemy.armature:getPosition())

		-- 显示绵羊
		enemy.sheep = display.newSprite("image/sheep.png", pos.x, pos.y)
		enemy.sheep:setScale(0.4)
		scene:addChild(enemy.sheep)

		local function skillEnd()
			enemy.armature:setVisible(true)
			if enemy.sheep then
				enemy.sheep:removeSelf()
				enemy.sheep = nil
			end
		end

		if skillinfo.DurationTime and tonumber(skillinfo.DurationTime) > 0 then
			master.skillhandle = scheduler.performWithDelayGlobal(skillEnd, skillinfo.DurationTime)
		end

		master:DelFrameCallBack("onDamageEvent")
	end

	if skillinfo.PreAction then
		master:AddFrameCallBack("onDamageEvent", onDamage)
		master:DoAttack()
	else
		onDamage()
	end
end

return Skill