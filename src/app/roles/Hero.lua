
local Progress = import("..ui.Progress")
local scheduler = require("framework.scheduler")
local Effect = import("..module.Effect")
local Skill = import("..module.Skill")

local Hero = class("Hero")

function Hero:ctor(heroID, side)
    local heroConf = DataManager:getHeroConf(heroID)
    if not heroConf then
        print("hero config not exist")
        return
    end

    -- 阵营
    self.side = side

    -- 初始化属性信息
    self:initProp(heroConf)

    -- 初始化动画信息
    self:initArmature(heroConf)

    -- 初始化头顶血条
    self:initHPBar()

    -- 初始化状态机
    self:addStateMachine()
end

-- 初始化英雄属性信息
function Hero:initProp(heroConf)
    self.id = heroConf.ID
    self.name = heroConf.Name
    self.attack = heroConf.Attack
    self.hp = heroConf.HP
    self.skills = {heroConf.Skill_1, heroConf.Skill_2, heroConf.Skill_3, heroConf.Skill_4}
end

-- 初始化动画信息
function Hero:initArmature(heroConf)
    local manager = ccs.ArmatureDataManager:getInstance()
    manager:addArmatureFileInfo("armature/" .. heroConf.Armature .. ".ExportJson")
    self.armature = ccs.Armature:create("Hero")    

    self.armature:setScaleX(0.5)
    self.armature:setScaleY(0.5)
    self.armature:setLocalZOrder(10)

    if self.side == 1 then
        self.armature:setPosition(cc.p(display.left+self.armature:getBoundingBox().width/2, display.cy))
    else
        self.armature:setScaleX(-0.5)
        self.armature:setPosition(cc.p(display.right-self.armature:getBoundingBox().width, display.cy))
    end

    self.frameEventList = {}

    -- 注册帧回调
    local function onFrameEvent(bone,evt,originFrameIndex,currentFrameIndex)
        if self.frameEventList[evt] then
            self.frameEventList[evt]()
        end
    end
    self.armature:getAnimation():setFrameEventCallFunc(onFrameEvent)

    -- 注册动画回调
    local function animationEvent(armatureBack,movementType,movementID)
        if movementType == ccs.MovementEventType.complete and movementID == "attack" then
            self:doEvent("stop")
        end
    end
    self.armature:getAnimation():setMovementEventCallFunc(animationEvent)

    -- 帧事件
    local function checkCollision(dt)
        local enemy = display.getRunningScene().enemy
        if enemy == nil then
            return
        end
        if cc.rectIntersectsRect(self.armature:getBoundingBox(), enemy.armature:getBoundingBox()) then
            self.armature:setLocalZOrder(10000 - self.armature:getPositionY()+self.armature:getContentSize().height/2)
            enemy.armature:setLocalZOrder(10000 - enemy.armature:getPositionY()+enemy.armature:getContentSize().height/2)
        end
    end
    self.handle = scheduler.scheduleUpdateGlobal(checkCollision)
end

-- 初始化头血条信息
function Hero:initHPBar()
    local image = ""
    if self.side == 1 then
        image = "ui/hp_green_small.png"
    else
        image = "ui/hp_red_small.png"
    end

    self.progress = Progress.new("ui/hp_black_small.png", image)
    local size = self.armature:getContentSize()

    self.progress:setPosition(size.width/5, size.height)
    self.armature:addChild(self.progress)
end

function Hero:DoAttack()
    if self:getState() ~= 'idle' then
        self:doEvent("stop")
    end

    self:doEvent("doAttack")
end

function Hero:DoMagic()
    if self:getState() ~= 'idle' then
        self:doEvent("stop")
    end

    self:doEvent("doMagic")
end

function Hero:idle()
    transition.stopTarget(self.armature)
    self.armature:getAnimation():playWithIndex(0)
    self.armature:getAnimation():setSpeedScale(0.8)
end

function Hero:walkTo(pos, callback)

    local function moveStop()
        self:doEvent("stop")
        if callback then
            callback()
        end
    end

    if self.moveAction then
        self.armature:stopAction(self.moveAction)
        self.moveAction = nil
    end

    local currentPos = cc.p(self.armature:getPosition())
    local destPos = cc.p(pos.x, pos.y)

    if pos.x < currentPos.x then
        self.armature:setScaleX(-0.5)
    else
        self.armature:setScaleX(0.5)
    end

    local posDiff = cc.pGetDistance(currentPos, destPos)
    self.moveAction = transition.sequence(
        {cc.MoveTo:create(5 * posDiff / display.width, cc.p(pos.x,pos.y)), 
        cc.CallFunc:create(moveStop)})

    if self.armature:getAnimation():getCurrentMovementID() ~= "run" then
        self.armature:getAnimation():playWithIndex(1)
    end

    self.armature:runAction(self.moveAction)
    return true
end

function Hero:beforeAttack()
    transition.stopTarget(self.armature)
    self.armature:getAnimation():stop()
end

function Hero:attackEnemy()
    transition.stopTarget(self.armature)
    self.armature:getAnimation():playWithIndex(2)
end

function Hero:beforeMagic()
    transition.stopTarget(self.armature)
    self.armature:getAnimation():stop()
end

function Hero:magic()
    transition.stopTarget(self.armature)
    self.armature:getAnimation():playWithIndex(2, -1, 1)
end

function Hero:leavemagic()
    -- transition.stopTarget(self.armature)
    Skill:EndSkill(self)
end

function Hero:hit()

    local function hitEnd()
        self:doEvent("stop")
    end
    transition.playAnimationOnce(self.armature, display.getAnimationCache("player1-hit"), false, hitEnd)
end

function Hero:dead()
    local world = PhysicsManager:getInstance()
    world:removeBody(self.body, true)
    self.body = nil
    transition.playAnimationOnce(self, display.getAnimationCache("player1-dead"))
end

function Hero:doEvent(event, ...)
    self.fsm_:doEvent(event, ...)
end

function Hero:getState()
    return self.fsm_:getState()
end

function Hero:addStateMachine()
    self.fsm_ = {}
    cc.GameObject.extend(self.fsm_)
    :addComponent("components.behavior.StateMachine")
    :exportMethods()

    self.fsm_:setupState({

        initial = "idle",

        events = {
        {name = "doWalk", from = {"idle", "attack", "magic"},   to = "walk" },
        {name = "doAttack",  from = {"idle", "walk"},  to = "attack"},
        {name = "beKilled", from = {"idle", "walk", "attack", "hit"},  to = "dead"},
        {name = "beHit", from = {"idle", "walk", "attack"}, to = "hit"},
        {name = "stop", from = {"walk", "attack", "hit", "magic"}, to = "idle"},
        {name = "doMagic", from = {"idle", "walk"}, to = "magic"},
        },

        callbacks = {
        onidle = function (event) self:idle() end,
        onwalk = function (event) self:walkTo(event.args[1], event.args[2]) end,
        -- onbeforeattack = function (event) self:beforeAttack() end,
        onattack = function (event) self:attackEnemy() end,
        onhit = function (event) self:hit() end,
        ondead = function (event) self:dead() end,
        -- onbeforemagic = function (event) self:beforeMagic() end,
        onmagic = function (event) self:magic() end,
        onleavemagic = function (event) self:leavemagic() end
        },
        })

end

function Hero:getID()
    return self.id
end

-- 增加血量
function Hero:IncHp(num)
end

-- 减少血量
function Hero:ReduceHp(num)
end

-- 增加蓝量
function Hero:IncMp(num)
end

-- 减少蓝量
function Hero:ReduceMp(num)
end

function Hero:AddFrameCallBack(eventName, func)
    self.frameEventList[eventName] = func
end

function Hero:DelFrameCallBack(eventName)
    self.frameEventList[eventName] = nil
end

return Hero

