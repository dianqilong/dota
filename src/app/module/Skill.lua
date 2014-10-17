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

	self.index = index

	local switch = {
		[1] = function(info, m) self:PointSkill(info, m) end,

		[2] = function(info, m) self:ptpLineEffect(info, m) end,

		[3] = function(info, m) self:ptpLineEffect(info, m) end,

		[4] = function(info, m) self:ptpLineEffect(info, m) end
	}

	-- 技能事件分发
	local func = switch[skillInfo.Type]
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
		local effWidth = skillinfo.EffWidth
		local effSpring = skillinfo.EffSpring
		local suffererList = {}
		local masterPos = cc.p(master:getPosition())
		for key, enemy in pairs(getAnemys(master)) do
			if not enemy:IsDead() then
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
		local minDistance = cc.pGetDistance(masterPos, cc.p(target:getPosition()))
		for i = 2, #targets do
			if not targets[i]:IsDead() then
				local distance = cc.pGetDistance(masterPos, cc.p(targets[i]:getPosition()))
				if distance < minDistance then
					target = targets[i]
				end
			end
		end
		return target
	end
	return nil
end

-- 单体技能
function Skill:PointSkill(skillinfo, master)
	-- 获取距离最近的敌人
	local enemy = self:GetSufferer(skillinfo, master, "closest")
	if not enemy then
		return
	end

	master:ReducePower(10000, self.index)
	master.atktime = 2

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
	local enemy = self:GetSufferer(skillinfo, master, "closest")
	if not enemy then
		return
	end

	master:ReducePower(10000, self.index)
	master.atktime = 2

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
		local function stealPower()
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
		master:AddFrameCallBack("onDamageEvent", onDamage)
		master:DoMagic(1)
	else
		onDamage()
	end
end

-- 穿刺
function Skill:s_puncture(skillinfo, master)
	-- 获取距离最近的敌人
	local enemys = self:GetSufferer(skillinfo, master, "line")
	if #enemys == 0 then
		return
	end

	master:ReducePower(10000, self.index)
	master.atktime = 2

	local function onDamage()
		master:DelFrameCallBack("onDamageEvent")
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
				enemys[i]:Hold(skillinfo.DurationTime)
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
	local enemy = self:GetSufferer(skillinfo, master, "closest")
	if not enemy then
		return
	end
	master:ReducePower(10000, self.index)
	master.atktime = 2
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
		enemy.armature:getAnimation():stop()

		local pos = cc.p(enemy.armature:getPosition())

		-- 显示绵羊
		enemy.sheep = display.newSprite("image/sheep.png", pos.x, pos.y)
		enemy.sheep:setScale(0.4)
		if enemy.side == 1 then
			enemy.sheep:setScaleX(-0.4)
		end
		enemy:addChild(enemy.sheep)
		enemy:Hold(skillinfo.DurationTime)

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