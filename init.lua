
--! 이 라이브러리는 로블록스의 LUA U 를 전혀 호환하지않습니다

local uv = require "uv";
local hrtime =  uv.hrtime;
local insert = table.insert;

local unitMut = 1000;
local units = {
    {1e3,"us"},{1e6,"ms"},{1e9,"sec"}
};

local profiler = {};
profiler.__index = profiler;

function profiler.new(projectName)
    projectName = projectName or "default";

    local this = {};

    this._project = projectName;
    setmetatable(this,profiler);

    return this;
end

function profiler:start(descript)
    local block = self._block;
    local new = {
        _descript = descript;
        _parent = block;
    };
    if block then
        new._root = self._root;
    else
        self._root = new;
    end
    insert(block or self,new);
    self._block = new;
    new._birth = hrtime();
end

function profiler:stop()
    local now = hrtime();

    local block = self._block;
    if not block then
        error"profiler was already stopped";
    end
    block._death = now;
    self._block = block._parent;
end

local floor = math.floor;
local function point(x,pos)
    pos = 10^pos;
    return floor(x*pos)/pos;
end

local indent = " |- ";
local points = 4;
local percentPoints = 2;
local itemFormat = "%s%s: %s%s%s\n";
local percent = " (Par:%s%%,Rot:%s%%)";
local rep = string.rep;
local format = string.format;
local function output(thing,indentLevel,str)
    indentLevel = indentLevel or 0;
    str = str or "";

    local timestamp = thing._death - thing._birth;
    local unit,timestampFormatted;

    for _,unitData in ipairs(units) do
        timestampFormatted = timestamp / unitData[1];
        unit = unitData[2];
        if timestampFormatted < unitMut then break; end
    end

    local root,parent = thing._root,thing._parent;
    thing._timestamp = timestamp;

    str = str .. format(itemFormat,
        rep(indent,indentLevel),
        thing._descript,
        point(timestampFormatted,points),unit,
        root and parent and format(percent,
            tostring(point((timestamp/parent._timestamp)*100,percentPoints)),
            tostring(point((timestamp/root._timestamp  )*100,percentPoints))
        ) or ""
    )

    local nextIndent = indentLevel + 1;
    for _,child in ipairs(thing) do
        str = output(child,nextIndent,str);
    end

    return str;
end

function profiler:print(index)
    index = index and (index - 1) or 0
    return output(self[#self - index]);
end

return profiler;
