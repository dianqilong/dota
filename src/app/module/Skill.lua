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

-- 选取受影响敌人
function Skill:GetSufferer(skillinfo, master, type)
	if type == "line" then--施法者前方线行范围
		local effWidth = skillinfo.EffWidth
		local effSpring = skillinfo.EffSpring
		local suffererList = {}
		local masterPos = cc.p(master:getPosition())
		for key, enemy in pairs(display.getRunningScene().rights) do
			local enemyPos = cc.p(enemy:getPosition())
			if math.abs(masterPos.y - enemyPos.y) < effWidth then
				if master.armature:getScaleX() < 0 then
					if masterPos.x > enemyPos.x and masterPos.x - effSpring < enemyPos.x then
						suffererList[#suffererList+1] = enemy
					end
				else
					if masterPos.x < enemyPos.x and masterPos.x + effSpring > enemyPos.x then
						suffererList[#suffererList+1] = enemy
					end
				end
			end
		end
		return suffererList
	elseif type == "closest_point" then--阵营最前方单位
		local targets = display.getRunningScene().rights
		if #targets == 0 then
			return nil
		elseif #targets == 1 then
			return targets[1]
		end

		local target = targets[1]
		for i = 2, #targets do
			local enemyPos = cc.p(targets[i]:getPosition())
			local targetPos = cc.p(target:getPosition())
			if enemy.armature:getScaleX() < 0 and enemyPos.x < targetPos.x then
				target = targets[i]
			elseif enemy.armature:getScaleX() > 0 and enemyPos.x > targetPos.x then
				target = targets[i]
			end
		end
		return target
	end
	return nil
end

-- 单体技能
function Skill:PointSkill(skillinfo, master)
	-- 获取距离最近的敌人
	local enemy = self:GetSufferer(skillinfo, master, "closest_point")

	--调整朝向
    if master:getPositionX() > enemy:getPositionX() then
        master.armature:setScaleX(-0.5)
    else
        master.armature:setScaleX(0.5)
    end
	local function onPointSkillDamage()
		master:DelFrameCallBack("onDamageEvent")
		local scene = display.getRunningScene()

		-- 添加buff
		if skillinfo.AddBuff then
			Buff:AddBuff(master, skillinfo.AddBuff)
		end

		-- 计算伤害
		if skillinfo.EffProp then
			enemy:ReduceHp(skillinfo.Damage)
		end

		-- 播放特效
		if skillinfo.Effect then
			Effect:createEffect(skillinfo.Effect, master, enemy)
		end
		
	end

	if skillinfo.PreAction then
		master:AddFrameCallBack("onDamageEvent", onPointSkillDamage)
		master:DoMagic()
	else
		onPointSkillDamage()
	end
end

-- 抽蓝
function Skill:s_stealmp(skillinfo, master)
	-- 获取距离最近的敌人
	local enemy = self:GetSufferer(skillinfo, master, "closest_point")

	--调整朝向
	if master:getPositionX() > enemy:getPositionX() then
		master.armature:setScaleX(-0.5)
	else
		master.armature:setScaleX(0.5)
	end

	local function onDamage()
		master:DelFrameCallBack("onDamageEvent")
		local scene = display.getRunningScene()

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
		master:DoMagic(1)
	else
		onDamage()
	end
end

-- 穿刺
function Skill:s_puncture(skillinfo, master)
	local function onDamage()
		master:DelFrameCallBack("onDamageEvent")
		local scene = display.getRunningScene()
		-- 播放特效
		if skillinfo.Effect and string.len(skillinfo.Effect) > 0 then
			Effect:createEffect(skillinfo.Effect, master)
		end

		local masterPos = cc.p(master:getPosition())
		-- 获取敌人
		local enemys = self:GetSufferer(skillinfo, master, "line")
		for i = 1, #enemys do
			local enemyPos = cc.p(enemys[i]:getPosition())
			local distance = math.abs(masterPos.x - enemyPos.x)
			local delay = math.floor(distance/(skillinfo.EffSpring/3))

			local function doEffect()
				local moveAction = cc.JumpTo:create(0.7, enemyPos, 100, 1)
				enemys[i]:runAction(moveAction)
				-- 计算伤害
				if skillinfo.EffProp then
					enemys[i]:ReduceHp(skillinfo.Damage)
				end
			end

			if delay > 0 then
				scheduler.performWithDelayGlobal(doEffect, delay*0.2)
			else
				doEffect()
			end
		end
	end

	if skillinfo.PreAction then
		master:AddFrameCallBack("onDamageEvent", onDamage)
		master:DoMagic()
	else
		onDamage()
	end
end

-- 变羊
function Skill:s_sheep(skillinfo, master)
	-- 获取距离最近的敌人
	local enemy = self:GetSufferer(skillinfo, master, "closest_point")

	--调整朝向
    if master:getPositionX() > enemy:getPositionX() then
        master.armature:setScaleX(-0.5)
    else
        master.armature:setScaleX(0.5)
    end
	local function onDamage()
		master:DelFrameCallBack("onDamageEvent")
		local scene = display.getRunningScene()
		
		-- 隐藏本体
		enemy.armature:setVisible(false)

		local pos = cc.p(enemy.armature:getPosition())

		-- 显示绵羊
		enemy.sheep = display.newSprite("image/sheep.png", pos.x, pos.y)
		enemy.sheep:setScale(0.4)
		enemy:addChild(enemy.sheep)

		local function skillEnd()
			enemy.armature:setVisible(true)
			if enemy.sheep then
				enemy.sheep:removeSelf()
				enemy.sheep = nil
			end
		end

		if skillinfo.DurationTime and skillinfo.DurationTime > 0 then
			enemy.sheepTimer = scheduler.performWithDelayGlobal(skillEnd, skillinfo.DurationTime)
		end
	end

	if skillinfo.PreAction then
		master:AddFrameCallBack("onDamageEvent", onDamage)
		master:DoMagic()
	else
		onDamage()
	end
end

-- 获取技能能量消耗
function Skill:getNeedPower(skillID)
	return DataManager:getSkillConf(skillID).Power
end

return Skill