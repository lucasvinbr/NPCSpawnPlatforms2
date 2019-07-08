--[[
	NPC Spawn Platforms V2 - lua/weapons/gmod_tool/stools/npc_spawnplatform.lua
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


local ClassName = 'npc_spawnplatform_vjhumans';

local function lang(id)
	return '#Tool.' .. ClassName .. '.' .. id;
end
local function cvar(id)
	return ClassName .. '_' .. id;
end


MsgN(ClassName, ' reloaded');

TOOL.Category     = "Lexical Tools";
TOOL.Name         = lang("name");
--- Default Values
local npcCvars = {
	npc           = "npc_combine_s";
	weapon        = "weapon_smg1";
	spawnheight   = "16";
	spawnradius   = "16";
	maximum       = "5";
	delay         = "4";
	onkey         = "2";
	offkey        = "1";
	nocollide     = "1";
	toggleable    = "1";
	autoremove    = "1";
	squadoverride = "1";
	customsquads  = "0";
	totallimit    = "0";
	active        = "0";
	frozen        = "1";

	vjhealth      = "0";
	vjshootdist   = "2000";
	vjweaponspread= "2";
	vjmeleedamage = "15";
	vjcanmelee    = "1";
	vjcangrenade  = "1";
	vjcanmoveshoot= "1";
	vjishostile   = "0";


}

local notSavedNpcCvars = {
	vjoverrideclass = "";
	vjnpcsuffixifhostile = "";
}

local batcherCvars = {
	batcher_totalmaxinaction = "50";
	-- batcher_inputjson = "";
	-- batcher_addentry_name = "default";
	-- batcher_addentry_amount = "100";
	-- batcher_addentry_hostile = "0";
	batcher_selectedindex = "0";
}

cleanup.Register("Spawnplatforms");
table.Merge(TOOL.ClientConVar, npcCvars);
table.Merge(TOOL.ClientConVar, notSavedNpcCvars);
table.Merge(TOOL.ClientConVar, batcherCvars);

function TOOL:LeftClick(trace)
	local owner = self:GetOwner();
	if (npcspawner.config.adminonly == 1 and not owner:IsAdmin()) then
		if (CLIENT) then
			GAMEMODE:AddNotify("The server admin has disabled this STool for non-admins!", NOTIFY_ERROR, 5);
		end
		npcspawner.debug2(owner, "has tried to use the STool in admin mode and isn't an admin!");
		return false;
	end
	npcspawner.debug2(owner, "has left clicked the STool.");
	if (CLIENT) then
		return true;
	elseif (not owner:CheckLimit("spawnplatforms")) then
		return false;
	elseif (trace.Entity:GetClass() == "sent_spawnplatform_vjhumans") then
		self:SetKVs(trace.Entity);
		npcspawner.debug(owner, "has applied his settings to an existing platform:", trace.Entity);
		return true;
	end
	local ent = ents.Create("sent_spawnplatform_vjhumans");
	ent:SetKeyValue("ply", owner:EntIndex());
	ent:SetPos(trace.HitPos);
	local ang = trace.HitNormal:Angle();
	ang.Roll = ang.Roll - 90;
	ang.Pitch = ang.Pitch - 90;
	ent:SetAngles(ang);
	ent:Spawn();
	ent:Activate();
	ent:SetPlayer(owner);
	self:SetKVs(ent);
	local min = ent:OBBMins();
	ent:SetPos(trace.HitPos - trace.HitNormal * min.y);
	owner:AddCount("sent_spawnplatform_vjhumans", ent);
	undo.Create("NPC Spawn Platform");
		undo.SetPlayer(self:GetOwner());
		undo.AddEntity(ent);
		undo.SetCustomUndoText("Undone a " .. self:GetClientInfo("npc") .. " spawn platform" ..
			(tonumber(self:GetClientInfo("autoremove")) > 0 and " and all its NPCs." or "."));
	undo.Finish();
	cleanup.Add(self:GetOwner(), "Spawnplatforms", ent);
	return true;
end

function TOOL:RightClick(trace)
	local owner = self:GetOwner();
	local ent = trace.Entity;
	npcspawner.debug2(owner, "has right-clicked the STool on", ent);
	if (IsValid(ent) and ent:GetClass() == "sent_spawnplatform_vjhumans") then
		if (CLIENT) then return true end
		for key in pairs(self.ClientConVar) do
			local res = ent:GetNetworkKeyValue(key);
			npcspawner.debug2("Got value", res, "for key", key);
			if (res) then
				owner:ConCommand(cvar(key) .. " " .. tostring(res) .. "\n");
			end
		end
	end
end

function TOOL:SetKVs(ent)
	for key in pairs(npcCvars) do
		-- Things that've been
		if(key == "npc" and self:GetClientInfo("vjishostile") == "1") then
			ent:SetKeyValue(key, self:GetClientInfo(key) .. self:GetClientInfo("vjnpcsuffixifhostile"));
		else
			ent:SetKeyValue(key, self:GetClientInfo(key));
		end

	end
	ent:SetKeyValue("vjoverrideclass", self:GetClientInfo("vjoverrideclass"));
end

if (SERVER) then return; end

local function AddToolLanguage(id, lang)
	language.Add('tool.' .. ClassName .. '.' .. id, lang);
end
AddToolLanguage("name", "NPC Spawn Platforms for VJ Humans");
AddToolLanguage("desc", "Create a platform that will constantly make NPCs.");
AddToolLanguage("0",    "Left-click: Spawn/Update Platform. Right-click: Copy Platform Data.");
-- Controls
AddToolLanguage("npc",           "NPC");
AddToolLanguage("weapon",        "Weapon");
AddToolLanguage("delay",         "Spawning Delay");
AddToolLanguage("maximum",       "Maximum In Action");
AddToolLanguage("totallimit",    "Turn Off After");
AddToolLanguage("autoremove",    "Clean up on Remove");
AddToolLanguage("keys.on",       "Turn On");
AddToolLanguage("keys.off",      "Turn Off");
AddToolLanguage("toggleable",    "Use Key Toggles");
AddToolLanguage("active",        "Start Active");
AddToolLanguage("nocollide",     "Disable NPC Collisions");
AddToolLanguage("spawnheight",   "Spawn Height");
AddToolLanguage("spawnradius",   "Spawn Radius");
AddToolLanguage("frozen",        "Spawn the platform frozen");
AddToolLanguage("customsquads",  "Use Global Squad");
AddToolLanguage("squadoverride", "Global Squad Number");
AddToolLanguage("vjoverrideclass",   "Override VJ Human Class");
AddToolLanguage("vjnpcsuffixifhostile", "VJ NPC Suffix if Hostile");
AddToolLanguage("vjshootdist",   "Shoot Distance");
AddToolLanguage("vjweaponspread","Weapon Spread");
AddToolLanguage("vjmeleedamage", "Melee Damage");
AddToolLanguage("vjcangrenade",  "Can Use Grenades");
AddToolLanguage("vjcanmelee",   "Can Use Melee Attack");
AddToolLanguage("vjcanmoveshoot",   "Can Shoot While Moving");
AddToolLanguage("vjhealth",   "Override Health");
AddToolLanguage("vjishostile",   "Is Hostile");
AddToolLanguage("batcher_inputjson",   "Input JSON");
AddToolLanguage("batcher_totalmaxinaction",   "Shared 'max in action'");
AddToolLanguage("batcher_addentry_name",   "Preset to Add");
AddToolLanguage("batcher_addentry_amount",   "Turn off After");
-- Control Descs
AddToolLanguage("vjshootdist.desc",         "How far the spawned NPC can shoot");
AddToolLanguage("vjcangrenade.desc",         "Can the NPC throw grenades?");
AddToolLanguage("vjcanmelee.desc",         "Can the NPC use melee attacks when close?");
AddToolLanguage("vjcanmoveshoot.desc",         "Can the NPC move and shoot at the same time?");
AddToolLanguage("vjhealth.desc",         "Sets a new max health for the spawned NPC. If set to 0, will use the NPC's default");
AddToolLanguage("vjmeleedamage.desc",         "The damage caused by the NPC's melee attack");
AddToolLanguage("vjweaponspread.desc",         "The NPC's weapon accuracy. The closer to 0 the better");
AddToolLanguage("vjishostile.desc",         "Is the NPC hostile to the player and HL2 Resistance?");
AddToolLanguage("vjnpcsuffixifhostile.desc",         "Suffix added to the NPC type if the 'is hostile' option is on (will use 'Soldier H' instead of 'Soldier' if hostile and this suffix is set to ' H', for example)");
AddToolLanguage("delay.desc",         "The delay between each NPC spawn.");
AddToolLanguage("maximum.desc",       "The platform will pause spawning until you kill one of the spawned ones");
AddToolLanguage("totallimit.desc",    "Turn the platform off after this many NPC have been spawned");
AddToolLanguage("autoremove.desc",    "All NPCs spawned by a platform will be removed with the platform.");
AddToolLanguage("spawnheight.desc",   "Spawn NPCs higher than the platform to avoid obsticles");
AddToolLanguage("spawnradius.desc",   "Spawn NPCs in a circle around the platform. 0 spawns them on the platform");
AddToolLanguage("batcher_inputjson.desc", "Enter a JSON string with an array of objects that have 'preset' and 'amount' entries");
AddToolLanguage("batcher_totalmaxinaction.desc", "If not 0, Batcher entries will have their 'Maximum in Action' value overridden so that their sum results in this (considering each entry's amount and the limit defined in the config)");
-- Help!
AddToolLanguage("positioning.help", "Prevent your NPCs getting stuck in each other by disabling collisions or spacing their spawns out.");
AddToolLanguage("squads.help1", "NPCs in a squad talk to each other to improve tactics. By default, all NPCs spawned by a spawn platform are in the same squad.");
AddToolLanguage("squads.help2", "If you want a squad to cover more than one platform, use a global squad. Be careful not to let your squads get to big or your game will lag!");

AddToolLanguage("batcher.help1", "The batcher allows the use of presets with tweaked or balanced settings without having to create new presets.");
AddToolLanguage("batcher.help2", "Expected JSON format: {\"troops\":[{\"name\":\"Soldier1\",\"amount\":80,\"hostile\":\"true\"},{\"name\":\"Soldier2\",\"amount\":40}]}");
-- Panels
AddToolLanguage("panel_npc",          "NPC Selection");
AddToolLanguage("panel_spawning",     "NPC Spawn Rates");
AddToolLanguage("panel_vjhuman",     "VJ Human Settings");
AddToolLanguage("panel_activation",   "Platform Activation");
AddToolLanguage("panel_positioning",  "NPC Positioning");
AddToolLanguage("panel_other",        "Other");
AddToolLanguage("panel_batcher",        "Spawn Batcher");
AddToolLanguage("panel_batcher_addmanual",        "Add Entries Manually");
AddToolLanguage("panel_batcher_addjson",        "Add Entries via JSON");
--btns
AddToolLanguage("btn_addtobatcher",        "Add to Batch List");
AddToolLanguage("btn_addtobatcher_json",        "Import to Batch List");
AddToolLanguage("btn_clearbatcher",        "Clear Batch List");
AddToolLanguage("btn_rmselfrombatcher",        "Remove Selected from Batch List");
AddToolLanguage("btn_reloadpresets",        "Reload Preset List");
-- Inferior Tech
language.Add("Cleanup_Spawnplatforms", "NPC Spawn Platforms");
language.Add("Cleaned_Spawnplatforms", "Cleaned up all NPC Spawn Platforms");

-- Because when don't you need to define your own builtins?
local function AddControl(CPanel, control, name, data)
	data = data or {};
	data.Label = lang(name);
	if (control ~= "ControlPanel" and control ~= "ListBox") then
		data.Command = cvar(name);
	end
	local ctrl = CPanel:AddControl(control, data);
	if (data.Description) then
		ctrl:SetToolTip(lang(name .. ".desc"));
	end
	return ctrl;
end

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {
		Text        = lang 'name';
		Description = lang 'desc';
	});
	-- Presets
	local CVars = {};
	local defaults = {};
	for key, default in pairs(npcCvars) do
		key = cvar(key);
		table.insert(CVars, key);
		defaults[key] = default;
	end

local presetsBox = CPanel:AddControl("ComboBox", {
		Label   = "#Presets";
		Folder  = "spawnplatform_vjhumans";
		CVars   = CVars;
		Options = {
			default = defaults;
			-- TODO: Maybe some other nice defaults?
		};
		MenuButton = 1;
	});

	do -- NPC Selector

		local CPanel = AddControl(CPanel, "ControlPanel", "panel_npc");

		-- Type select
		AddControl(CPanel, "NPCSpawnSelecter", "npc");

		-- Weapon select
		AddControl(CPanel, "NPCWeaponSelecter", "weapon");

	end

	do
		local CPanel = AddControl(CPanel, "ControlPanel", "panel_spawning");

		-- Timer select
		AddControl(CPanel, "Slider", "delay", {
			Type        = "Float";
			Min         = npcspawner.config.mindelay;
			Max         = 60;
			Description = true;
		});
		-- Maximum select
		AddControl(CPanel, "Slider", "maximum", {
			Type        = "Integer";
			Min         = 1;
			Max         = npcspawner.config.maxinplay;
			Description = true;
		});
		-- Maximum Ever
		AddControl(CPanel, "Slider", "totallimit", {
			Type        = "Integer";
			Min         = 0;
			Max         = 100;
			Description = true;
		});
		-- Autoremove select
		AddControl(CPanel, "Checkbox", "autoremove", {
			Description = true;
		});
	end

	do -- VJ Human stuff
		local CPanel = AddControl(CPanel, "ControlPanel", "panel_vjhuman");
		AddControl(CPanel, "Slider", "vjhealth", {
			Type        = "Integer";
			Min         = 0;
			Max         = 300;
			Description = true;
		});
		AddControl(CPanel, "Slider", "vjshootdist", {
			Type        = "Float";
			Min         = 0;
			Max         = 10000;
			Description = true;
		});
		AddControl(CPanel, "Slider", "vjweaponspread", {
			Type        = "Float";
			Min         = 0;
			Max         = 20;
			Description = true;
		});
		AddControl(CPanel, "Checkbox", "vjcanmoveshoot", {
			Description = true;
		});
		AddControl(CPanel, "Checkbox", "vjcanmelee", {
			Description = true;
		});
		AddControl(CPanel, "Slider", "vjmeleedamage", {
			Type        = "Integer";
			Min         = 0;
			Max         = 300;
			Description = true;
		});
		AddControl(CPanel, "Checkbox", "vjcangrenade", {
			Description = true;
		});

		AddControl(CPanel, "Checkbox", "vjishostile", {
			Description = true;
		});

	end

	do
		local CPanel = AddControl(CPanel, "ControlPanel", "panel_activation");
		--Numpad on/off select
		CPanel:AddControl("Numpad", { -- Someone always has to be special
			Label       = lang "keys.on";
			Label2      = lang "keys.off";
			Command     = cvar "onkey";
			Command2    = cvar "offkey";
		});
		--Toggleable select
		AddControl(CPanel, "Checkbox", "toggleable", {
		});
		--Active select
		AddControl(CPanel, "Checkbox", "active");
	end

	do -- Positions

		local CPanel = AddControl(CPanel, "ControlPanel", "panel_positioning", {
			Closed = true;
		});
		CPanel:Help(lang "positioning.help");
		-- Nocollide
		AddControl(CPanel, "Checkbox", "nocollide");
		--Spawnheight select
		AddControl(CPanel, "Slider", "spawnheight", {
			Type        = "Float";
			Min         = 8;
			Max         = 128;
			Description = true;
		});
		--Spawnradius select
		AddControl(CPanel, "Slider", "spawnradius", {
			Type        = "Float";
			Min         = 0;
			Max         = 128;
			Description = true;
		});

	end
	do -- Other
		local CPanel = AddControl(CPanel, "ControlPanel", "panel_other", {
			Closed = true;
		});
		-- Global Squad On/Off
		AddControl(CPanel, "Checkbox", "frozen");
		-- Global Squads
		CPanel:Help(lang "squads.help1");
		CPanel:Help(lang "squads.help2");
		-- Global Squad On/Off
		AddControl(CPanel, "Checkbox", "customsquads");
		-- Custom Squad Picker
		AddControl(CPanel, "Slider", "squadoverride", {
			Type        = "Integer";
			Min         = 1;
			Max         = 50;
		});

		AddControl(CPanel, "Textbox", "vjoverrideclass");
		AddControl(CPanel, "Textbox", "vjnpcsuffixifhostile", {
			Description = true;
		});
	end
	do --batcher
		local batcherCat = vgui.Create("DForm");

		local function refillComboxWithPresets(combox)
			combox:Clear();
			for presetName, _ in pairs(presets.GetTable("spawnplatform_vjhumans")) do
				combox:AddChoice(presetName);
			end

			combox:ChooseOptionID(1);
		end

		local function chooseComboxEntryByName(combox, name)
			local index = 1;
			local entryTxt = combox:GetOptionText(index);
			while(entryTxt ~= nil and entryTxt ~= '') do
				if(entryTxt == name) then
					combox:ChooseOptionID(index);
					return;
				else
					index = index + 1;
					entryTxt = combox:GetOptionText(index);
				end
			end

			print("(VJHumans Spawn Batcher) couldn't find preset with provided name: " .. name);
		end

		batcherCat:SetName(lang("panel_batcher"));

		batcherCat:Help(lang "batcher.help1");


		local batchList = vgui.Create("VJHumanSpawnPlatBatcherList");
		local function onRowSelected(panel, _, line)
			chooseComboxEntryByName(presetsBox.DropDown, line:GetColumnText(1));

			local amount = line:GetColumnText(2);
			local hostile = line:GetColumnText(3);

			RunConsoleCommand(cvar("totallimit"), amount);

			if(hostile ~= nil and hostile ~= '') then
				if(hostile == true) then
					RunConsoleCommand(cvar("vjishostile"), "1");
				else
					RunConsoleCommand(cvar("vjishostile"), "0");
				end
			end

			local sharedMaxInAction = cvars.Number(cvar("batcher_totalmaxinaction"), 0);

			if(sharedMaxInAction > 0) then
				local totalAmountInList = panel:GetTotalAmountInEntries();
				local maxInAction = sharedMaxInAction * (amount / totalAmountInList);
				if(maxInAction < 1)then
					 maxInAction = 1;
				 elseif(maxInAction > npcspawner.config.maxinplay)then
					 maxInAction = npcspawner.config.maxinplay;
				 end
				npcspawner.debug("max in action for selected entry is " .. maxInAction);
				RunConsoleCommand(cvar("maximum"), maxInAction);
			end
		end
		batchList.OnRowSelected = onRowSelected;
		batcherCat:AddItem(batchList);

		local totalSlider = batcherCat:NumSlider(lang("batcher_totalmaxinaction"), cvar("batcher_totalmaxinaction"), 0, 50, 0);
		totalSlider:SetToolTip(lang("batcher_totalmaxinaction.desc"));

		addedBtn = batcherCat:Button(lang("btn_rmselfrombatcher"));
		addedBtn.DoClick = function()
			if(batchList:GetSelectedLine()) then
				batchList:RemoveLine(batchList:GetSelectedLine());
			end
		end

		addedBtn = batcherCat:Button(lang("btn_clearbatcher"));
		addedBtn.DoClick = function()
			batchList:Clear();
		end


		-- batcherCat:Help(lang "batcher.help2"); --add/remove manual entry stuff goes here
		local addManualCat = vgui.Create("DForm");
		addManualCat:SetLabel(lang("panel_batcher_addmanual"));

		local pickPresetBox = addManualCat:ComboBox(lang("batcher_addentry_name"));
		refillComboxWithPresets(pickPresetBox);

		local presetAmount = addManualCat:NumberWang(lang("batcher_addentry_amount"), nil, 0, 999, 0);
		local presetHostile = addManualCat:CheckBox(lang("vjishostile"));

		local addedBtn = addManualCat:Button(lang("btn_addtobatcher"));
		addedBtn.DoClick = function()
			batchList:AddLine(pickPresetBox:GetSelected(),
			presetAmount:GetValue(),
			 presetHostile:GetChecked());
		end

		addedBtn = addManualCat:Button(lang("btn_reloadpresets"));
		addedBtn.DoClick = function()
			refillComboxWithPresets(pickPresetBox);
		end

		batcherCat:AddItem(addManualCat);



		--JSON stuff goes here
		local addJSONCat = vgui.Create("DForm");
		addJSONCat:SetLabel(lang("panel_batcher_addjson"));

		addJSONCat:Help(lang "batcher.help2");

		local jsonField = addJSONCat:TextEntry(lang("batcher_inputjson"));

		addedBtn = addJSONCat:Button(lang("btn_addtobatcher_json"));

		addedBtn.DoClick = function()
			local rawJson = jsonField:GetValue();
			local importedTable = util.JSONToTable(rawJson);
			local attributeCounter = 0;

			if(istable(importedTable))then

				for listObj, troops in pairs(importedTable) do
					for _, entry in pairs(troops) do
						batchList:AddLine(entry.name,
						entry.amount,
						 entry.hostile);
					end
				end
			else
				print("(VJHumans Spawn Batcher) Failed to import JSON from provided string!");
			end
		end

		batcherCat:AddItem(addJSONCat);

		CPanel:AddItem(batcherCat);


	end
end
