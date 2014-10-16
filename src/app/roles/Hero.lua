
local Progress = import("..ui.Progress")
local scheduler = require("framework.scheduler")
local Effect = import("..module.Effect")
local Skill = import("..module.Skill")

local Hero = class("Hero", function()
        return display.newNode()
    end)

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
    self.attack = heroConf.Attack*5
    self.hp = heroConf.HP
    self.maxHp = heroConf.HP
    self.skills = {heroConf.Skill_1, heroConf.Skill_2, heroConf.Skill_3, heroConf.Skill_4}
    self.powers = {0,0,0,0}
    self.maxPowers = {Skill:getNeedPower(heroConf.Skill_1),
                        Skill:getNeedPower(heroConf.Skill_2),
                        Skill:getNeedPower(heroConf.Skill_3),
                        Skill:getNeedPower(heroConf.Skill_4)}
    self.skillsReady = {false,false,false,false}
end

-- 初始化动画信息
function Hero:initArmature(heroConf)
    local manager = ccs.ArmatureDataManager:getInstance()
    manager:addArmatureFileInfo("armature/" .. heroConf.Armature .. ".ExportJson")
    self.armature = ccs.Armature:create("Hero")

    self:addChild(self.armature)

    self.armature:setScaleX(0.5)
    self.armature:setScaleY(0.5)

    if self.side == 1 then
        self:setPosition(cc.p(display.left+self.armature:getBoundingBox().width/2, display.cy-80))
    else
        self.armature:setScaleX(-0.5)
        self:setPosition(cc.p(display.right-self.armature:getBoundingBox().width, display.cy-80))
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
        if movementType == ccs.MovementEventType.complete and 
            (movementID == "attack" or movementID == "smitten") then
            self:doEvent("stop")
        end
    end
    self.armature:getAnimation():setMovementEventCallFunc(animationEvent)

    -- 帧事件
    local function checkCollision(dt)
        self:setLocalZOrder(10000 - self:getPositionY())
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
    size.width = size.width * math.abs(self.armature:getScaleX())
    size.height = size.height * math.abs(self.armature:getScaleY())
    self:addChild(self.progress)

    local barSize = self.progress:getContentSize()
    self.progress:setPosition(0, size.height)
    self.progress:setScale(0.8)
end

-- 更新头顶血条显示
function Hero:updateHpBar()
    self.progress:setProgress(self.hp/self.maxHp*100)
    local skillPanel = display.getRunningScene().skillPanel
    skillPanel:UpdateDisplay()
end

function Hero:DoAttack()
    if self:getState() ~= 'idle' then
        self:doEvent("stop")
    end

    self:doEvent("doAttack")
end

function Hero:DoMagic(circul)
    if self:getState() ~= 'idle' then
        self:doEvent("stop")
    end

    if not circul then
        circul = -1
    end

    self:doEvent("doMagic", circul)
end

function Hero:idle()
    transition.stopTarget(self)
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
        self:stopAction(self.moveAction)
        self.moveAction = nil
    end

    local currentPos = cc.p(self:getPosition())
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

    self:runAction(self.moveAction)
    return true
end

function Hero:doAttack()
    transition.stopTarget(self)
    local target = Skill:GetSufferer(nil, self, "closest_point")
    if not target then
        print("no target")
        return
    end

    --调整朝向
    if self:getPositionX() > target:getPositionX() then
        self.armature:setScaleX(-0.5)
    else
        self.armature:setScaleX(0.5)
    end

    self.armature:getAnimation():play("attack")

    local function normalattack()
        self:DelFrameCallBack("onDamageEvent")
        local starPos = self.armature:convertToWorldSpace(cc.p(self.armature:getBone("atkpoint"):getPosition()))
        local targetPos = cc.p(target:getPosition())
        self.atkeff = display.newSprite("effect/eff_atk.png", starPos.x, starPos.y)
        display.getRunningScene():addChild(self.atkeff)
        self.atkeff:setLocalZOrder(self:getLocalZOrder())
        local angle = cc.pToAngleSelf(cc.pSub(targetPos, starPos))
        self.atkeff:setRotation(-math.deg(angle))
        local distance = cc.pGetDistance(starPos, targetPos)
        local action = transition.sequence(
            {cc.MoveTo:create(distance / display.width, targetPos), 
            cc.CallFunc:create(function()
                if target.hp > 0 then
                    target:ReduceHp(self.attack)
                    if target.hp > 0 then
                        target:doEvent("beHit")
                    end
                    self:IncPower(200)
                end
                self.atkeff:removeSelf()
                self.atkeff=nil
                end)})
        self.atkeff:runAction(action)
    end

    self:AddFrameCallBack("onDamageEvent", normalattack)
end

function Hero:magic(circul)
    transition.stopTarget(self)
    self.armature:getAnimation():play("attack", -1, circul)
end

function Hero:leavemagic()
    -- transition.stopTarget(self)
    Skill:EndSkill(self)
end

function Hero:hit()
    if self.hp == 0 then
        self:doEvent("beKilled")
        return
    end
    self.armature:getAnimation():play("smitten")
end

function Hero:dead()        
    scheduler.performWithDelayGlobal(function()
            self:doEvent("stop")
            self:IncHp(self.maxHp)
            end, 3)
    self.armature:getAnimation():play("death")
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
        {name = "stop", from = {"walk", "attack", "hit", "magic", "dead"}, to = "idle"},
        {name = "doMagic", from = {"idle", "walk"}, to = "magic"},
        },

        callbacks = {
        onidle = function (event) self:idle() end,
        onwalk = function (event) self:walkTo(event.args[1], event.args[2]) end,
        onattack = function (event) self:doAttack() end,
        onhit = function (event) self:hit() end,
        ondead = function (event) self:dead() end,
        onmagic = function (event) self:magic(event.args[1]) end,
        onleavemagic = function (event) self:leavemagic() end
        },
        })

end

function Hero:getID()
    return self.id
end

-- 增加血量
function Hero:IncHp(num)
    self.hp = self.hp + num
    if self.hp > self.maxHp then
        self.hp = self.maxHp
    end
    self:updateHpBar()
end

-- 减少血量
function Hero:ReduceHp(num)
    self.hp = self.hp - num
    if self.hp <= 0 then
        self.hp = 0
        self:doEvent("beKilled")
    end
    self:updateHpBar()
end

-- 增加能量
function Hero:IncPower(num)
    for i = 1, #self.powers do
        self.powers[i] = self.powers[i] + num
        if self.powers[i] >= self.maxPowers[i] then
            self.powers[i] = self.maxPowers[i]
            -- 技能准备完毕
            self.skillsReady[i] = true
        end
    end
    local skillPanel = display.getRunningScene().skillPanel
    skillPanel:UpdateDisplay()
end

-- 减少能量
function Hero:ReducePower(num, index)
    if index < 0 or index > #self.powers then
        print("ReducePower index error [" .. index .. "]")
        return
    end

    self.powers[index] = self.powers[index] - num
    -- 技能重新准备
    self.skillsReady[index] = false
    if self.powers[index] < 0 then
        self.powers[index] = 0
    end
    local skillPanel = display.getRunningScene().skillPanel
    skillPanel:UpdateDisplay()
end

function Hero:AddFrameCallBack(eventName, func)
    self.frameEventList[eventName] = func
end

function Hero:DelFrameCallBack(eventName)
    self.frameEventList[eventName] = nil
end

return Hero

