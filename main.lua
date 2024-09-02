--@name ComputerCraft
--@author SquidDev - CC: Tweaked, Lumi - porting to SF
--@client
--@owneronly

-- this should speed up load times as you only have to send these lines vs sending the entire `cl_fragment.lua` file to the server
assert( loadstring( file.readInGame( "data/starfall/computercraft/cl_fragment.lua" ), "cl_fragment.lua" ) )()
