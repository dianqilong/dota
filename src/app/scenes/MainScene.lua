
local Hero = import("..roles.Hero")
local SkillPanel = import("..ui.skillpanel")
local dataManager = import("..datamanager.datamanager")
local Skill = import("..module.Skill")

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
    end)

function MainScene:ctor()
    self:initData()
    self:initScene()
end

-- 初始化数据
function MainScene:initData()
    -- 加载数据    
    DataManager = dataManager:new()
end

-- 初始化场景
function MainScene:initScene()
    -- 背景
    local background = display.newSprite("image/background.png", display.cx, display.cy)
    self:addChild(background)

    self.lefts = {}
    self.rights = {}    

    self.hero = Hero.new("hero_lion", 1)
    self.hero.IsUserAI = false
    self.lefts[#self.lefts+1] = self.hero
    self:addChild(self.hero)

    local enemy = Hero.new("hero_lion", 2)

    self.rights[#self.rights+1] = enemy
    self:addChild(enemy)

    self.skillPanel = SkillPanel.new(self, "hero_lion")
    self.skillPanel:UpdateDisplay()

    self:addTouchLayer()
end

function MainScene:addTouchLayer()
    local function onTouch(eventName, x, y)
        if eventName == "began" then
            self.hero:walkTo({x=x, y=y})
            if self.hero:getState() ~= 'walk' and self.hero:getState() ~= 'hit' then
                self.hero:doEvent("doWalk", cc.p(x, y))
            end
        end
    end

    self.layerTouch = display.newLayer()
    self.layerTouch:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        return onTouch(event.name, event.x, event.y)
        end)
    self.layerTouch:setTouchEnabled(true)
    self.layerTouch:setContentSize(cc.size(display.width, display.height - 250))
    self.layerTouch:setPosition(cc.p(0,100))
    self:addChild(self.layerTouch, -5)
end

function MainScene:pause()
    display.pause()
    local layer = PauseLayer.new()
    self:addChild(layer)
end

-- 鏄剧ず杩涘叆涓嬩竴鍏崇殑鎸夐挳
function MainScene:showNextLevelItem()
    local goItem = self.menu:getChildByTag(2)
    goItem:setVisible(true)
    goItem:runAction(CCRepeatForever:create(CCBlink:create(1, 1)))
end

-- 杩涘叆涓嬩竴鍏�
function MainScene:gotoNextLevel()
    local goItem = self.menu:getChildByTag(2)
    transition.stopTarget(goItem)
    goItem:setVisible(false)

    self.background:move("left", self.player)
end

-- 杩涘叆鍏冲崱
function MainScene:enterLevel(level)
    self.level = level
    self:addUI()
    self:addRoles()
end

function MainScene:enemyDead(enemy)
    print("EnemyDead")
    -- 妫�娴嬫晫浜烘槸鍚﹀凡缁忔病琛�浜�
    self:removeEnemy(enemy)

    -- 濡傛灉鏁屼汉鍏ㄩ儴鎸備簡
    if #self.enemys == 0 then
        self:showNextLevelItem()
    end
end

function MainScene:backgroundMoveEnd()
    self:addEnemys()
end

function MainScene:onEnter()

end

function MainScene:onExit()
--    local world = PhysicsManager:getInstance()
--    world:stop()
--    self.layerTouch:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
--    PhysicsManager:purgeInstance()

CCNotificationCenter:sharedNotificationCenter():unregisterScriptObserver(nil, "CLICK_ENEMY")
CCNotificationCenter:sharedNotificationCenter():unregisterScriptObserver(nil, "ENEMY_DEAD")
CCNotificationCenter:sharedNotificationCenter():unregisterScriptObserver(nil, "BACKGROUND_MOVE_END")
end

return MainScene
