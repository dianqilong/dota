
local Progress = import("..ui.Progress")
local scheduler = require("framework.scheduler")
local Effect = import("..module.Effect")

local Player = class("Player", function()
    local armature = ccs.Armature:create("Hero")

    local function onFrameEvent(bone,evt,originFrameIndex,currentFrameIndex)
        if armature.frameEventList[evt] then
            armature.frameEventList[evt]()
        end
    end

    armature:getAnimation():setFrameEventCallFunc(onFrameEvent)

    return armature
    end)

function Player:ctor(heroID)
    self.progress = Progress.new("ui/hp_black_small.png", "ui/hp_green_small.png")
    local size = self:getContentSize()
    self.progress:setPosition(size.width/5, size.height)
    self:addChild(self.progress)

    self.id = "hero"
    self.attack = 50
    self.blood = 500
    self:setScaleX(0.5)
    self:setScaleY(0.5)
    self:setLocalZOrder(10)
    self:addStateMachine()
    self:setPosition(cc.p(display.left+self:getBoundingBox().width/2, display.cy))

    self.frameEventList = {}

    local function animationEvent(armatureBack,movementType,movementID)
        if movementType == ccs.MovementEventType.complete and movementID == "attack" then
            self:doEvent("stop")
        end
    end

    self:getAnimation():setMovementEventCallFunc(animationEvent)

    -- 帧事件
    local function checkCollision(dt)
        local enemy = display.getRunningScene().enemy
        if enemy == nil then
            return
        end
        if cc.rectIntersectsRect(self:getBoundingBox(), enemy:getBoundingBox()) then
            self:setLocalZOrder(10000 - self:getPositionY()+self:getContentSize().height/2)
            enemy:setLocalZOrder(10000 - enemy:getPositionY()+enemy:getContentSize().height/2)
        end
    end

    self.handle = scheduler.scheduleUpdateGlobal(checkCollision)
end

function Player:idle()
    transition.stopTarget(self)
    self:getAnimation():playWithIndex(0)
    self:getAnimation():setSpeedScale(0.8)
end

function Player:walkTo(pos, callback)

    local function moveStop()
        self:doEvent("stop")
        if callback then
            callback()
        end
    end

    if self.moveAction then
        self:stopAction(self.moveAction)
        self.moveAction = nil
    end

    local currentPos = cc.p(self:getPosition())
    local destPos = cc.p(pos.x, pos.y)

    if pos.x < currentPos.x then
        self:setScaleX(-0.5)
    else
        self:setScaleX(0.5)
    end

    local posDiff = cc.pGetDistance(currentPos, destPos)
    self.moveAction = transition.sequence(
        {cc.MoveTo:create(5 * posDiff / display.width, cc.p(pos.x,pos.y)), 
        cc.CallFunc:create(moveStop)})

    if self:getAnimation():getCurrentMovementID() ~= "run" then
        self:getAnimation():playWithIndex(1)
    end

    self:runAction(self.moveAction)
    return true
end

function Player:attackEnemy()
    transition.stopTarget(self)
    self:getAnimation():playWithIndex(2)
end

function Player:magic()
    transition.stopTarget(self)
    self:getAnimation():playWithIndex(2, -1, 1)
end

function Player:leavemagic()
    transition.stopTarget(self)
end

function Player:hit()

    local function hitEnd()
        self:doEvent("stop")
    end
    transition.playAnimationOnce(self, display.getAnimationCache("player1-hit"), false, hitEnd)
end

function Player:dead()
    local world = PhysicsManager:getInstance()
    world:removeBody(self.body, true)
    self.body = nil
    transition.playAnimationOnce(self, display.getAnimationCache("player1-dead"))
end

function Player:doEvent(event, ...)
    self.fsm_:doEvent(event, ...)
end

function Player:getState()
    return self.fsm_:getState()
end

function Player:addStateMachine()
    self.fsm_ = {}
    cc.GameObject.extend(self.fsm_)
    :addComponent("components.behavior.StateMachine")
    :exportMethods()

    self.fsm_:setupState({

        initial = "idle",

        events = {
        {name = "clickScreen", from = {"idle", "attack", "magic"},   to = "walk" },
        {name = "clickEnemy",  from = {"idle", "walk"},  to = "attack"},
        {name = "beKilled", from = {"idle", "walk", "attack", "hit"},  to = "dead"},
        {name = "beHit", from = {"idle", "walk", "attack"}, to = "hit"},
        {name = "stop", from = {"walk", "attack", "hit"}, to = "idle"},
        {name = "domagic", from = {"idle", "walk"}, to = "magic"},
        },

        callbacks = {
        onidle = function (event) self:idle() end,
        onwalk = function (event) self:walkTo(event.args[1], event.args[2]) end,
        onattack = function (event) self:attackEnemy() end,
        onhit = function (event) self:hit() end,
        ondead = function (event) self:dead() end,
        onmagic = function (event) self:magic() end,
        onleavemagic = function (event) self:leavemagic() end
        },
        })

end

function Player:getID()
    return self.id
end

-- 增加血量
function Player:IncHp(num)
end

-- 减少血量
function Player:ReduceHp(num)
end

-- 增加蓝量
function Player:IncMp(num)
end

-- 减少蓝量
function Player:ReduceMp(num)
end

function Player:AddFrameCallBack(eventName, func)
    self.frameEventList[eventName] = func
end

function Player:DelFrameCallBack(eventName)
    self.frameEventList[eventName] = nil
end

return Player

