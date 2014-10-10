
local Player = import("..roles.Player")
local SkillPanel = import("..ui.skillpanel")
local dataManager = import("..datamanager.datamanager")
local Enemy = import("..roles.enemy")
local Skill = import("..module.Skill")
--local Enemy2 = import("..roles.Enemy2")
--local Progress = import("..ui.Progress")
--local Background = import("..ui.Background")
--local PauseLayer = import("..scenes.PauseLayer")
--local GameoverLayer = import("..scenes.GameoverLayer")
--local PhysicsManager = import("..scenes.PhysicsManager")

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

    -- 人物
    local manager = ccs.ArmatureDataManager:getInstance()
    manager:addArmatureFileInfo("armature/tauren.ExportJson")
    manager:addArmatureFileInfo("armature/Hero.ExportJson")    
    manager:addArmatureFileInfo("effect/redLightAnimation.ExportJson")
    manager:addArmatureFileInfo("effect/blueLightAnimation.ExportJson")

    self.enemy= Enemy.new()
    self:addChild(self.enemy)

    self.hero= Player.new()
    self:addChild(self.hero)

    self.skillPanel = SkillPanel.new(self, "hero_lion")

    self:addTouchLayer()
end

function MainScene:addTouchLayer()
    local function onTouch(eventName, x, y)
        if eventName == "began" then
            self.hero:walkTo({x=x, y=y})
            if self.hero:getState() ~= 'walk' then
                self.hero:doEvent("clickScreen", cc.p(x, y))
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

function MainScene:addRoles()

    -- 鑳屾櫙
    self.background = Background.new()-- display.newSprite("image/background.png", display.cx, display.cy)
    self.background:setPosition(0, 0)
    self:addChild(self.background)

    -- 鐜╁
    self.player = Player.new()
    self.player:setPosition(display.left + self.player:getContentSize().width/2, display.cy)
    self.player.body:setPosition(display.left + self.player:getContentSize().width/2, display.cy)
    self:addChild(self.player)

    self:addEnemys()

--    local world = PhysicsManager:getInstance()
--    self.worldDebug = world:createDebugNode()
--    self:addChild(self.worldDebug)
--    world:addCollisionScriptListener(handler(self, self.onCollision) ,
--        CollisionType.kCollisionTypePlayer, CollisionType.kCollisionTypeEnemy)

end

function MainScene:addEnemys()

    -- 鏁屼汉1
    self.enemy1 = Enemy1.new()
    self.enemy1:setPosition(display.right - self.enemy1:getContentSize().width/2, display.cy)
    self.enemy1.body:setPosition(display.right - self.enemy1:getContentSize().width/2, display.cy)
    self:addChild(self.enemy1)

    self.enemys[#self.enemys + 1] = self.enemy1

    -- 鏁屼汉2
    self.enemy2 = Enemy2.new()
    self.enemy2:setPosition(display.right - self.enemy2:getContentSize().width/2 * 3, display.cy)
    self.enemy2.body:setPosition(display.right - self.enemy2:getContentSize().width/2 * 3, display.cy)
    self:addChild(self.enemy2)

    self.enemys[#self.enemys + 1] = self.enemy2
end

function MainScene:onCollision(eventType, event)
    print(eventType)
    if eventType == 'begin' then
        self.canAttack = true
        local body1 = event:getBody1()
        local body2 = event:getBody2()

        if body1:getCollisionType() == CollisionType.kCollisionTypePlayer and body2 then
            body2.isCanAttack = true
        end
        elseif eventType == 'separate' then
            self.canAttack = false
            local body1 = event:getBody1()
            local body2 = event:getBody2()

            if body1:getCollisionType() == CollisionType.kCollisionTypePlayer and body2 then
                body2.isCanAttack = false
            end
        end
    end

    function MainScene:addUI()

    -- 琛�閲�
    self.progress = Progress.new("#player-progress-bg.png", "#player-progress-fill.png")
    self.progress:setPosition(display.left + self.progress:getContentSize().width/2, display.top - self.progress:getContentSize().height/2)
    self:addChild(self.progress, 10)

    local itemPause = cc.ui.MenuItem:create({image="#pause1.png", imageSelected="#pause2.png",
        tag=1, listener = function(tag) self:pause() end})

    local itemGo = cc.ui.MenuItem:create({image="#go.png", tag = 2, listener = function(tag)
        self:gotoNextLevel()
        end})
    display.align(itemGo, display.CENTER_RIGHT, 0, 0)
    itemGo:setVisible(false)
    itemGo:setPosition(display.right, display.cy)
    self.menu = cc.ui.newMenu({itemPause, itemGo})
    itemPause:setPosition(display.right-itemPause:getContentSize().width/2, display.top-itemPause:getContentSize().height/2)
    self.menu:setPosition(0,0)
    self:addChild(self.menu, 10)
end

function MainScene:pause()
    display.pause()
    local layer = PauseLayer.new()
    self:addChild(layer)
end

function MainScene:clickEnemy(enemy)
    print("self.canAttack = " .. tostring(self.canAttack))
    if self.canAttack then
        if self.player:getState() ~= "attack" then
            self.player:doEvent("clickEnemy")
            print("enemy:canAttack " .. tostring(enemy:getCanAttack()))
            if enemy:getCanAttack() and enemy:getState() ~= 'hit' then
                enemy:doEvent("beHit", {attack = self.player.attack})
            end
        end
    else
        local x,y = enemy:getPosition()
        self.player:walkTo({x=x, y=y})
        if self.player:getState() ~= 'walk' then
            self.player:doEvent("clickScreen")
        end
    end
end

function MainScene:removeEnemy(enemy)
    for i, v in ipairs(self.enemys) do
        if enemy == v then
            table.remove(self.enemys, i)
        end
    end
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
