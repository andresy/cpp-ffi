-- for GCC-command-like compilers (Clang, ICC)

local function parse(args) -- pour pouvoir etre flexible au besoin
   assert(args.filename, 'missing filename')

   local outname = os.tmpname()

   -- note that LuaJIT FFI does not support some bizarre things
   -- (e.g. "^" from MacOS X)... hence the c99 enforcement
   local cmd = {string.format('gcc -std=c99 -E %s -o %s', args.filename, outname)}

   if args.includes then
      for _, include in ipairs(args.includes) do
         table.insert(cmd, string.format('-I%s', include))
      end
   end

   if args.flags then
      for _, flag in ipairs(args.flags) do
         table.insert(cmd, flag)
      end
   end

   cmd = table.concat(cmd, ' ')

   local ret = os.execute(cmd)
   local res
   if ret == 0 then
      local f = io.open(outname)
      res = f:read('*all')
      f:close()
   end
   os.remove(outname)
   
   return res
end

return {parse=parse, lineregexp='^#%s+(%d+)%s+"([^"]+)"'}
