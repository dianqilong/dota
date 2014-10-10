--
-- Author: yjun
-- Date: 2014-09-24 16:37:46
--
local Buff = import("..module.Buff")
local Effect = import("..module.Effect")

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
		master:doEvent("clickEnemy")
	else
		onPointSkillDamage()
	end
end

-- 抽蓝
function Skill:s_stealmp(skillinfo, master)
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
		master:doEvent("domagic")
	end
end

return Skill