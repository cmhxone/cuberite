
-- Global variables
PLUGIN = {};	-- Reference to own plugin object
ShouldDumpFunctions = true;  -- If set to true, all available functions are logged upon plugin initialization





function Initialize(Plugin)
	PLUGIN = Plugin
	
	Plugin:SetName("Debuggers")
	Plugin:SetVersion(1)
	
	PluginManager = cRoot:Get():GetPluginManager()
	PluginManager:AddHook(Plugin, cPluginManager.HOOK_PLAYER_USING_ITEM);
	PluginManager:AddHook(Plugin, cPluginManager.HOOK_TAKE_DAMAGE);

	-- Enable the following line for BlockArea / Generator interface testing:
	-- PluginManager:AddHook(Plugin, cPluginManager.HOOK_CHUNK_GENERATED);
	
	LOG("Initialized " .. Plugin:GetName() .. " v." .. Plugin:GetVersion())

	-- dump all available functions to console:
	if (ShouldDumpFunctions) then
		LOG("Dumping all available functions:");
		function dump (prefix, a, Output)
			for i, v in pairs (a) do
				if (type(v) == "table") then
					if (GetChar(i, 1) ~= ".") then
						if (v == _G) then
							LOG(prefix .. i .. " == _G, CYCLE, ignoring");
						elseif (v == _G.package) then
							LOG(prefix .. i .. " == _G.package, ignoring");
						else
							dump(prefix .. i .. ".", v, Output)
						end
					end
				elseif (type(v) == "function") then
					if (string.sub(i, 1, 2) ~= "__") then
						table.insert(Output, prefix .. i .. "()");
					end
				end
			end
		end

		local Output = {};
		dump("", _G, Output);

		table.sort(Output);
		local f = io.open("API.txt", "w");
		for i, n in ipairs(Output) do
			f:write(n, "\n");
		end
		f:close();
	end
	
	
	-- Debug block area merging:
	local BA1 = cBlockArea();
	local BA2 = cBlockArea();
	if (BA1:LoadFromSchematicFile("schematics/test.schematic")) then
		if (BA2:LoadFromSchematicFile("schematics/fountain.schematic")) then
			BA2:SetRelBlockType(0, 0, 0, E_BLOCK_LAPIS_BLOCK);
			BA2:SetRelBlockType(1, 0, 0, E_BLOCK_LAPIS_BLOCK);
			BA2:SetRelBlockType(2, 0, 0, E_BLOCK_LAPIS_BLOCK);
			BA1:Merge(BA2, 1, 10, 1, cBlockArea.msImprint);
			BA1:SaveToSchematicFile("schematics/merge.schematic");
		end
	end
	
	-- Debug block area cuboid filling:
	BA1:FillRelCuboid(2, 9, 2, 8, 2, 8, cBlockArea.baTypes, E_BLOCK_GOLD_BLOCK);
	BA1:RelLine(2, 2, 2, 9, 8, 8, cBlockArea.baTypes or cBlockArea.baMetas, E_BLOCK_SAPLING, E_META_SAPLING_BIRCH);
	BA1:SaveToSchematicFile("schematics/fillrel.schematic");

	-- Debug block area mirroring:
	if (BA1:LoadFromSchematicFile("schematics/lt.schematic")) then
		BA1:MirrorXYNoMeta();
		BA1:SaveToSchematicFile("schematics/lt_XY.schematic");
		BA1:MirrorXYNoMeta();
		BA1:SaveToSchematicFile("schematics/lt_XY2.schematic");
		
		BA1:MirrorXZNoMeta();
		BA1:SaveToSchematicFile("schematics/lt_XZ.schematic");
		BA1:MirrorXZNoMeta();
		BA1:SaveToSchematicFile("schematics/lt_XZ2.schematic");
		
		BA1:MirrorYZNoMeta();
		BA1:SaveToSchematicFile("schematics/lt_YZ.schematic");
		BA1:MirrorYZNoMeta();
		BA1:SaveToSchematicFile("schematics/lt_YZ2.schematic");
	end
	
	-- Debug block area rotation:
	if (BA1:LoadFromSchematicFile("schematics/rot.schematic")) then
		BA1:RotateCWNoMeta();
		BA1:SaveToSchematicFile("schematics/rot1.schematic");
		BA1:RotateCWNoMeta();
		BA1:SaveToSchematicFile("schematics/rot2.schematic");
		BA1:RotateCWNoMeta();
		BA1:SaveToSchematicFile("schematics/rot3.schematic");
		BA1:RotateCWNoMeta();
		BA1:SaveToSchematicFile("schematics/rot4.schematic");
	end

	return true
end





function OnPlayerUsingItem(Player, BlockX, BlockY, BlockZ, BlockFace, CursorX, CursorY, CursorZ)

	-- dont check if the direction is in the air
	if (BlockFace == BLOCK_FACE_NONE) then
		return false
	end

	local HeldItem = Player:GetEquippedItem();


	if (HeldItem.m_ItemType == E_ITEM_STICK) then
		-- Magic sTick of ticking: set the pointed block for ticking at the next tick
		Player:SendMessage(cChatColor.LightGray .. "Setting next block tick to {" .. BlockX .. ", " .. BlockY .. ", " .. BlockZ .. "}")
		Player:GetWorld():SetNextBlockTick(BlockX, BlockY, BlockZ);
		return true
	end


	if (HeldItem.m_ItemType == E_ITEM_BLAZE_ROD) then
		-- Magic rod of query: show block types and metas for both neighbors of the pointed face
		local Type = 0;
		local Meta = 0;
		local Valid = false;
		Valid, Type, Meta = Player:GetWorld():GetBlockTypeMeta(BlockX, BlockY, BlockZ, Type, Meta);

		if (Type == E_BLOCK_AIR) then
			Player:SendMessage(cChatColor.LightGray .. "Block {" .. BlockX .. ", " .. BlockY .. ", " .. BlockZ .. "}: air:" .. Meta);
		else
			local TempItem = cItem(Type, 1, Meta);
			Player:SendMessage(cChatColor.LightGray .. "Block {" .. BlockX .. ", " .. BlockY .. ", " .. BlockZ .. "}: " .. ItemToFullString(TempItem) .. " (" .. Type .. ":" .. Meta .. ")");
		end
		
		local X = BlockX;
		local Y = BlockY;
		local Z = BlockZ;
		X, Y, Z = AddFaceDirection(BlockX, BlockY, BlockZ, BlockFace);
		Valid, Type, Meta = Player:GetWorld():GetBlockTypeMeta(X, Y, Z, Type, Meta);
		if (Type == E_BLOCK_AIR) then
			Player:SendMessage(cChatColor.LightGray .. "Block {" .. X .. ", " .. Y .. ", " .. Z .. "}: air:" .. Meta);
		else
			local TempItem = cItem(Type, 1, Meta);
			Player:SendMessage(cChatColor.LightGray .. "Block {" .. X .. ", " .. Y .. ", " .. Z .. "}: " .. ItemToFullString(TempItem) .. " (" .. Type .. ":" .. Meta .. ")");
			return true;
		end
	end


	-- Rclk with a diamond to test block area cropping and expanding
	if (Player:GetEquippedItem().m_ItemType == E_ITEM_DIAMOND) then
		local Area = cBlockArea();
		Area:Read(Player:GetWorld(),
			BlockX - 19, BlockX + 19,
			BlockY - 7, BlockY + 7,
			BlockZ - 19, BlockZ + 19
		);

		LOG("Size before cropping: " .. Area:GetSizeX() .. " x " .. Area:GetSizeY() .. " x " .. Area:GetSizeZ());
		Area:DumpToRawFile("crop0.dat");
		
		Area:Crop(2, 3, 0, 0, 0, 0);
		LOG("Size after cropping 1: " .. Area:GetSizeX() .. " x " .. Area:GetSizeY() .. " x " .. Area:GetSizeZ());
		Area:DumpToRawFile("crop1.dat");
		
		Area:Crop(2, 3, 0, 0, 0, 0);
		LOG("Size after cropping 2: " .. Area:GetSizeX() .. " x " .. Area:GetSizeY() .. " x " .. Area:GetSizeZ());
		Area:DumpToRawFile("crop2.dat");
		
		Area:Expand(2, 3, 0, 0, 0, 0);
		LOG("Size after expanding 1: " .. Area:GetSizeX() .. " x " .. Area:GetSizeY() .. " x " .. Area:GetSizeZ());
		Area:DumpToRawFile("expand1.dat");
		
		Area:Expand(3, 2, 1, 1, 0, 0);
		LOG("Size after expanding 2: " .. Area:GetSizeX() .. " x " .. Area:GetSizeY() .. " x " .. Area:GetSizeZ());
		Area:DumpToRawFile("expand2.dat");
		
		Area:Crop(0, 0, 0, 0, 3, 2);
		LOG("Size after cropping 3: " .. Area:GetSizeX() .. " x " .. Area:GetSizeY() .. " x " .. Area:GetSizeZ());
		Area:DumpToRawFile("crop3.dat");
		
		Area:Crop(0, 0, 3, 2, 0, 0);
		LOG("Size after cropping 4: " .. Area:GetSizeX() .. " x " .. Area:GetSizeY() .. " x " .. Area:GetSizeZ());
		Area:DumpToRawFile("crop4.dat");

		LOG("Crop test done");
		Player:SendMessage("Crop / expand test done.");
		return false;
	end


	-- Rclk with an eye of ender places a predefined schematic at the cursor
	if (Player:GetEquippedItem().m_ItemType == E_ITEM_EYE_OF_ENDER) then
		local Area = cBlockArea();
		if not(Area:LoadFromSchematicFile("schematics/test.schematic")) then
			LOG("Loading failed");
			return false;
		end
		LOG("Schematic loaded, placing now.");
		Area:Write(Player:GetWorld(), BlockX, BlockY, BlockZ);
		LOG("Done.");
		return false;
	end
	
	
	-- Rclk with an ender pearl saves a predefined area around the cursor into a .schematic file. Also tests area copying
	if (Player:GetEquippedItem().m_ItemType == E_ITEM_ENDER_PEARL) then
		local Area = cBlockArea();
		if not(Area:Read(Player:GetWorld(), 
			BlockX - 8, BlockX + 8, BlockY - 8, BlockY + 8, BlockZ - 8, BlockZ + 8)
		) then
			LOG("LUA: Area couldn't be read");
			return false;
		end
		LOG("LUA: Area read, copying now.");
		local Area2 = cBlockArea();
		Area2:CopyFrom(Area);
		LOG("LUA: Copied, now saving.");
		if not(Area2:SaveToSchematicFile("schematics/test.schematic")) then
			LOG("LUA: Cannot save schematic file.");
			return false;
		end
		LOG("LUA: Done.");
		return false;
	end
	
end





function OnTakeDamage(Receiver, TDI)
	-- Receiver is cPawn
	-- TDI is TakeDamageInfo

	LOG(Receiver:GetClass() .. " was dealt RawDamage " .. TDI.RawDamage .. ", FinalDamage " .. TDI.FinalDamage .. " (that is, " .. (TDI.RawDamage - TDI.FinalDamage) .. " HPs covered by armor)");
end





function OnChunkGenerated(World, ChunkX, ChunkZ, ChunkDesc)
	-- Test ChunkDesc / BlockArea interaction
	local BlockArea = cBlockArea();
	ChunkDesc:ReadBlockArea(BlockArea, 0, 15, 50, 70, 0, 15);
	
	-- BlockArea:SaveToSchematicFile("ChunkBlocks_" .. ChunkX .. "_" .. ChunkZ .. ".schematic");

	ChunkDesc:WriteBlockArea(BlockArea, 5, 115, 5);
	return false;
end




