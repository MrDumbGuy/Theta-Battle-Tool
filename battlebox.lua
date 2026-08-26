require "animate"

Battlebox = Object:extend()

function Battlebox:new()

    self.name = "BATTLEBOX"

    self.animations = {
        ["opening"] = {name = "opening", length = 17, FPS = 30, looping = false},
        ["still"] = {name = "still", length = 1, FPS = 1, looping = true},
        ["closing"] = {name = "closing", length = 28, FPS = 30, looping = false},
        ["invisible"] = {name = "invisible", length = 1, FPS = 1, looping = true},
   }

    self.spritesheet = love.graphics.newImage("sprites/battlebox.png")

    local sheetjson = io.open("sprites/battlebox.json", "r")
    if sheetjson then
        local sheetarr = sheetjson:read("*a")
        self.spritesheetarray = json.decode(sheetarr)
        sheetjson:close()
    end

    self.quadrants = {
        ["opening"] = {},
        ["still"] = {},
        ["closing"] = {},
        ["invisible"] = {}
    }

    self.quadrantoffsets = {
        ["opening"] = {},
        ["still"] = {},
        ["closing"] = {},
        ["invisible"] = {}
    }

    local sheetwidth, sheetheight = self.spritesheetarray.meta.size.w, self.spritesheetarray.meta.size.h

    for i = 1, 17 do
        if i >= 10 then
            local localquad = self.spritesheetarray.frames["BBS_00"..i..".png"].frame
            self.quadrants["opening"][i] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetwidth, sheetheight)
            self.quadrantoffsets["opening"][i] = {}
            self.quadrantoffsets["opening"][i].w = (361 - localquad.w)/2
            self.quadrantoffsets["opening"][i].h = (363 - localquad.h)/2
        else
            local localquad = self.spritesheetarray.frames["BBS_000"..i..".png"].frame
            self.quadrants["opening"][i] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetwidth, sheetheight)
            self.quadrantoffsets["opening"][i] = {}
            self.quadrantoffsets["opening"][i].w = (361 - localquad.w)/2
            self.quadrantoffsets["opening"][i].h = (363 - localquad.h)/2
        end
    end

    local localquad = self.spritesheetarray.frames["BBS_0017.png"].frame
    self.quadrants["open"][1] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetwidth, sheetheight)
    self.quadrantoffsets["open"][1] = {}
    self.quadrantoffsets["open"][1].w = (361 - localquad.w)/2
    self.quadrantoffsets["open"][1].h = (363 - localquad.h)/2

    for i = 1, 28 do
        localquad = self.spritesheetarray.frames["BBS_00"..(i+17)..".png"].frame
        self.quadrants["closing"][i] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetwidth, sheetheight)
        self.quadrantoffsets["closing"][i] = {}
        self.quadrantoffsets["closing"][i].w = (361 - localquad.w)/2
        self.quadrantoffsets["closing"][i].h = (361 - localquad.h)/2
    end

    localquad = self.spritesheetarray.frames["BBS_0046.png"].frame
    self.quadrants["invisible"][1] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetwidth, sheetheight)

    self.currentanimation = "invisible"
    self.currentframecount = 1

    self.animationSpecialLoops = {
        ["opening"] = "still",
        ["closing"] = "invisible",
    }

    self.top = 200
    self.bottom = 483
    self.left = 500
    self.right = 783

end

function Battlebox:draw()
    if self.currentquadrant
    and self.currentanimation
    and self.currentframecount
    and self.quadrantoffsets[self.currentanimation] then
        if self.quadrantoffsets[self.currentanimation][math.floor(self.currentframecount)] then
            love.graphics.draw(self.spritesheet, self.currentquadrant, self.left + self.quadrantoffsets[self.currentanimation][math.floor(self.currentframecount)].w, self.top + self.quadrantoffsets[self.currentanimation][math.floor(self.currentframecount)].h)
        end
        --TODO Figure out why the unexpected offset is exctly 38 pixels
    end
end

function Battlebox:set_animation(animation)

    self.currentanimation = animation
    self.currentframecount = 1

end

function Battlebox:update(dt)

    AnimateQuadrants(self, dt, self.animationSpecialLoops)

end