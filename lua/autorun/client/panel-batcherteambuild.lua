--[[
	NPC Spawn Platforms V2 - lua/autorun/client/panel-npcselect.lua
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

local PANEL = {};

DEFINE_BASECLASS "DListView";


function PANEL:Init()

	self:SetMultiSelect( false );
	self:AddColumn( "#preset" );
	self:AddColumn( "#amount" );
	self:AddColumn( "#hostile" );

	self:SortByColumn(2, false);

	self:SetTall(100);
	-- self.list = ctrl;

end

function PANEL:GetTotalAmountInEntries()
	local total = 0;
	local curLineValue = 0;

	for k, line in pairs(self:GetLines()) do
		curLineValue = line:GetValue(2);
		if(curLineValue <= 0) then --infinite amounts should count as "a lot"
			total = total + 999;
		else
			total = total + curLineValue;
		end
	end

	return total;
end

function PANEL:ControlValues( data )
	if ( data.command ) then
		self:SetConVar( data.command );
	end
end

-- TODO: Think hook!

derma.DefineControl("VJHumanSpawnPlatBatcherList", "Selects NPC presets and their amounts", PANEL, "DListView")
