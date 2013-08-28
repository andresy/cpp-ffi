local ffi = require 'ffi'

local headers = {}

-- ARK: faut faire tout d'un coup pour un fichier, car sinon on
-- peut avoir des #line qui break une struct, par exemple
-- --> readcheader(filename, {{10,3}, ...})

local function readcheader(filename, ...)
   local segments = {...}

   if not headers[filename] then -- DEBUG: on pourrait vouloir reloader... si il y a eu une creation entre temps
      -- sans doute pas, car on est sans doute de la baise dans ce cas (a voir)
      local header = {}
      for line in io.lines('include' .. filename) do
         table.insert(header, line) -- NOTE: cannot remove the empty lines here, as I need them when declaring (sometimes struct declared over several lines, possibly empty...)
      end
      headers[filename] = header
   end

   local header = headers[filename]
   
   local cdef = {}
   local range = {}
   local function docdef()
      if #cdef > 0 then
--DEBUG:         print('-----', filename, range[1])
--DEBUG:         print(table.concat(cdef, '\n'))
         ffi.cdef(table.concat(cdef, '\n'))
         for i=1,#range do
            header[range[i]] = nil -- DEBUG: check with above comment
         end
         cdef = {}
         idx = {}
      end
   end

   for _, segment in ipairs(segments) do
      local idx = segment[1]
      local n = segment[2]

      for lineidx=idx,idx+n-1 do
         if header[lineidx] then
            table.insert(cdef, header[lineidx])
            table.insert(range, lineidx)
         else
            docdef()
         end
      end
   end
   docdef()

end

return readcheader