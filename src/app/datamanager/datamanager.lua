--
-- Author: yjun
-- Date: 2014-09-24 15:14:33
--
import("..util")
local Effect = import("..module.Effect")
local Skill = import("..module.Skill")

local DataManager = class("DataManager")

function DataManager:ctor()
	self:loadHeroConfig()
	self:loadSkillConfig()
	self:loadEffectConfig()
	self:loadBuffConfig()
	self:loadNpcConfig()

	self.effect = Effect:new()
	self.skill = Skill:new()
	self.index = 0
end

-- 获取全局递增索引
function DataManager:getIncIndex()
	self.index = self.index + 1
	return self.index
end

function DataManager:loadHeroConfig()
	local path = cc.FileUtils:getInstance():fullPathForFilename("config/heroconfig.csv")
	self.heroconfig = loadCsvFile(path)
end

function DataManager:loadSkillConfig()
	local path = cc.FileUtils:getInstance():fullPathForFilename("config/skillconfig.csv")
	self.skillconfig = loadCsvFile(path)
end

function DataManager:loadEffectConfig()
	local path = cc.FileUtils:getInstance():fullPathForFilename("config/effectconfig.csv")
	self.effectconfig = loadCsvFile(path)
end

function DataManager:loadBuffConfig()
	local path = cc.FileUtils:getInstance():fullPathForFilename("config/buffconfig.csv")
	self.buffconfig = loadCsvFile(path)
end

function DataManager:loadNpcConfig()
	local path = cc.FileUtils:getInstance():fullPathForFilename("config/npcconfig.csv")
	self.npcconfig = loadCsvFile(path)
end

function DataManager:getHeroConf(heroID)
	return self.heroconfig[heroID]
end

function DataManager:getEffectConf(effectID)
	return self.effectconfig[effectID]
end

function DataManager:getSkillConf(skillID)
	return self.skillconfig[skillID]
end

function DataManager:getBuffConf(buffID)
	return self.buffconfig[buffID]
end

function DataManager:setBuffConf(buffID, config)
	self.buffconfig[buffID] = config
end

function DataManager:getNpcConf(npcID)
	return self.npcconfig[npcID]
end

return DataManager