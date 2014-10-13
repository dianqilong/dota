--
-- Author: yjun
-- Date: 2014-09-23 20:56:03
--
local Skill = import("..module.Skill")
local Progress = import("..ui.Progress")
local Effect = import("..module.Effect")

local SkillPanel = class("SkillPanel", function(parent, heroID)
        -- 获取英雄技能信息
        local subheroID = string.split(heroID, '_')[2]
        local heroInfo = DataManager:getHeroConf(heroID)

        local node = cc.uiloader:load("ui/SkillPanelUI/SkillPanelUI_1.json")
        parent:addChild(node)

        local skillBtn_1 = cc.uiloader:seekNodeByTag(node, 1)
        skillBtn_1:onButtonClicked(function(event)
        	Skill:UseSkill(display.getRunningScene().hero, heroInfo.Skill_1)
        	end)
        :setButtonImage("normal", "icon/skill_"..subheroID .. "_1.png")
        :setButtonImage("pressed", "icon/skill_"..subheroID .. "_1.png")
        :setButtonImage("disabled", "icon/skill_"..subheroID .. "_1.png")

        skillBtn_1 = cc.uiloader:seekNodeByTag(node, 2)
        skillBtn_1:onButtonClicked(function(event)
        	Skill:UseSkill(display.getRunningScene().hero, heroInfo.Skill_2)
        	-- display.getRunningScene().enemy.armature:setVisible(not display.getRunningScene().enemy.armature:isVisible())

        	end)
        :setButtonImage("normal", "icon/skill_"..subheroID .. "_2.png")
        :setButtonImage("pressed", "icon/skill_"..subheroID .. "_2.png")        
        :setButtonImage("disabled", "icon/skill_"..subheroID .. "_2.png")

        skillBtn_1 = cc.uiloader:seekNodeByTag(node, 3)
        skillBtn_1:onButtonClicked(function(event)
        	Skill:UseSkill(display.getRunningScene().hero, heroInfo.Skill_3)
        	end)
        :setButtonImage("normal", "icon/skill_"..subheroID .. "_3.png")
        :setButtonImage("pressed", "icon/skill_"..subheroID .. "_3.png")        
        :setButtonImage("disabled", "icon/skill_"..subheroID .. "_3.png")

        skillBtn_1 = cc.uiloader:seekNodeByTag(node, 4)
        skillBtn_1:onButtonClicked(function(event)
        	Skill:UseSkill(display.getRunningScene().hero, heroInfo.Skill_4)
        	end)
        :setButtonImage("normal", "icon/skill_"..subheroID .. "_4.png")
        :setButtonImage("pressed", "icon/skill_"..subheroID .. "_4.png")        
        :setButtonImage("disabled", "icon/skill_"..subheroID .. "_4.png")

        skillBtn_1 = cc.uiloader:seekNodeByTag(node, 5)
        skillBtn_1:onButtonClicked(function(event)
        	if (display.getRunningScene().hero.armature:getAnimation():getCurrentMovementID() ~= "attack") then
        		display.getRunningScene().hero:doEvent("doAttack")
        	end
        	end)
        :setButtonImage("normal", "icon/"..heroID .. ".png")
        :setButtonImage("pressed", "icon/"..heroID .. ".png")
        :setButtonImage("disabled", "icon/"..heroID .. ".png")

        local progressBack = cc.uiloader:seekNodeByTag(node, 7)
        node.progress = Progress.new("ui/hp_gray.png", "ui/hp_green.png")
        node.progress:setScale(1.6)
        node.progress:setPosition(progressBack:getPositionX(), progressBack:getPositionY())
        node:addChild(node.progress)
        progressBack:setVisible(false)
        node.progress:setProgress(100)

        return node

        end)

function SkillPanel:ctor()
    self:setLocalZOrder(10000)
end

return SkillPanel