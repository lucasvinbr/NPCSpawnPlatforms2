--[[
	NPC Spawn Platforms V2 - lua/weapons/gmod_tool/stools/npc_spawnplatform_vjhumans_deathlinker.lua
    Copyright 2009-2017 Lex Robinson

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
--]]


local ClassName = 'npc_spawnplatform_vjhumans_deathlinker';

local function lang(id)
	return '#Tool.' .. ClassName .. '.' .. id;
end
local function cvar(id)
	return ClassName .. '_' .. id;
end


MsgN(ClassName, ' reloaded');

TOOL.Category     = "Lexical Tools";
TOOL.Name         = lang("name");

function TOOL:LeftClick(trace)
	local owner = self:GetOwner();
	if (npcspawner.config.adminonly == 1 and not owner:IsAdmin()) then
		if (CLIENT) then
			GAMEMODE:AddNotify("The server admin has disabled this STool for non-admins!", NOTIFY_ERROR, 5);
		end
		npcspawner.debug2(owner, "has tried to use the DLinker STool in admin mode and isn't an admin!");
		return false;
	end

	local hitEntIsSpawnPlat = trace.Entity:GetClass() == "sent_spawnplatform_vjhumans";

	npcspawner.debug2(owner, "has left clicked the DLinker STool.");
	if (CLIENT) then
		return hitEntIsSpawnPlat;
	elseif (hitEntIsSpawnPlat) then
		self:LinkDeathSingle(trace.Entity);
		npcspawner.debug(owner, "has DLinked to an existing platform:", trace.Entity);
		return true;
	end
	return false;
end

function TOOL:RightClick(trace)
	local owner = self:GetOwner();

	if (npcspawner.config.adminonly == 1 and not owner:IsAdmin()) then
		if (CLIENT) then
			GAMEMODE:AddNotify("The server admin has disabled this STool for non-admins!", NOTIFY_ERROR, 5);
		end
		npcspawner.debug2(owner, "has tried to use the DLinker STool in admin mode and isn't an admin!");
		return false;
	end

	local ent = trace.Entity;
	npcspawner.debug2(owner, "has right-clicked the DLinker STool on", ent);
	if (IsValid(ent) and ent:GetClass() == "sent_spawnplatform_vjhumans") then
		if (CLIENT) then return true end

		self:LinkDeathToAllSharingNPCType(ent);
		return true;
	end
end

function TOOL:Reload(trace)
	npcspawner.debug2(owner, "has reloaded the DLinker STool (should nullify all his links)");
	if CLIENT then return true end
	self:ClearAllOwnerLinks();
	return true;
end

function TOOL:LinkDeathSingle(targetPlat)
	targetPlat:SetPlayerWhoseDeathsCount(self:GetOwner());
end

function TOOL:ClearDeathLink(targetPlat)
	targetPlat:SetPlayerWhoseDeathsCount(NULL);
end

function TOOL:LinkDeathToAllSharingNPCType(referencePlat)
	local targetNPCType = referencePlat:GetNPC();

	for _, plat in pairs( ents.FindByClass( "sent_spawnplatform_vjhumans" ) ) do
		if plat:GetNPC() == targetNPCType then
			if (not IsValid(plat:GetPlayerWhoseDeathsCount())) then
				self:LinkDeathSingle(plat);
			end
		end
	end
end

function TOOL:ClearAllOwnerLinks()
	local owner = self:GetOwner();
	
	for _, plat in pairs( ents.FindByClass( "sent_spawnplatform_vjhumans" ) ) do
		if (IsValid(plat:GetPlayerWhoseDeathsCount())) then
			if plat:GetPlayerWhoseDeathsCount():Name() == owner:Name() then
				self:ClearDeathLink(plat);
			end
		end
	end
end

if (SERVER) then return; end

local function AddToolLanguage(id, lang)
	language.Add('tool.' .. ClassName .. '.' .. id, lang);
end
AddToolLanguage("name", "NPC Plats for VJ Humans - Death Linker");
AddToolLanguage("desc", "Makes your deaths count towards spawns from the target platform");
AddToolLanguage("0",    "Left-click: Link Deaths to Platform. Right-click: Link Deaths to All Platforms spawning the same NPC Type. Reload: Clears all Links assigned to you.");
