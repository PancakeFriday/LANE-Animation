-- see https://www.lua.org/pil/19.3.html
function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
	i = i + 1
	if a[i] == nil then return nil
	else return a[i], t[a[i]]
	end
  end
  return iter
end


-- classic
--
-- Copyright (c) 2014, rxi
--
-- This module is free software; you can redistribute it and/or modify it under
-- the terms of the MIT license. See LICENSE for details.
--

local Object = {}
Object.__index = Object


function Object:new()
end


function Object:extend()
  local cls = {}
  for k, v in pairs(self) do
    if k:find("__") == 1 then
      cls[k] = v
    end
  end
  cls.__index = cls
  cls.super = self
  setmetatable(cls, self)
  return cls
end


function Object:implement(...)
  for _, cls in pairs({...}) do
    for k, v in pairs(cls) do
      if self[k] == nil and type(v) == "function" then
        self[k] = v
      end
    end
  end
end


function Object:is(T)
  local mt = getmetatable(self)
  while mt do
    if mt == T then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
end


function Object:__tostring()
  return "Object"
end


function Object:__call(...)
  local obj = setmetatable({}, self)
  obj:new(...)
  return obj
end

-- END classic

local lume = {}

function lume.deserialize(str)
  return lume.dostring("return " .. str)
end

function lume.dostring(str)
  return assert((loadstring or load)(str))()
end

local Property = Object:extend()

function Property:new(posx, posy, col, row)
	self.pos = {x=posx, y=posy}
	self.scale = {x=1,y=1}
	self.rot=0
	self.color={255,255,255,255}
	self.col, self.row = col, row
end

function Property.getInterpolated(time, ltime, utime, p1, p2)
	local h = function(a,b)
		return a + (b-a)/(utime - ltime) * (time-ltime)
	end
	local pos = {x=h(p1.pos.x,p2.pos.x), y=h(p1.pos.y,p2.pos.y)}
	local scale = {x=h(p1.scale.x,p2.scale.x), y=h(p1.scale.y,p2.scale.y)}
	local rot = h(p1.rot, p2.rot)
	local color = {
		r=h(p1.color.r, p2.color.r),
		g=h(p1.color.g, p2.color.g),
		b=h(p1.color.b, p2.color.b),
		a=h(p1.color.a, p2.color.a)
	}
	local prop = Property(pos.x, pos.y, p1.col, p1.row)
	prop.scale = scale
	prop.rot = rot
	prop.color = color
	return prop
end

function Property:copy(conv)
	conv = conv or tonumber
	local t = Property(1,1,1,1)
	t.pos.x = conv(self.pos.x)
	t.pos.y = conv(self.pos.y)
	t.scale.x = conv(self.scale.x)
	t.scale.y = conv(self.scale.y)
	t.rot = conv(self.rot)
	t.color = {conv(self.color[1]), conv(self.color[2]), conv(self.color[3]), conv(self.color[4])}
	t.row, t.col = conv(self.row), conv(self.col)
	return t
end

local Sprite = Object:extend()

function Sprite:new(d)
	self.quads = {}
	self.name = d.name

	local filedata = love.filesystem.newFileData(d.img,d.name)
	local imgdata = love.image.newImageData(filedata)
	local img = love.graphics.newImage(imgdata)

	self.img = img
	self.imgsettings = d.imgsettings

	for i,v in pairs(d.quads) do
		if not self.quads[i] then
			self.quads[i] = {}
		end
		for j,k in pairs(v) do
			self.quads[i][j] = love.graphics.newQuad(unpack(k))
		end
	end
end

local Animation = Object:extend()

function Animation:new(d, sprites)
	self.time = 0
	self.playing = false
	self.maxTime = d.maxTime

	self.sprites = sprites

	self.keys = d.keys
	for i, key in pairs(self.keys) do
		for time, value in pairs(key.frames) do
			setmetatable(value.properties, Property)
		end
	end
end

function Animation:play()
	self.playing = true
end

function Animation:stop()
	self.playing = false
	self.time = 0
end

function Animation:pause()
	self.playing = false
end

function Animation:draw()
	for i,key in pairs(self.keys) do
		local lind, uind = self:getLowerIndex(key, self.time)
		if lind and tonumber(lind) <= self.time then
			local img, quads, props, qw, qh = self:getInterpolatedSprite(key, self.time, lind, uind)
			if img then
				love.graphics.setColor(props.color.r, props.color.g, props.color.b, props.color.a)
				love.graphics.draw(img,
					quads[props.col][props.row],
					props.pos.x,
					props.pos.y,
					props.rot,
					props.scale.x,
					props.scale.y,
					qw/2,
					qh/2)
			end
		end
	end

	love.graphics.setColor(255,255,255)
end

function Animation:getLowerIndex(key, time)
	local sort = function(a,b)
		return tonumber(a)<tonumber(b)
	end
	time = tonumber(time)
	local prevktime
	for ktime, value in pairsByKeys(key.frames, sort) do
		if tonumber(ktime) == time then
			return ktime
		elseif tonumber(ktime) > time and prevktime and tonumber(prevktime) < time then
			return prevktime, ktime
		end
		prevktime = ktime
	end

	return prevktime
end

function Animation:getInterpolatedSprite(key, time, lind, uind)
	if not uind then
		local img = self.sprites[key.frames[lind].spritehash].img
		local quads = self.sprites[key.frames[lind].spritehash].quads
		local props = key.frames[lind].properties
		if not quads[props.col] or not quads[props.col][props.row] then
			return nil
		end
		local _, _, qw, qh = quads[props.col][props.row]:getViewport()
		return img, quads, props, qw, qh
	else
		local img = self.sprites[key.frames[lind].spritehash].img
		local quads = self.sprites[key.frames[lind].spritehash].quads
		local props = Property.getInterpolated(tonumber(time), tonumber(lind), tonumber(uind), key.frames[lind].properties, key.frames[uind].properties)
		if not quads[props.col] or not quads[props.col][props.row] then
			return nil
		end
		local _, _, qw, qh = quads[props.col][props.row]:getViewport()
		return img, quads, props, qw, qh
	end
end

function Animation:update(dt)
	if self.playing then
		self.time = (self.time + dt)%self.maxTime
	end
end

local Ani = Object:extend()

function Ani:new(fname)
	local f = io.open(fname, "r")
	local d = f:read("*all")
	f:close()

	self.sprites = {}
	local t = lume.deserialize(d)
	for i,v in pairs(t.sprites) do
		self.sprites[i] = Sprite(v)
	end
	self.animations = {}
	for i,v in pairs(t.animations) do
		self.animations[i] = Animation(v, self.sprites)
	end

	self.current = ""
end

function Ani:getNames()
	local t = {}
	for name,_ in pairs(self.animations) do
		table.insert(t,name)
	end
	return t
end

function Ani:setCurrent(s)
	for name,v in pairs(self.animations) do
		if s == name then
			self.current = s
			return true
		end
	end
	return false
end

function Ani:play()
	if self.current ~= "" then
		self.animations[self.current]:play()
	end
end

function Ani:stop()
	if self.current ~= "" then
		self.animations[self.current]:stop()
	end
end

function Ani:pause()
	if self.current ~= "" then
		self.animations[self.current]:pause()
	end
end

function Ani:draw()
	if self.current ~= "" then
		self.animations[self.current]:draw()
	end
end

function Ani:update(dt)
	if self.current ~= "" then
		self.animations[self.current]:update(dt)
	end
end

return Ani
