require 'paths'

local function fileexists(filename)
   local f = io.open(filename)
   if f then
      f:close()
      return true
   else
      return false
   end
end

local function parse(filename)
   local outname = os.tmpname()
   -- DEBUG: system dependent
   local ret = os.execute(string.format('gcc -ansi -E %s -o %s', filename, outname))
   local res
   if ret == 0 then
      local f = io.open(outname)
      res = f:read('*all')
      f:close()
   end
   os.remove(outname)
   
   return res
end
   
local function preprocess(rootfilename, files)
   files = files or {}

   local reader = {"local readcheader = require 'readcheader'\n"}
   local out = parse(rootfilename)   
   local lineno, filename
   local readfilename
   local readfileargs = {}
   local lineoff = 0
   local nline = 0

   local function endfile()
--      print(readfilename, filename, nline)

      if readfilename ~= filename then
         if #readfileargs > 0 then
            table.insert(reader, table.concat(readfileargs, ", ") .. ')')
         end
         readfilename = filename
         readfileargs = {}
      end

      if filename and lineno and nline > 0 then
         if #readfileargs == 0 then
            table.insert(readfileargs, string.format("readcheader('%s'", filename))
         end
         table.insert(readfileargs, string.format("{%d, %d}", lineno, lineoff))
      end

   end

   for line in out:gmatch('(.-)[\n\r]') do
      local lineno_, filename_ = line:match('^#%s+(%d+)%s+"([^"]+)"')
      if lineno_ and filename_ then
         endfile()
         lineno, lineoff, filename, nline = lineno_, 0, filename_, 0
      else
         if line:match('%S') then
            files[filename] = files[filename] or {}
            files[filename][lineno+lineoff] = line -- DEBUG: check is same?
            nline = nline + 1
         end
         lineoff = lineoff + 1
      end
   end
   filename = nil -- make sure even the last one is written down
   endfile()

   return files, table.concat(reader, '\n')
end

local function finddefinitions(filename, defs, filters)
   local defs = defs or {}
   local filters = filters or {'.'}
   local lines = {}
   for line in io.lines(filename) do
      table.insert(lines, line)
      local var, val = line:match('^%s*#%s*define%s+([^%s%(%)]+)%s+(.*)$')
      if var and val then
         table.insert(lines, string.format('CPPFFILUADEF VAR_%s %s', var, val))
      end
   end

   local tmpname = os.tmpname()
   os.remove(tmpname)
   tmpname = tmpname .. '.h'

   local f = io.open(tmpname, 'w')
   for _, line in ipairs(lines) do
      f:write(line)
      f:write('\n')
   end
   f:close()

   local out = parse(tmpname)
   if out then
      for line in out:gmatch('[^\n\r]+') do
         local var, val = line:match('^CPPFFILUADEF%s+VAR_(%S+)%s+(%S+)$')
         if var and val and tonumber(val) then
            for _, filter in ipairs(filters) do
               if var:match(filter) then
                  defs[var] = val
                  break
               end
            end
         end
      end
   end

   os.remove(tmpname)

   return defs
end

local files, reader = preprocess(arg[1])

local function c2luaname(filename)
   local luafilename = filename:gsub('%.[^%.]+$', '.lua')
   assert(luafilename ~= filename)
   luafilename = 'include' .. luafilename
   return luafilename
end

local function tblsize(tbl)
   local n = 0
   for k,v in pairs(tbl) do
      n = n + 1
   end
   return n
end

local function maxlines(lines)
   local maxl = 0
   for idx, line in pairs(lines) do
      maxl = math.max(maxl, idx)
   end
   return maxl
end

local defs = {}

for filename, lines in pairs(files) do
   finddefinitions(filename, defs)

   filename = 'include' .. filename
   os.execute(string.format('mkdir -p %s', paths.dirname(filename)))

   local f = io.open(filename)
   local oldlines = {}
   if f then
      f:close()
      local idx = 0
      for line in io.lines(filename) do
         idx = idx + 1
         if line:match('%S+') then
            oldlines[idx] = line
         end
      end
   end

   local f = io.open(filename, 'w')
   for i=1,maxlines(lines) do
      if lines[i] then
         if oldlines[i] then
            assert(oldlines[i] == lines[i],
                   string.format("file %s line %d does not match with previous preprocessing:\n%s\nvs the previous one:\n%s\n",
                                 filename,
                                 i,
                                 lines[i],
                                 oldlines[i]))
         end
         f:write(lines[i])
      elseif oldlines[i] then
         f:write(oldlines[i])
      end
      f:write('\n')
   end
   f:close()
end

print(reader)

if tblsize(defs) > 0 then
   print()
   print('local defs = {}')
   for val, var in pairs(defs) do
      print(string.format('defs["%s"] = %s', val, var))
   end
   print('return defs')
end
