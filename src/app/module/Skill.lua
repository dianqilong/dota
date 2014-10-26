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
function Skill:UseSkill(master, index)
	local skillID = master.skills[index]
	local skillInfo = DataManager:getSkillConf(skillID)
	if skillInfo == nil then
		print("skill config not exit. ")
		return
	end

	self.power_index = index

	local switch = {
		[0] = function(info, m) self:PassiveSkill(info, m) end,

		[1] = function(info, m) self:PointSkill(info, m) end,

		[2] = function(info, m) self:ptpLineEffect(info, m) end,

		[3] = function(info, m) self:circular_aoe(info, m) end,

		[4] = function(info, m) self:ptpLineEffect(info, m) end
	}

	-- 技能事件分发
	local func = switch[skillInfo.Type]
	if func then
		func(skillInfo, master)
	elseif self[skillID] then
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

-- 获取技能类型
function Skill:getSkillType(skillID)
	return DataManager:getSkillConf(skillID).Type
end

-- 获取技能能量消耗
function Skill:getNeedPower(skillID)
	return DataManager:getSkillConf(skillID).Power
end

-- 获取敌方阵营活着的单位
local function getAnemys(master)
	if master.side == 1 then
		return display.getRunningScene().rights
	else
		return display.getRunningScene().lefts
	end
end

-- 选取受影响敌人
function Skill:GetSufferer(skillinfo, master, type)
	if type == "line" then--施法者前方线行范围
		local effWidth = skillinfo.EffWidth*3
		local effSpring = skillinfo.EffSpring*3
		local castDistance = skillinfo.CastDistance
		local suffererList = {}
		local masterPos = cc.p(master:getPosition())
		local enemys = getAnemys(master)
		for i = 1, #enemys do
			if not enemys[i]:IsDead() then
				local enemyPos = cc.p(enemys[i]:getPosition())
				if math.abs(masterPos.y - enemyPos.y) < effWidth then
					if master.armature:getScaleX() < 0 then
						if masterPos.x > enemyPos.x and masterPos.x - (effSpring/2+castDistance) < enemyPos.x then
							suffererList[#suffererList+1] = enemys[i]
						end
					else
						if masterPos.x < enemyPos.x and masterPos.x + (effSpring/2+castDistance) > enemyPos.x then
							suffererList[#suffererList+1] = enemys[i]
						end
					end
				end
			end
		end
		return suffererList
	elseif type == "atkrange" then -- 攻击范围内最近的敌方单位
		local targets = getAnemys(master)
		if #targets == 0 then
			return nil
		end

		local target = nil
		local masterPos = cc.p(master:getPosition())
		local minDistance = master.atkRange
		for i = 1, #targets do
			if not targets[i]:IsDead() then
				local targetPos = cc.p(targets[i]:getPosition())
				local distance = cc.pGetDistance(masterPos, targetPos)
				if distance < minDistance then
					target = targets[i]
					minDistance = distance
				end
			end
		end
		return target	
	elseif type == "closest" then -- 最近的敌方单位
		local targets = getAnemys(master)
		if #targets == 0 then
			return nil
		elseif #targets == 1 then
			if targets[1]:IsDead() then
				return nil
			end
			return targets[1]
		end

		local target = targets[1]
		local masterPos = cc.p(master:getPosition())
		local minDistance = 10000
		for i = 1, #targets do
			if not targets[i]:IsDead() then
				local distance = cc.pGetDistance(masterPos, cc.p(targets[i]:getPosition()))
				if distance < minDistance then
					target = targets[i]
					minDistance = distance
				end
			end
		end
		return target
	end
	return nil
end

-- 被动技能
function Skill:PassiveSkill(skillinfo, master)
	-- 添加buff
	if skillinfo.AddBuff then
		Buff:AddBuff(master, skillinfo.AddBuff)
	end
end

-- 单体技能
function Skill:PointSkill(skillinfo, master)
	-- 获取距离最近的敌人
	local enemy = self:GetSufferer(skillinfo, master, "closest")
	if not enemy then
		return
	end

	master:ReducePower(10000, self.power_index)
	master.atktime = 2

	--调整朝向
    if master:getPositionX() > enemy:getPositionX() then
        master.armature:setScaleX(-0.5)
    else
        master.armature:setScaleX(0.5)
    end
	local function onPointSkillDamage()
		master:DelCallBack("onDamageEvent", onPointSkillDamage)
		local scene = display.getRunningScene()

		-- 添加buff
		if skillinfo.AddBuff then
			Buff:AddBuff(master, skillinfo.AddBuff)
		end

		-- 计算伤害
		if skillinfo.EffProp then
			enemy:ReduceHp(skillinfo.Damage, master)
		end

		-- 播放特效
		if skillinfo.Effect then
			Effect:createEffect(skillinfo.Effect, master, enemy)
		end
	end

	if skillinfo.PreAction then
		master:AddCallBack("onDamageEvent", onPointSkillDamage)
		master:DoMagic()
	else
		onPointSkillDamage()
	end
end

-- 根据技能施法距离获取特效位置偏移量
function getEffectOffset(skillinfo, master)
	if skillinfo.CastDistance == 0 then
		return 0
	end

	-- 左方阵营
	if master.side == 1 then
		return skillinfo.CastDistance
	else
		return -skillinfo.CastDistance
	end

	return 0
end

-- 圆形AOE
function Skill:circular_aoe(skillinfo, master)
	master:ReducePower(10000, self.power_index)
	master.atktime = 2

	local function onDamage()
		master:DelCallBack("onDamageEvent", onDamage)

		-- 添加buff
		if skillinfo.AddBuff then
			Buff:AddBuff(master, skillinfo.AddBuff)
		end

		-- 播放特效
		if skillinfo.Effect then
			local effect = Effect:createEffect(skillinfo.Effect, master)
			if effect then
				effect:setPosition(master:getPositionX() + getEffectOffset(skillinfo, master), master:getPositionY())
			end
		end

		-- 获取受影响敌人
		local enemys = self:GetSufferer(skillinfo, master, "line")
		for i = 1, #enemys do
			enemys[i]:ReduceHp(skillinfo.Damage, master)
			if not enemys[i]:IsDead() and skillinfo.DurationTime > 0 then
				enemys[i]:Hold(skillinfo.DurationTime)
			end
		end
	end

	if skillinfo.PreAction then
		master:AddCallBack("onDamageEvent", onDamage)
		master:DoMagic()
	else
		onDamage()
	end
end

-- 抽蓝
function Skill:s_stealmp(skillinfo, master)
	-- 获取距离最近的敌人
	local enemy = self:GetSufferer(skillinfo, master, "closest")
	if not enemy then
		return
	end

	master:ReducePower(10000, self.power_index)
	master.atktime = 2

	--调整朝向
	if master:getPositionX() > enemy:getPositionX() then
		master.armature:setScaleX(-0.5)
	else
		master.armature:setScaleX(0.5)
	end

	local function onDamage()
		master:DelCallBack("onDamageEvent", onDamage)
		local scene = display.getRunningScene()

		-- 添加buff
		if skillinfo.AddBuff then
			Buff:AddBuff(master, skillinfo.AddBuff)
		end

		-- 计算伤害
		local function stealPower()
			--目标死亡，不处理
			if enemy:IsDead() then
				master:doEvent("stop")
				return
			end
			master.stealPowerTimer = master.stealPowerTimer + 0.5
			if master.stealPowerTimer > skillinfo.DurationTime then
				master:doEvent("stop")
				return
			end

			master:IncPower(5)
			enemy:ReducePowerAll(5)
		end

		-- 播放特效
		if skillinfo.Effect then
			Effect:createEffect(skillinfo.Effect, master, enemy)
		end

		if skillinfo.DurationTime and skillinfo.DurationTime > 0 then
			master.skillhandle = scheduler.scheduleGlobal(stealPower, 0.5)
			master.stealPowerTimer = 0
			stealPower()
		end
	end

	if skillinfo.PreAction then
		master:AddCallBack("onDamageEvent", onDamage)
		master:DoMagic(1)
	else
		onDamage()
	end
end

-- 穿刺
function Skill:s_puncture(skillinfo, master)
	-- 获取距离最近的敌人
	local enemys = self:GetSufferer(skillinfo, master, "line")

	master:ReducePower(10000, self.power_index)
	master.atktime = 2

	local function onDamage()
		master:DelCallBack("onDamageEvent", onDamage)
		local scene = display.getRunningScene()
		-- 播放特效
		if skillinfo.Effect and string.len(skillinfo.Effect) > 0 then
			Effect:createEffect(skillinfo.Effect, master)
		end

		local masterPos = cc.p(master:getPosition())
		for i = 1, #enemys do
			local enemyPos = cc.p(enemys[i]:getPosition())
			local distance = math.abs(masterPos.x - enemyPos.x)
			local delay = math.floor(distance/(skillinfo.EffSpring/3))

			local function doEffect()
				--目标死亡，不处理
				if enemys[i]:IsDead() then
					return
				end
				enemys[i]:Hold(skillinfo.DurationTime)
				local moveAction = cc.JumpTo:create(0.7, enemyPos, 100, 1)
				enemys[i]:runAction(moveAction)
				-- 计算伤害
				if skillinfo.EffProp then
					enemys[i]:ReduceHp(skillinfo.Damage, master)
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
		master:AddCallBack("onDamageEvent", onDamage)
		master:DoMagic()
	else
		onDamage()
	end
end

-- 变羊
function Skill:s_sheep(skillinfo, master)
	-- 获取距离最近的敌人
	local enemy = self:GetSufferer(skillinfo, master, "closest")
	if not enemy then
		return
	end
	master:ReducePower(10000, self.power_index)
	master.atktime = 2
	--调整朝向
    if master:getPositionX() > enemy:getPositionX() then
        master.armature:setScaleX(-0.5)
    else
        master.armature:setScaleX(0.5)
    end
	local function onDamage()
		master:DelCallBack("onDamageEvent", onDamage)
		--目标死亡，不处理
		if enemy:IsDead() then
			return
		end
		local scene = display.getRunningScene()
		
		-- 隐藏本体
		enemy.armature:setVisible(false)
		enemy.armature:getAnimation():stop()

		local pos = cc.p(enemy.armature:getPosition())

		-- 显示绵羊
		if enemy.subs then
			enemy.subs:removeSelf()
			enemy.subs = nil
		end

		enemy.subs = display.newSprite("image/sheep.png", pos.x, pos.y)
		enemy.subs:setScale(0.4)
		if enemy.side == 1 then
			enemy.subs:setScaleX(-0.4)
		end
		enemy:addChild(enemy.subs)
		enemy:Hold(skillinfo.DurationTime)

		local function skillEnd()
			enemy.schedulers["sheepTimer"] = nil
			enemy.armature:setVisible(true)
			if enemy.subs then
				enemy.subs:removeSelf()
				enemy.subs = nil
			end
		end

		if skillinfo.DurationTime and skillinfo.DurationTime > 0 then
			if enemy.schedulers["sheepTimer"] then
				scheduler.unscheduleGlobal(enemy.schedulers["sheepTimer"])
				enemy.schedulers["sheepTimer"] = nil
			end
			enemy.schedulers["sheepTimer"] = scheduler.performWithDelayGlobal(skillEnd, skillinfo.DurationTime)
		end
	end

	if skillinfo.PreAction then
		master:AddCallBack("onDamageEvent", onDamage)
		master:DoMagic()
	else
		onDamage()
	end
end

return Skill