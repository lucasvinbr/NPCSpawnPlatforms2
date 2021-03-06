--[[
	NPC Spawn Platforms V2 - lua/autorun/client/npcspawner2_cl.lua
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

local cvarstr = "npcspawner_config_";

local function cvar(id)
	return cvarstr .. id;
end

local function callback(cvar, old, new)
	local lpl = LocalPlayer();
	if (IsValid(lpl) and not lpl:IsAdmin()) then
		return
	end

	local name = cvar:gsub(cvarstr, "");
	local value = tonumber(new)

	if (not value or value == npcspawner.config[name]) then
		return;
	end

	RunConsoleCommand("npcspawner_config", name, value);
end

for name, default in pairs(npcspawner.config) do
	name = cvar(name)
	CreateConVar(name, tostring(default));
	cvars.AddChangeCallback(name, callback);
end

npcspawner.recieve("NPCSpawner Config", function(data)
	npcspawner.config = data;
	npcspawner.debug("Just got new config vars.");
	for name, value in pairs(npcspawner.config) do
		RunConsoleCommand(cvar(name), tostring(value))
	end
end);

concommand.Add( "log_remainingvjspawnplatnpcs", function()
	local alliesRemaining = {};
	local enemiesRemaining = {};

	for _, plat in pairs( ents.FindByClass( "sent_spawnplatform_vjhumans" ) ) do
		if (plat:IsVjHostile()) then
			if(enemiesRemaining[plat:GetNPC()]) then
				enemiesRemaining[plat:GetNPC()] = enemiesRemaining[plat:GetNPC()] + plat:CalcRemainingNPCs();
			else
				enemiesRemaining[plat:GetNPC()] = plat:CalcRemainingNPCs();
			end
		else
			if(alliesRemaining[plat:GetNPC()]) then
				alliesRemaining[plat:GetNPC()] = alliesRemaining[plat:GetNPC()] + plat:CalcRemainingNPCs();
			else
				alliesRemaining[plat:GetNPC()] = plat:CalcRemainingNPCs();
			end
		end
	end

	print("Vj Humans Spawn Plats - Remaining Allies:");
	for name, amount in pairs(alliesRemaining) do
		print(name .. " : " .. amount);
	end

	print("Vj Humans Spawn Plats - Remaining Hostiles:");
	for name, amount in pairs(enemiesRemaining) do
		print(name .. " : " .. amount);
	end
end);

concommand.Add( "debug_log_vjspawnplatpresetinfo", function()
	for presetName, presetData in pairs(presets.GetTable("spawnplatform_vjhumans")) do
		print("preset: " .. presetName);
		print("data:");
		for k, v in pairs(presetData) do
			print(k .. ": " .. v);
		end
		print("---end of preset data---");
	end
end);

-----------------------------------
-- Lexical Patented Corpse Eater --
-----------------------------------
CreateConVar("cleanupcorpses", 1);
timer.Create("Dead Body Deleter", 60, 0, function()
	if (GetConVarNumber("cleanupcorpses") < 1) then return; end
	for _, ent in pairs(ents.FindByClass("class C_ClientRagdoll")) do
		ent:Remove()
	end
end);

local function addPanelLabel(id, label, help)
	language.Add("utilities.spawnplatform." .. id, label)
	if (help) then
		language.Add("utilities.spawnplatform." .. id .. ".help", help)
	end
end

local function lang(id)
	return "#utilities.spawnplatform." .. id
end

language.Add("spawnmenu.utilities.spawnplatform", "NPC Spawn Platforms")
addPanelLabel("cleanupcorpses", "Clean up corpses", "Automatically delete all NPC corpses every minute")
addPanelLabel("adminonly", "Admins Only", "Prevent normal users from spawning platforms")
addPanelLabel("playerdeathscounttowardplats", "Player Deaths can Count towards Platform Spawns", "Players can link themselves to a spawn platform to make their deaths count as spawns from that plat. This allows or disables this effect")
addPanelLabel("callhooks", "Call Sandbox Hooks", "Act as if the user had used the spawn menu to spawn NPCs. This will force the platform to obey entity limits etc.")
addPanelLabel("maxinplay", "Max NPCs per Platform", "How many NPCs a single platform may have alive at once")
addPanelLabel("mindelay", "Minimum Spawn Delay", "The minimum delay a platform must wait before spawning a new NPC")
addPanelLabel("logremaining", "Print Remaining NPCs to Console", "Prints the amount of NPCs remaining for the platforms, separated by their 'isHostile' option")
addPanelLabel("sanity", "Valid NPC Check", "Only spawn NPCs on the NPC list. If you disable this option, players can potentially spawn literally any entity they want.")
addPanelLabel("debug", "Enable Developer Logging", "Enable or disable diagnostic messages. Requires the convar 'developer' to be 1 or 2")
addPanelLabel("dangerzone", "Danger Zone")
addPanelLabel("rehydrate", "Missing NPCs on Dupe Fix", [[
If you duplicate a platform but not it's NPCs, it will re-spawn all NPCs the old platform had.
This is important for saves and persistance (which use the duplicator under the hood) but may be suprising with the duplicator tool.
If you do not use persistance and want freshly duplicated platforms to have no NPCs, untick this.]])

local function clientOptions(panel)
	panel:AddControl("CheckBox", {
		Label = lang("cleanupcorpses"),
		Help = true,
		Command = "cleanupcorpses",
	});

	panel:AddControl("Button", {
		Label = lang("logremaining"),
		Help = true,
		Command = "log_remainingvjspawnplatnpcs",
	});

end

local function adminOptions(panel)
	panel:AddControl("CheckBox", {
		Label   = lang("adminonly"),
		Command = cvar("adminonly"),
		Help    = true,
	});

	panel:AddControl("CheckBox", {
		Label   = lang("playerdeathscounttowardplats"),
		Command = cvar("playerdeathscounttowardplats"),
		Help    = true,
	});

	panel:AddControl("CheckBox", {
		Label   = lang("callhooks"),
		Command = cvar("callhooks"),
		Help    = true,
	});

	panel:AddControl("Slider", {
		Label   = lang("maxinplay"),
		Command = cvar("maxinplay"),
		Help    = true,
		Type    = "Float",
		Min     = "1",
		Max     = "50",
	})

	panel:AddControl("Slider", {
		Label   = lang("mindelay"),
		Command = cvar("mindelay"),
		Help    = true,
		Type    = "Float",
		Min     = "0.1",
		Max     = "10",
	})

	local dzpanel = panel:AddControl("ControlPanel", {
		Label = lang("dangerzone"),
		Closed = true,
	});

	dzpanel:AddControl("CheckBox", {
		Label   = lang("sanity"),
		Command = cvar("sanity"),
		Help    = true,
	});

	dzpanel:AddControl("CheckBox", {
		Label   = lang("rehydrate"),
		Command = cvar("rehydrate"),
		Help    = true,
	});


	--[[
	dzpanel:AddControl("CheckBox", {
		Label   = lang("debug"),
		Command = cvar("debug"),
		Help    = true,
	});
	--]]
end

hook.Add("PopulateToolMenu", "NPCSpawner Options", function()
	spawnmenu.AddToolMenuOption("Utilities", "User",  "NPC Spawn Platforms User",  "#spawnmenu.utilities.spawnplatform", "", "", clientOptions)
	spawnmenu.AddToolMenuOption("Utilities", "Admin", "NPC Spawn Platforms Admin", "#spawnmenu.utilities.spawnplatform", "", "", adminOptions )
end)
