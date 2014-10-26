--
-- Author: yjun
-- Date: 2014-09-27 11:06:48
--
local Buff = class("Buff")

function Buff:ctor(buffID)
	self.id = buffID
	self.buffConf = DataManager:getBuffConf(buffID)
	if not self.buffConf then
		return nil
	end
	self.triggers = {}

	local trigger = self.buffConf.Trigger

	if trigger == 1 then -- 添加时触发
		self.triggers = {"OnAdd"}
	elseif trigger == 2 then
	elseif trigger == 3 then
	elseif trigger == 4 then -- 被攻击
		self.triggers = {"ReduceHp"}
	end
end

-- 添加buff
function Buff:AddBuff(target, buffID)
	Buff:DelBuff(target, buffID)

	local buff = Buff.new(buffID)
	buff.master = target

	local config = buff.buffConf
	if not config then
		print("buff config not exist")
		return
	end

	-- 添加buff到对象
	target.buffs[buffID] = buff

	buff:UpdateBuff("OnAdd")

	return buff
end

-- 删除buff	
function Buff:DelBuff(target, buffID)
	local buff = target.buffs[buffID]
	if not buff then
		return
	end

	buff:UpdateBuff("OnDel")

	target.buffs[buffID] = nil
end

-- 更新buff状态
function Buff:UpdateBuff(type, ...)
	if not ValueExist(self.triggers, type) then
		return
	end

	local config = self.buffConf

	if config.ExecFunc and self[config.ExecFunc] then
		self[config.ExecFunc](self, ...)
	elseif self[self.id] then
		self[self.id](self, ...)
	else
		print("no buff function")
	end
end

-- 反伤buff
function Buff:buff_return(num, attacker)
	attacker:ReduceHp(num/2)
end

-- 增加属性
function Buff:add_prop()
	local prop = self.buffConf.Prop
	local value = self.buffConf.Value
	self.master:IncProp(prop, value)
end

-- 减少属性
function Buff:reduce_prop()
	local prop = self.buffConf.Prop
	local value = self.buffConf.Value
	self.master:ReduceProp(prop, value)
end

return Buff