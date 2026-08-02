Object = require "classic"
require "partyMember"
require "background"
require "battleui"
require "battlebar"
require "soul"
require "submenu"
require "battlebox"
require "bullet"
flux = require "flux"
tick = require "tick"
json = require "json"
local tlfres = require "tlfres"
require "item"
require "itemmanager"
Controller = require "battlecontroller" --The battle middle-manager. Intentionally global.

--Best for blurless scaling
love.graphics.setDefaultFilter( "nearest", "nearest", 1)

--Place constant values here.

local WIDTH = 1280
local HEIGHT = 960

local ARR_STATES = {--UI Buttons to states as used in Controller.current_state
                    --MAGIC will also be used in ACTUI since behavior is similar enough
                    --It still has a graphical difference (magic button over act button) but no functional one.
    "ATTACKUI",
    "ACTUI",
    "ITEMUI",
    "SPAREUI",
    "DEFEND",
}

--The game's fonts.
--These need to be global because too many engine components rely on them.
--They're also present in every Deltarune battle ever
--If you need your own fonts, feel free to load them in your Encounter() and implement custom fonts for your draw() calls!
Battlefont = love.graphics.newFont("fonts/8bitOperatorPlus-Bold.ttf", 30)
Goldenfont = love.graphics.newImageFont("sprites/goldennumeralfont.png", "0123456789+-%/ ")--The mercy increased font
HPfont = love.graphics.newFont("fonts/deltarune-hp-font.otf", 14)

--Basic sound effects.
--Again, only global because these are present in every encounter
--You can load your custom sound effects in your battle!
SND_MENUMOVE = love.audio.newSource("sfx/snd_menumove.wav", "static")
SND_SELECT = love.audio.newSource("sfx/snd_select.wav", "static")
SND_ATTACK = love.audio.newSource("sfx/snd_attack.wav", "static")

--Place state-tracking variables here

selected_enemy = nil

local SplashScreen = love.graphics.newImage("sprites/ThetaBattleTool-Titlecard.png")

--Just in case I add a menu for changing battles or something.
local battling

--TODO Move most of these to the Controller object. The Controller is meant to be the middle-manager for the battle, so it should handle most of these variables.
local members_to_attack
local enemies_to_attack
local battlebars

local actname
local actindex

--Arrays used for submenus:
local selected_enemies

--The encounter object.

--[[
    Although you can, I'd advise against placing anything battle-specific here.
    That kind of defeats the point of having made an engine instead of a messily-coded fangame.
    (Also in the far future there's a chance support is added for an exchangable battle loader)
]]

function love.load()

    battling = false

end

local function startBattle()

    members_to_attack = {}
    enemies_to_attack = {}
    battlebars = {}
    actindex = {}
    actindex = {}
    selected_enemies = {}

    Controller:load()
    battling = true

end

function love.update(dt)

    if battling then
        Controller:update(dt)

        for i = 1, #battlebars do
            if battlebars[i] then
                battlebars[i]:update(dt)
            end
        end

        tick.update(dt)

        flux.update(dt)

        local battleovercheck = true

        for i = 1, #Controller.battle.enemies do
            if Controller.battle.enemies[i] then
                if Controller.battle.enemies[i].hp > 0 then
                    battleovercheck = false
                    break
                end
            end
        end

        if battleovercheck then
            Controller:setState("BATTLEOVER")
        end

        if Controller:getState() == "BATTLEOVER" then
            for i = 1, #Controller.battle.party_members do
                Controller.battle.UIs[i]:subtext("* Battle is over!\n* Press any key to exit.")
            end
            Sole:updatePosArray(nil)
        end
    end

end

local function BULLETSCleanup()

    Controller.battle.Box:set_animation(3)
    Sole:updateLimits(Controller.battle.Box)

    --Collect garbage and reset to first party member.
    Controller:setPartyMember(1)
    selected_enemies = {}
    actname = {}
    actindex = {}
    Controller:BULLETSCleanup()
    collectgarbage("collect")

end

local function StartBULLETS()
        --Collect garbage
        members_to_attack = {}
        enemies_to_attack = {}
        battlebars = {}
        collectgarbage("collect")

        Controller:setPartyMember(1)
        for i = 1, #Controller.battle.party_members do
            Controller.battle.UIs[i]:subtext("")
        end
        Controller.battle.Box:set_animation(1)
        Sole:updateLimits(Controller.battle.Box)
        Sole:centerInBox()
        tick.delay(function() BULLETSCleanup() end, 5)
        Controller:setState("BULLETS")
end

local function ExecuteAttack(enemies)

    print("ExecuteAttack()")
    print("Controller:getPartyMember(): "..Controller:getPartyMember())

    Controller:setState("ATTACKING")

    if #members_to_attack > 0 and #battlebars == 0 then
        print("members_to_attack: "..#members_to_attack)

        for i = 1, #members_to_attack do
            local k = 1
            local baroffsetcoefficient = 1 --Used to position the battlebars correctly

            while k < #Controller.battle.party_members + 1 do
                if Controller.battle.party_members[k] == members_to_attack[i] then
                    baroffsetcoefficient = k
                    print("baroffsetcoefficient: "..baroffsetcoefficient)
                end
                k = k+1
            end

            battlebars[i] = BattleBar(900+100*baroffsetcoefficient, 738+41*1.5*(baroffsetcoefficient-1), i,Controller.battle.party_members)

        end

    elseif Controller:getPartyMember() <= #battlebars then

        if battlebars[Controller:getPartyMember()] then
            battlebars[Controller:getPartyMember()]:attack(enemies, enemies_to_attack, members_to_attack)
        end

    end

    if Controller:getPartyMember() > #battlebars then

        Controller.doneNavigating = true

        StartBULLETS()

    end


end

--Don't touch this unless you are CERTAIN you know what you are doing.
--This function handles every command passed through the UI.
--That means all of FIGHT/ACT...MERCY is handled here.

local function ExecuteCommands()

    Controller:setState("COMMANDS")

    print("ExecuteCommands()")

    local CommandReturned
    Controller:setPartyMember(Controller:getPartyMember() + 1)

    print("Controller:getPartyMember() @ COMMANDS: "..Controller:getPartyMember())

    if Controller:getPartyMember() <= #Controller.battle.party_members then
        if Controller:getCommand(Controller:getPartyMember(), 1) then --TODO Ensure that the Command for a downed partyMember is empty.
            Controller.battle.UIs[Controller:getPartyMember()]:subtext(Controller:getCommand(Controller:getPartyMember(),2))
            CommandReturned = Controller:runCommand(Controller:getPartyMember(), 1)
            if CommandReturned then print("Command executed: "..CommandReturned.." by: "..Controller.battle.party_members[Controller:getPartyMember()].name) end
        end
    end
    if CommandReturned == "DEFCOMMAND" then
        Controller.battle.party_members[Controller:getPartyMember()].isdefending = true
        ExecuteCommands()
    elseif CommandReturned == "ATTACKCOMMAND" then
        members_to_attack[#members_to_attack+1] = Controller.battle.party_members[Controller:getPartyMember()]
        print("Latest member to attack: "..members_to_attack[#members_to_attack].name)
        ExecuteCommands()
    end

    if Controller:getPartyMember() >= #Controller.battle.party_members + 1 then

        Controller:BULLETSCleanup()

        for i = 1, #Controller.battle.party_members do
            Controller.battle.party_members[i].hpup = nil
        end

        if #members_to_attack > 0 then

            Controller:setPartyMember(1)

            for i = 1, #Controller.battle.party_members do
                Controller.battle.UIs[i]:subtext("")
            end
            Controller:setState("ATTACKING")
            ExecuteAttack()
        else
            Controller.doneNavigating = true
            StartBULLETS()
        end

    end

end

function love.mousepressed(x, y, button)

    if button == 1 then
        print(x..", "..y)
    end

end

function love.keypressed(key)

    if battling then

        print("Controller's state = "..Controller:getState())

        if Controller:getState() == "COMMANDS" then

            if Controller:getPartyMember() <= #Controller.battle.party_members then
                ExecuteCommands()
            end

        elseif Controller:getState() == "ATTACKING" and key == "z" then

            ExecuteAttack(Controller.battle.enemies)

        elseif Controller:getState() == "BATTLEOVER" then
            love.event.quit()
        end

        if Controller:getState() ~= "BULLETS" then
            print("Current State: "..Controller:getState())
            print("Party Member:"..Controller:getPartyMember())
        end

        --This has to run after  the above to prevent misfires.

        selected_enemies, enemies_to_attack, actname, actindex = Controller:heartBeat(key, ARR_STATES, selected_enemies, enemies_to_attack, actname, actindex)

        --Go back to the Battle UI or move on to executing every command?
        if Controller.doneNavigating and Controller:getPartyMember() > #Controller.battle.party_members then
            Controller:setPartyMember(0)
            Controller:setState("COMMANDS")
            ExecuteCommands()
            Sole:updatePosArray(nil)
        elseif Controller.doneNavigating and Controller:getState() ~= "BULLETS" and Controller:getState() ~= "COMMANDS" and Controller:getState() ~= "ATTACKING" then
            Controller.battle.UIs[Controller:getPartyMember()]:subtext("* A wild battle commentary appeared!")
            Controller.battle.UIs[Controller:getPartyMember()]:menuState(Sole, 0, 0, "BATTLEUI", {})
            Controller:setState("BATTLEUI")
            Controller.doneNavigating = false
            selected_enemy = nil
        end
    else

        if key == "z" then
            startBattle()
    
        end

    end
end

function love.draw()

    tlfres.beginRendering(WIDTH, HEIGHT)

    if battling then

        love.graphics.setPointSize(tlfres.getScale())

        Controller:drawBackground()

        --UI Purple line (top)
        love.graphics.setColor(51/255, 32/255, 51/255)
        love.graphics.rectangle("fill", 0, 684, 1280, 4)

        --UI Background (black)
        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("fill",0,687,1280,273)

        --UI Purple line (bottom)
        love.graphics.setColor(51/255, 32/255, 51/255)
        love.graphics.rectangle("fill", 0, 733, 1280, 4)

        love.graphics.setColor(1,1,1,1) --If you don't set to white when drawing images, the image colors get altered.

        Controller:drawForeground()

        for i = 1, #Controller.battle.UIs do
            Controller.battle.UIs[i]:draw(Controller:getState(), Controller.battle.party_members)
        end

        for i = 1, #battlebars do
            battlebars[i]:draw()
        end

        Sole:draw(Controller:getState())

    else

        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(SplashScreen, 0, 0)
        love.graphics.setFont(Battlefont)
        love.graphics.print("Press Z to start the battle!", WIDTH/3-50, 700, 0)
        love.graphics.setColor(0.37,1,0.75,1)
        love.graphics.print("TBT (c) SEDAT ARITÜRK 2026", WIDTH/3-50, 750)
        love.graphics.setColor(1,0,0,1)
        love.graphics.print("SEE README, LICENSE & CREDITS", WIDTH/3-50, 800)

    end

    local FPS = love.timer.getFPS()

    if FPS >= 30 then
        love.graphics.setColor(0,1,0,1)
    elseif 30 >= FPS and FPS > 15 then
        love.graphics.setColor(1,1,0,1)
    elseif FPS < 15 then
        love.graphics.setColor(1,0,0,1)
    end

    love.graphics.setFont(Battlefont)
    love.graphics.print("FPS:"..FPS, 0, 0, 0, 1, 1)

    tlfres.endRendering()

    FPS = nil

end