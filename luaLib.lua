local _execute = os.execute
local _typeOf = typeOf
local _io = io
local _print = print
local _toast = toast
local _pairs = pairs
local _ipairs = ipairs
local _tostring = tostring
local _tonumber = tonumber
-- math
local _m_floor = math.floor
local _m_random = math.random
-- string
local _s_format = string.format
local _s_gsub = string.gsub
local _s_find = string.find
local _s_sub = string.sub
local _s_gmatch = string.gmatch
local _s_len = string.len
local _s_lower = string.lower
local _s_upper = string.upper
local _s_char = string.char
--
-- ===================================
-- Variable handling Functions
-- ===================================
function gettype(t)
    local ty = _typeOf(t)
    if (ty == "userdata") then
        return (t:typeOf())
    end
    return ty
end

-- Find whether the type of a variable is string
-- ----------------------------------------------
function is_string(s) return _typeOf(s) == "string" end

-- Finds out whether a variable is a boolean
-- ----------------------------------------------
function is_bool(b) return _typeOf(b) == "boolean" end

-- Finds whether a variable is a number or a numeric string
-- ----------------------------------------------
function is_numeric(n) return _tonumber(n) ~= nil end

-- Finds whether the type of a variable is float
-- ----------------------------------------------
function is_float(n) return n ~= _m_floor(n) end

-- Finds whether a variable is an array
-- ----------------------------------------------
function is_table(t) return _typeOf(t) == "table" end

-- print hole table and sub-tables values
-- ----------------------------------------------
print_r = function(t, name, indent)
    table.show = function(t, name, indent)
        local cart -- a container
        local autoref -- for self references

        --[[ counts the number of elements in a table
        local function tablecount(t)
           local n = 0
           for _, _ in pairs(t) do n = n+1 end
           return n
        end
        ]]
        -- (RiciLake) returns true if the table is empty
        local function isemptytable(t) return next(t) == nil end

        local function basicSerialize(o)
            local so = _tostring(o)
            if _typeOf(o) == "function" then
                local info = debug.getinfo(o, "S")
                -- info.name is nil because o is not a calling level
                if info.what == "C" then
                    return _s_format("%q", so .. ", C function")
                else
                    -- the information is defined through lines
                    return _s_format("%q", so .. ", defined in (" ..
                            info.linedefined .. "-" .. info.lastlinedefined ..
                            ")" .. info.source)
                end
            elseif _typeOf(o) == "number" or _typeOf(o) == "boolean" then
                return so
            else
                return _s_format("%q", so)
            end
        end

        local function addtocart(value, name, indent, saved, field)
            indent = indent or ""
            saved = saved or {}
            field = field or name

            cart = cart .. indent .. field

            if _typeOf(value) ~= "table" then
                cart = cart .. " = " .. basicSerialize(value) .. ";\n"
            else
                if saved[value] then
                    cart = cart .. " = {}; -- " .. saved[value]
                            .. " (self reference)\n"
                    autoref = autoref .. name .. " = " .. saved[value] .. ";\n"
                else
                    saved[value] = name
                    --if tablecount(value) == 0 then
                    if isemptytable(value) then
                        cart = cart .. " = {};\n"
                    else
                        cart = cart .. " = {\n"
                        for k, v in _pairs(value) do
                            k = basicSerialize(k)
                            local fname = _s_format("%s[%s]", name, k)
                            field = _s_format("[%s]", k)
                            -- three spaces between levels
                            addtocart(v, fname, indent .. "   ", saved, field)
                        end
                        cart = cart .. indent .. "};\n"
                    end
                end
            end
        end

        name = name or "__unnamed__"
        if _typeOf(t) ~= "table" then
            return name .. " = " .. basicSerialize(t)
        end
        cart, autoref = "", ""
        addtocart(t, name, indent)
        return cart .. autoref
    end
    _print(table.show(t, name, indent))
end

function print(...)
    if is_table(select(1,...)) then
        print_r(...)
    else
        _print(...)
    end
end

-- developer print
-- ----------------------------------------------
function dprint(...) if DEVELOPER == true then print(...) end end

-- developer print_r
-- ----------------------------------------------
function dprint_r(...) if DEVELOPER == true then print_r(...) end end

-- developer toast
-- ----------------------------------------------
function dtoast(...) if DEVELOPER == true then _toast(...) end end


-- ===================================
-- String Functions
-- ===================================


-- Strip whitespace from the beginning and end of a string
-- ----------------------------------------------
function trim(s) return (_s_gsub(s, "^%s*(.-)%s*$", "%1")) end

-- Strip whitespace from the beginning of a string
-- ----------------------------------------------
function ltrim(s) return (_s_gsub(s, "^%s*", "")) end

--  Strip whitespace from the end of a string
-- ----------------------------------------------
function rtrim(s)
    local n = #s
    while n > 0 and _s_find(s, "^%s", n) do n = n - 1 end
    return _s_sub(s, 1, n)
end

-- Split a string by string
-- ----------------------------------------------
function explode(s, d)
    d = d or "%s"
    local array, i = {}, 1
    for str in _s_gmatch(s, "([^" .. d .. "]+)") do
        array[i] = str
        i = i + 1
    end
    return array
end

-- Replace all occurrences of the search string with the replacement string
-- ----------------------------------------------
function str_replace(f, r, s, c)
    c = c or nil
    return _s_gsub(f, r, s, c)
end

-- ===================================
-- Array/Tables Functions
-- ===================================

--  Count all elements in an array, or something in an object
-- ----------------------------------------------
function count(a)
    local count = 0
    for _ in _pairs(a) do count = count + 1 end
    return count
end

--  Checks if a value exists in an array/table
-- ----------------------------------------------
function in_table(tb, v)
    for i, t in _ipairs(tb) do
        if (t == v) then return true end
    end
    return false
end

function table_reverse(t)
    local r = {}
    local i = #t
    for k, v in _ipairs(t) do
        r[i + 1 - k] = v
    end
    return r
end

function table_key_exists(t, key)

    for k, v in _pairs(t) do
        if k == key then
            return true
        elseif is_table(v) then
            return table_key_exists(v, key)
        end
    end
    return false
end

-- Validate table structure and avoid prints
-- ----------------------------------------------
function validate_table(file, rules)
    -- rues for tables
    rules = rules or { "table", "number", "boolean", "string" }

    -- no file given
    if not file then return false, "_file_not_set_" end

    -- check file types
    if not is_string(file) and not is_table(file) then return false, "_file_bad_type" end

    -- if file check if sxists
    if is_string(file) and not fileExists(file) then return false, "_file_not_found_" end

    -- if file is a table
    if is_table(file) then
        for k, v in _pairs(file) do
            if in_table(rules, gettype(v)) then
                if is_table(v) then validate_table(v, rules) end
            else
                return false, "_table_bad_s_format_"
            end
        end
    else
        -- reset prints functions
        local old_print, old_toast, old_print_r, old_dprint, old_dprint_r, old_dtoast = _print, _toast, print_r, dprint, dprint_r, dtoast
        --
        _print, _toast, print_r, dprint, dprint_r, dtoast = nil, nil, nil, nil, nil, nil

        -- secure the load file
        local status, data = pcall(dofile, file)

        -- set print functions
        _print, _toast, print_r, dprint, dprint_r, dtoast = old_print, old_toast, old_print_r, old_dprint, old_dprint_r, old_dtoast

        -- if any error on load
        if status then
            return validate_table(data, rules)
        else
            return false, "_critical_"
        end
    end

    return file
end


-- ===================================
-- Filesystem Functions
-- ===================================

-- Returns trailing name component of path
-- ----------------------------------------------
function basename(p) local t = explode(p, "/") return t[#t] end

-- Returns a parent directory's path
-- ----------------------------------------------
function dirname(s)
    local t, r = explode(s, "/"), ""
    for i, v in _ipairs(t) do
        if i < #t then r = r .. v .. "/" end
    end
    return r
end

-- Returns a parent directory's path
-- ----------------------------------------------
function file_extension(u)
    local s = u
    local t = ""
    local r = ""

    for i = _s_len(s), 1, -1 do
        if _s_sub(s, i, i) ~= "." then
            t = t .. _s_sub(s, i, i)
        else
            break
        end
    end
    for j = _s_len(t), 1, -1 do
        r = r .. _s_sub(t, j, j)
    end

    return r
end

-- Makes directory
-- ----------------------------------------------
function mkdir(p) return _execute('mkdir -p "' .. p .. '"') == 0 end

-- Removes directory
-- ----------------------------------------------
function rmdir(p) return _execute("rm -rf  \"" .. p .. "\"") == 0 end

function copy(s, d) return (mkdir(d) and _execute("cp -rf \"" .. s .. "\" \"" .. d .. "\"") == 0) end

-- Returns information about a file path
-- ----------------------------------------------
function pathinfo(p, op)
    local r = {}
    local l = not op and 4 or 1

    for i = 1, l do
        if op == "PATHINFO_DIRNAME" or l == 4 then
            r["dirname"] = dirname(p)
        end
        if op == "PATHINFO_BASENAME" or l == 4 then
            r["basename"] = basename(p)
        end
        if op == "PATHINFO_EXTENSION" or l == 4 then
            r["extension"] = file_extension(p)
        end
        if op == "PATHINFO_FILENAME" or l == 4 then
            r["filename"] = str_replace(basename(p), "(%.%w+)$", "")
        end
    end

    if l == 1 then return r[_s_lower(str_replace(op, "(.*)%_", ""))]
    else return r
    end
end

-- List files and directories inside the specified path
-- ----------------------------------------------
function scandir(scan_dir, temp)
    temp = temp or "/sdcard/__temp/"
    local list_file = temp .. "_scandir_"
    --
    local create_list_file = 'ls "' .. scan_dir .. '" > ' .. list_file

    if not mkdir(temp) then return false, "_mkdir_" end

    if _execute(create_list_file) ~= 0 then return false, "_list_" end
    local lines = {}

    for line in _io.lines(list_file) do
        lines[#lines + 1] = line
    end

    --if not rmdir(list_file) then return false, "_rmdir_" end
    return lines
end


-- Tells whether the filename is a directory
-- TODO : find another way
-- ----------------------------------------------
function is_dir(dir)
    local f = _io.open(dir .. '__is_dir__', 'w+')
    if f then
        _io.close(f)
        rmdir(dir .. '__is_dir__')
        return true
    end
    return false
end

-- ===================================
-- Android function
-- ===================================


-- simulate home botton
-- ----------------------------------------------
function btn_home() keyevent(3) end

-- simulate back botton
-- ----------------------------------------------
function btn_back(i, w)
    i = i or 1
    w = w or 0.1
    while i > 0 do
        local status, result = pcall(keyevent, 4)

        if not status then
            wait(1)
            _toast("keyevent(4) ERROR")
            _toast("keyevent(4) ERROR")
            _toast("keyevent(4) ERROR")
            pcall(keyevent, 4)
        end

        wait(w)
        i = i - 1
    end
end

-- simulate SWITCH botton
-- ----------------------------------------------
function btn_switch(i, w)
    i = i or 0
    w = w or 0
    while i > 0 do
        keyevent(187)
        i = i - 1
        wait(w)
    end
end


-- ===================================
-- lua essential function
-- ===================================

-- Clone all table and sub tables to avoid the __pairs metamethod.
-- ----------------------------------------------
function clone_table(t)
    local copy
    if is_table(t) then
        copy = {}
        for t_key, t_value in next, t, nil do
            copy[clone_table(t_key)] = clone_table(t_value)
        end
        setmetatable(copy, clone_table(getmetatable(t)))
    else -- number, string, boolean, etc
        copy = t
    end
    return copy
end


-- ===================================
-- others functions
-- ===================================

-- check odd
-- ----------------------------------------------
function odd(n) return not (n % 2 == 0) end

-- creates a random string
-- ----------------------------------------------
function random_string(l)
    local charset = {}

    for i = 48, 57 do table.insert(charset, _s_char(i)) end
    for i = 65, 90 do table.insert(charset, _s_char(i)) end
    for i = 97, 122 do table.insert(charset, _s_char(i)) end

    math.randomseed(os.time())

    if l > 0 then
        return random_string(l - 1) .. charset[_m_random(1, #charset)]
    else
        return ""
    end
end

-- ===================================
-- Ankulua extends
-- ===================================

-- converts a location to string
-- ----------------------------------------------
function location_to_string(loc) return _tostring((_s_format("Location(%d, %d)", loc:getX(), loc:getY()))) end

-- converts a region to string
-- ----------------------------------------------
function region_to_string(r) return _tostring((_s_format("Region(%d, %d, %d, %d)", r:getX(), r:getY(), r:getW(), r:getH()))) end

-- Finds out whether a variable is a Location
-- ----------------------------------------------
function is_location(v) return gettype(v) == "Location" end

-- Finds out whether a variable is a Region
-- ----------------------------------------------
function is_region(v) return gettype(v) == "Region" end

-- Finds out whether a variable is a Match
-- ----------------------------------------------
function is_match(v) return gettype(v) == "Match" end

-- Finds out whether a variable is a Pattern
-- ----------------------------------------------
function is_pattern(v) if gettype(v) == "Pattern" then return true, v:getFileName() end return false, "_none_" end

-- Auto highlight any img,region,match or location
-- ----------------------------------------------
function debug_r(var, title, time)
    if DEBUG_R == true or DEBUG_R == nil then
        local x, y, w, h = 0, 0, 0, 0
        local tp = ""
        time = time or 3
        if is_table(var) then
            x = var[1] y = var[2] w = var[3] or 10 h = var[4] or 10
            tp = not var[3] and "Table(Location)" or "Table(Region)"
        elseif is_region(var) or is_match(var) then
            tp = is_region(var) and "Region" or "Match"
            x = var:getX() y = var:getY() w = var:getW() h = var:getH()
        elseif is_location(var) then
            tp = "Location"
            x = var:getX() - 10 y = var:getY() - 10 w = 20 h = 20
        elseif is_pattern(var) or is_string(var) then
            tp = is_string(var) and "String" or "Pattern"
            if exists(var) then
                local m = getLastMatch()
                local target = m:getTarget()
                local center = m:getCenter()
                x = m:getX() y = m:getY() w = m:getW() h = m:getH()
                _toast("IMG - Target | " .. (title and title or ""))
                Region(target:getX() - 10, target:getY() - 10, 20, 20):highlight(time)
                _toast("IMG - Center | " .. (title and title or ""))
                Region(center:getX() - 10, center:getY() - 10, 20, 20):highlight(time)
            else
                _toast("IMG not found")
            end
        end
        _toast(tp .. " | " .. (title and title or ""))
        Region(x, y, w, h):highlight(time)
    end
end

-- highlight a image(string)
-- ----------------------------------------------
function img_r(v, r, time)
    time = time or 2
    if not is_string(v) then _toast("strign expected at img_r ->" .. gettype(v)) return v end
    v = str_replace(v, ".png", "") .. ".png"
    if DEBUG_R == true or DEBUG_R == nil then
        local t = Timer()
        if r then
            debug_r(r, "Region of :" .. v, time)
            if r:exists(v, 0) then debug_r(r:getLastMatch(), v .. " - time elapsed: " .. t:set(), time) end
        elseif exists(v, 0) then
            debug_r(getLastMatch(), v .. " - time elapsed: " .. t:set(), time)
        end
    end
    return v
end

-- converts a table to string
-- ----------------------------------------------
function table_to_string(table, space)
    space = space or ""
    local text = "{"
    for key, value in _pairs(table) do
        if not is_numeric(key) then text = text .. "\n\t" .. space .. _tostring(key) .. " = "
        end
        if gettype(value) == "Location" then
            text = text .. location_to_string(value)
        elseif gettype(value) == "Region" then
            text = text .. region_to_string(value)
        elseif is_table(value) then
            text = text .. table_to_string(value, space .. "\t")
        elseif is_string(value) then
            text = text .. "'" .. value .. "'"
        elseif (is_bool(value)) then
            text = text .. _tostring(value)
        else
            text = text .. value
        end
        text = text .. ","
    end
    text = text .. "\n" .. space .. "}\n"
    return text
end

-- Return all the values of an region,location,match or table
-- ----------------------------------------------
function get_values(v)
    if is_location(v) then
        return { x = v:getX(), y = v:getY() }
    elseif is_region(v) then
        return { x = v:getX(), y = v:getY(), w = v:getW(), h = v:getH() }
    elseif is_match(v) then
        return { x = v:getX(), y = v:getY(), w = v:getW(), h = v:getH(), center = get_values(v:getCenter()), score = v:getScore(), target = get_values(v:getTarget()) }
    elseif is_table(v) then
        local r = {}
        for k, n in _pairs(v) do
            r[#r + 1] = n
        end
        return r
    elseif is_pattern(v) then
        return get_values(v:getTargetOffset())
    else
        return {}
    end
end

-- Checks the timeout of a variable
-- ----------------------------------------------
function is_timeout(timer, time_out) return timer:check() > time_out end

-- Format seconds to clock time
-- ----------------------------------------------
function get_clock(t)
    t = _tonumber(t)
    local r = { h = 00, m = 00, s = 00 }
    local s = "00:00:00"
    if t > 0 then
        r.h = _s_format("%02.f", _m_floor(t / 3600));
        r.m = _s_format("%02.f", _m_floor(t / 60 - (r.h * 60)));
        r.s = _s_format("%02.f", _m_floor(t - r.h * 3600 - r.m * 60));
        s = r.h .. ":" .. r.m .. ":" .. r.s
    end
    return s, r
end

-- Extend ankulua preferencePut* to save regions
-- lcations and tables
-- ----------------------------------------------
function preferencePutData(v, o)
    if is_region(o) then
        preferencePutString(v, _s_format("Region(%d, %d, %d, %d)", o:getX(), o:getY(), o:getW(), o:getH()))
    elseif is_location(o) then
        preferencePutString(v, _s_format("Location(%d, %d)", o:getX(), o:getY()))
    elseif is_table(o) then
        preferencePutString(v, table_to_string(o))
    else
        return false
    end
    return true
end

--
function preferenceGetData(v, s)
    if is_string(v) and preferenceGetString(v, s) then
        return loadstring('return ' .. preferenceGetString(v, s))()
    end
    return false
end

-- ===================================
-- Alias functions
-- ===================================

-- alias of is_float
is_double = function(...) return is_float(...)
end
-- alias of is_table
is_array = function(...) return is_table(...)
end
-- alias of clone_table
clone_array = function(...) return clone_table(...)
end
-- alias of table_to_string
array_to_string = function(...) return table_to_string(...)
end
-- alias of in_table
in_array = function(...) return in_table(...)
end
-- alias of table_reverse
array_reverse = function(...) return table_reverse(...)
end
-- alias of validate_table
validate_array = function(...) return validate_table(...)
end
-- alias of table_key_exists
array_key_exists = function(...) return table_key_exists(...)
end
-- alias of preferencePutData
preferencePutRegion = function(...) return preferencePutData(...)
end
preferencePutLocation = function(...) return preferencePutData(...)
end
preferencePutTable = function(...) return preferencePutData(...)
end
preferencePutArray = function(...) return preferencePutData(...)
end
-- alias of preferenceGetData
preferenceGetRegion = function(...) return preferenceGetData(...)
end
preferenceGetLocation = function(...) return preferenceGetData(...)
end
preferenceGetTable = function(...) return preferenceGetData(...)
end
preferenceGetArray = function(...) return preferenceGetData(...)
end

-- ===================================
-- ChangeLog
-- ===================================

