local insert = table.insert
local floor = math.floor
local rep = string.rep
local format = string.format
local concat = table.concat
local gsub = string.gsub

-- Init time handlers
local uv,hrtime
local unitMut = 1000
local units = {{1e3,"us"},{1e6,"ms"},{1e9,"sec"}}
if not pcall(function ()
	uv = require "uv"
	hrtime =  uv.hrtime
end) then
	hrtime = os.clock
	units = {{1/1e6,"us"},{1/1e3,"ms"},{1,"sec"}}
end

-- formatters
local function point(x,pos)
	pos = 10^pos
	return floor(x*pos)/pos
end
local indent = " |- "
local points = 4 -- max time point length
local percentPoints = 2 -- max percent point length
local itemFormat = "%s%s: %s%s%s\n%s"
local percentFormat = " (Parent:%s%%,Root:%s%%)"
local function output(thing,indentLevel,str)
	indentLevel = indentLevel or 0
	str = str or ""

	local timestamp = thing._death - thing._birth
	local unit,timestampFormatted

	for _,unitData in ipairs(units) do
		timestampFormatted = timestamp / unitData[1]
		unit = unitData[2]
		if timestampFormatted < unitMut then break end
	end

	local root,parent = thing._root,thing._parent
	thing._timestamp = timestamp

	local footer = ""
	local thisIndent = rep(indent,indentLevel)
	local endDescript = thing._enddescript or ""
	if endDescript then
		local newLine = thisIndent .. " • "
		footer = newLine .. gsub(endDescript,"\n",newLine) .. "\n"
	end

	str = str .. format(itemFormat,
		thisIndent,
		thing._descript or "(No description given)",
		point(timestampFormatted,points),unit,
		root and parent and format(percentFormat,
			tostring(point((timestamp/parent._timestamp)*100,percentPoints)),
			tostring(point((timestamp/root._timestamp  )*100,percentPoints))
		) or "",footer
	)

	local nextIndent = indentLevel + 1
	for _,child in ipairs(thing) do
		str = output(child,nextIndent,str)
	end

	return str
end

local profiler = {}
profiler.__index = profiler

function profiler.New(projectName)
	projectName = projectName or "default"

	local this = {}

	this._project = projectName
	setmetatable(this,profiler)

	return this
end
profiler.new = profiler.New

function profiler:Start(descript)
	local block = self._block
	local new = {
		_descript = descript,
		_parent = block
	}
	if block then
		new._root = self._root
	else
		self._root = new
	end
	insert(block or self,new)
	self._block = new
	new._birth = hrtime()
end
profiler.start = profiler.Start

function profiler:Stop(descript,...)
	local now = hrtime()

	local block = self._block
	if not block then
		error"profiler was already stopped"
	end
	block._death = now
	if descript then
		if select("#",...) ~= 0 then
			descript = format(descript,...)
		end
		block._enddescript = descript
	end
	self._block = block._parent
end
profiler.stop = profiler.Stop

function profiler:Print(index)
	index = index and (index - 1) or 0
	return output(self[#self - index])
end
profiler.print = profiler.Print

function profiler:PrintAll()
	local t = {}
	for _,result in ipairs(self) do
		insert(t,output(result))
	end
	return concat(t)
end
profiler.printAll = profiler.PrintAll

return profiler
