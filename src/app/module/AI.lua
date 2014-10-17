--
-- Author: yjun
-- Date: 2014-10-16 10:46:49
--

local Skill = import("..module.Skill")

local AI = class("AI")

function AI:ctor()
end

function AI:SetMaster(master)
	self.master = master
end

-- 捕获事件,更新指令
function AI:CatchEvent(eventName)
	local master = self.master
	local state = master:getState()
	if state == "idle" then
		-- 尝试释放技能
		local index = self:getReadySkill()
		if not master.IsUserAI then
			index = nil
		end
		if index then
			if master.atktime <= 0 then
				Skill:UseSkill(master, index)
			end
		else -- 尝试普通攻击
			local target = Skill:GetSufferer(nil, master, "closest")
			if target then
				local distance = cc.pGetDistance(cc.p(master:getPosition()), cc.p(target:getPosition()))
				if distance <= master.atkRange then
					if master.atktime <= 0 then
						master:DoAttack()
					end
				else
					master:WalkTo(cc.p(target:getPosition()))
				end
			end
		end
	elseif state == "walk" then
		local target = Skill:GetSufferer(nil, master, "closest")
		if target then
			local distance = cc.pGetDistance(cc.p(master:getPosition()), cc.p(target:getPosition()))
			if distance <= master.atkRange then
				master:Stop()
			end
		end
	end
end

-- 获取一个准备好的技能
function AI:getReadySkill()
	for i = 1, 4 do
		if self.master.skillsReady[i] then
			return i
		end
	end

	return nil
end

return AI