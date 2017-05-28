-- ===================================
-- Variable handling Functions
-- ===================================
gettype = function(t)
    local ty = typeOf(t)
    if (ty == "userdata") then
        return (t:typeOf())
    end
    return ty
end

-- Find whether the type of a variable is string
-- ----------------------------------------------
is_string = function(s) if (typeOf(s) == "string") then return true end end

-- Finds out whether a variable is a boolean
-- ----------------------------------------------
is_bool = function(b) if typeOf(b) == "boolean" then return true end return false end

-- Finds whether a variable is a number or a numeric string
-- ----------------------------------------------
is_numeric = function(n) if tonumber(n) ~= nil then return true end return false end

-- Finds whether the type of a variable is float
-- ----------------------------------------------
is_float = function(n) if n ~= math.floor(n) then return true end return false end

-- Finds whether a variable is an array
-- ----------------------------------------------
is_table = function(t) if (typeOf(t) == "table") then return true end return false end

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
            local so = tostring(o)
            if typeOf(o) == "function" then
                local info = debug.getinfo(o, "S")
                -- info.name is nil because o is not a calling level
                if info.what == "C" then
                    return string.format("%q", so .. ", C function")
                else
                    -- the information is defined through lines
                    return string.format("%q", so .. ", defined in (" ..
                            info.linedefined .. "-" .. info.lastlinedefined ..
                            ")" .. info.source)
                end
            elseif typeOf(o) == "number" or typeOf(o) == "boolean" then
                return so
            else
                return string.format("%q", so)
            end
        end

        local function addtocart(value, name, indent, saved, field)
            indent = indent or ""
            saved = saved or {}
            field = field or name

            cart = cart .. indent .. field

            if typeOf(value) ~= "table" then
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
                        for k, v in pairs(value) do
                            k = basicSerialize(k)
                            local fname = string.format("%s[%s]", name, k)
                            field = string.format("[%s]", k)
                            -- three spaces between levels
                            addtocart(v, fname, indent .. "   ", saved, field)
                        end
                        cart = cart .. indent .. "};\n"
                    end
                end
            end
        end

        name = name or "__unnamed__"
        if typeOf(t) ~= "table" then
            return name .. " = " .. basicSerialize(t)
        end
        cart, autoref = "", ""
        addtocart(t, name, indent)
        return cart .. autoref
    end
    print(table.show(t, name, indent))
end


-- ===================================
-- String Functions
-- ===================================


-- Strip whitespace from the beginning and end of a string
-- ----------------------------------------------
trim = function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end

-- Strip whitespace from the beginning of a string
-- ----------------------------------------------
ltrim = function(s) return (s:gsub("^%s*", "")) end

--  Strip whitespace from the end of a string
-- ----------------------------------------------
rtrim = function(s)
    local n = #s
    while n > 0 and s:find("^%s", n) do n = n - 1 end
    return s:sub(1, n)
end

-- Split a string by string
-- ----------------------------------------------
explode = function(s, d)
    d = d or "%s"
    local array, i = {}, 1
    for str in string.gmatch(s, "([^" .. d .. "]+)") do
        array[i] = str
        i = i + 1
    end
    return array
end

-- Replace all occurrences of the search string with the replacement string
-- ----------------------------------------------
str_replace = function(f, r, s, c)
    c = c or nil
    return string.gsub(f, r, s, c)
end

-- ===================================
-- Array/Tables Functions
-- ===================================

--  Count all elements in an array, or something in an object
-- ----------------------------------------------
count = function(a)
    local count = 0
    for _ in pairs(a) do count = count + 1 end
    return count
end

--  Checks if a value exists in an array/table
-- ----------------------------------------------
function in_table(tb, v)
    for i, t in ipairs(tb) do
        if (t == v) then return true end
    end
    return false
end

-- ===================================
-- Filesystem Functions
-- ===================================

-- Tells whether the filename is a directory
-- TODO : find another way
-- ----------------------------------------------
is_dir = function(s) if is_string(s) and not s:match("(.+)%..+") then return true end return false end

-- Returns trailing name component of path
-- ----------------------------------------------
basename = function(p) local t = explode(p, "/") return t[#t] end

-- Returns a parent directory's path
-- ----------------------------------------------
dirname = function(s)
    local t, r = explode(s, "/"), ""
    for i, v in ipairs(t) do
        if i < #t then r = r .. v .. "/" end
    end
    return r
end

-- Returns a parent directory's path
-- ----------------------------------------------
file_extension = function(u)
    local s = u
    local t = ""
    local r = ""

    for i = s:len(), 1, -1 do
        if s:sub(i, i) ~= "." then
            t = t .. s:sub(i, i)
        else
            break
        end
    end
    for j = t:len(), 1, -1 do
        r = r .. t:sub(j, j)
    end

    return r
end

-- Makes directory
-- ----------------------------------------------
mkdir = function(p) if os.execute("mkdir -p \"" .. p .. "\"") == 0 then return true end return false end

-- Removes directory
-- ----------------------------------------------
rmdir = function(p) if os.execute("rm -rf  \"" .. p .. "\"") == 0 then return true end return false end

copy = function(s, d)
    if mkdir(d) and os.execute("cp -rf \"" .. s .. "\" \"" .. d .. "\"") == 0 then return true end return false
end

-- List files and directories inside the specified path
-- ----------------------------------------------
function scandir(scan_dir, temp)
    temp = temp or "/sdcard/__temp/"
    local list_file = temp .. "_scandir_"
    --
    local create_list_file = "ls " .. scan_dir .. " > " .. list_file

    mkdir(temp)
    os.execute(create_list_file)

    local lines = {}

    for line in io.lines(list_file) do
        lines[#lines + 1] = line
    end

    rmdir(list_file)
    return lines
end

-- Returns information about a file path
-- ----------------------------------------------
pathinfo = function(p, op)
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

    if l == 1 then return r[string.lower(str_replace(op, "(.*)%_", ""))]
    else return r
    end
end

-- ===================================
-- Android function
-- ===================================


-- simulate home botton
-- ----------------------------------------------
btn_home = function() keyevent(3) end

-- simulate back botton
-- ----------------------------------------------
btn_back = function(i, w)
    i = i or 1
    w = w or 0
    while i > 0 do
        keyevent(4)
        wait(w)
        i = i - 1
    end
end

-- simulate SWITCH botton
-- ----------------------------------------------
btn_switch = function(i, w)
    i = i or 0
    w = w or 0
    while i > 0 do
        wait(w)
        keyevent(187)
        i = i - 1
    end
end


-- ===================================
-- lua essential function
-- ===================================

-- Clone all table and sub tables to avoid the __pairs metamethod.
-- ----------------------------------------------
clone_table = function(t)
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
odd = function(n) return not (n % 2 == 0) end

-- creates a random string
-- ----------------------------------------------
random_string = function(l)
    local charset = {}

    for i = 48, 57 do table.insert(charset, string.char(i)) end
    for i = 65, 90 do table.insert(charset, string.char(i)) end
    for i = 97, 122 do table.insert(charset, string.char(i)) end

    math.randomseed(os.time())

    if l > 0 then
        return random_string(l - 1) .. charset[math.random(1, #charset)]
    else
        return ""
    end
end

-- ===================================
-- Ankulua extends
-- ===================================

-- converts a location to string
-- ----------------------------------------------
location_to_string = function(loc) return tostring((string.format("Location(%d, %d)", loc:getX(), loc:getY()))) end

-- converts a region to string
-- ----------------------------------------------
region_to_string = function(r) return tostring((string.format("Region(%d, %d, %d, %d)", r:getX(), r:getY(), r:getW(), r:getH()))) end

-- Finds out whether a variable is a Location
-- ----------------------------------------------
is_location = function(v) if gettype(v) == "Location" then return true end return false end

-- Finds out whether a variable is a Region
-- ----------------------------------------------
is_region = function(v) if gettype(v) == "Region" then return true end return false end

-- Finds out whether a variable is a Match
-- ----------------------------------------------
is_match = function(v) if gettype(v) == "Match" then return true end return false end

-- Finds out whether a variable is a Pattern
-- ----------------------------------------------
is_pattern = function(v) if gettype(v) == "Pattern" then return true, p:getFileName() end return false, "_none_" end

-- Auto highlight any img,region,match or location
-- ----------------------------------------------
debug_r = function(title, var, time)
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
                toast("IMG - Target | " .. title)
                Region(target:getX() - 10, target:getY() - 10, 20, 20):highlight(time)
                toast("IMG - Center | " .. title)
                Region(center:getX() - 10, center:getY() - 10, 20, 20):highlight(time)
            else
                toast("IMG not found")
            end
        end
        toast(tp .. " | " .. title)
        Region(x, y, w, h):highlight(time)
    end
end

-- highlight a image(string)
-- ----------------------------------------------
img_r = function(v, time)
    time = time or 2
    if is_string(v) then v = str_replace(v, ".png", "") .. ".png"
        if DEBUG_R == true or DEBUG_R == nil then
            local t = Timer()
            local p = v
            if is_string(v) then p = Pattern(v) else p = v end
            if exists(p) then debug_r(p:getFileName() .. " - time elapsed: " .. t:set(), getLastMatch(), time) end
        end
        return v
    end
end

-- converts a table to string
-- ----------------------------------------------
table_to_string = function(table, space)

    space = space or ""
    local text = "{"

    for key, value in pairs(table) do
        text = text .. "\n\t" .. space .. tostring(key) .. " = "
        if gettype(value) == "Location" then
            text = text .. location_to_string(value)
        elseif gettype(value) == "Region" then
            text = text .. region_to_string(value)
        elseif is_table(value) then
            text = text .. table_to_string(value, space .. "\t")
        elseif is_string(value) then
            text = text .. "'" .. value .. "'"
        elseif (is_bool(value)) then
            text = text .. tostring(value)
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

get_values = function(v)
    if is_location(v) then return { x = v:getX(), y = v:getY() }
    elseif is_region(v) then return { x = v:getX(), y = v:getY(), w = v:getW(), h = v:getH() }
    elseif is_match(v) then return { x = v:getX(), y = v:getY(), w = v:getW(), h = v:getH(), center = get_values(v:getCenter()), score = v:getScore(), target = get_values(v:getTarget()) }
    elseif is_table(v) then local r = {} for k, n in pairs(v) do r[#r + 1] = n end return r
    else return {}
    end
end



-- ===================================
-- Alias functions
-- ===================================

-- alias of is_float
is_double = function(...) return is_float(...) end
-- alias of is_table
is_array = function(...) return is_table(...) end
-- alias of clone_table
clone_array = function(...) return clone_table(...) end
-- alias of clone_table
array_to_string = function(...) return table_to_string(...) end
-- alias of in_table
in_array = function(...) return in_table(...) end