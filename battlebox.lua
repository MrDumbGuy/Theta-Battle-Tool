require "animate"

Battlebox = Object:extend()

function Battlebox:new()

    self.name = "BATTLEBOX"

    self.animations = {
        [1] = {"opening", 17, 30, false},
        [2] = {"still", 1, 1, true},
        [3] = {"closing", 28, 30, false},
        [4] = {"invisible", 1, 1, true},
   }

    self.spritesheet = love.graphics.newImage("sprites/battlebox.png")

    local sheetjson = io.open("sprites/battlebox.json", "r")
    if sheetjson then
        local sheetarr = sheetjson:read("*a")
        self.spritesheetarray = json.decode(sheetarr)
        sheetjson:close()
    end

    self.quadrants = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {}
    }

    self.quadrantoffsets = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {}
    }

    local sheetwidth, sheetheight = self.spritesheetarray.meta.size.w, self.spritesheetarray.meta.size.h

    for i = 1, 17 do
        if i >= 10 then
            local localquad = self.spritesheetarray.frames["BBS_00"..i..".png"].frame
            self.quadrants[1][i] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetwidth, sheetheight)
            self.quadrantoffsets[1][i] = {}
            self.quadrantoffsets[1][i].w = (361 - localquad.w)/2
            self.quadrantoffsets[1][i].h = (363 - localquad.h)/2
        else
            local localquad = self.spritesheetarray.frames["BBS_000"..i..".png"].frame
            self.quadrants[1][i] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetwidth, sheetheight)
            self.quadrantoffsets[1][i] = {}
            self.quadrantoffsets[1][i].w = (361 - localquad.w)/2
            self.quadrantoffsets[1][i].h = (363 - localquad.h)/2
        end
    end

    local localquad = self.spritesheetarray.frames["BBS_0017.png"].frame
    self.quadrants[2][1] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetwidth, sheetheight)
    self.quadrantoffsets[2][1] = {}
    self.quadrantoffsets[2][1].w = (361 - localquad.w)/2
    self.quadrantoffsets[2][1].h = (363 - localquad.h)/2

    for i = 1, 28 do
        local localquad = self.spritesheetarray.frames["BBS_00"..(i+17)..".png"].frame
        self.quadrants[3][i] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetwidth, sheetheight)
        self.quadrantoffsets[3][i] = {}
        self.quadrantoffsets[3][i].w = (361 - localquad.w)/2
        self.quadrantoffsets[3][i].h = (361 - localquad.h)/2
    end

    localquad = self.spritesheetarray.frames["BBS_0046.png"].frame
    self.quadrants[4][1] = love.graphics.newQuad(localquad.x, localquad.y, localquad.w, localquad.h, sheetwidth, sheetheight)

    self.currentanimation = 4
    self.currentframecount = 1

    self.animationSpecialLoops = {
        [1] = 2,
        [3] = 4,
    }

    self.top = 200
    self.bottom = 483
    self.left = 500
    self.right = 783

end

function Battlebox:draw()
    if self.currentquadrant and self.currentanimation and self.currentframecount and self.quadrantoffsets[self.currentanimation][math.floor(self.currentframecount)] then
        love.graphics.draw(self.spritesheet, self.currentquadrant, self.left - 38 + self.quadrantoffsets[self.currentanimation][math.floor(self.currentframecount)].w, self.top - 38 + self.quadrantoffsets[self.currentanimation][math.floor(self.currentframecount)].h)
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