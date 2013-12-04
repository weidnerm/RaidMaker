-- ****************************************************
-- * ADDON TEMPLATE, CUSTOMIZE AT WILL *
-- ****************************************************
-- * NOTE: Any line with "--" in front of it will not be read by your computer.
-- * If you want any part of the code below to be read, remove the dashes, 
-- * or add dashes to comment out specific code. My commentary on functions etc.
-- * is prefaced with "-- *"


-- ****************************************************
-- * DECLARE VARIABLES * 
-- ****************************************************
-- * Add any variables you want available to functions here; for example,
--
-- * variable for CancelMyAuctions functions:
-- local CANCELMYAUCTIONSTEXT = "";

-- * variables for RaidMaker_IsBuffActive and RaidMaker_SetSpellCast functions:
--   RaidMaker_buffspell = "";
--   local AT_buffname = "Prayer of Mending";
local darkGrey   = "|c00252525";
local mediumGrey = "|c00707070";
local lightGrey  = "|c00a0a0a0";
local yellow = "|c00FFFF25";
local white  = "|c00FFFFff";
local red    = "|c00FF0000";
local green  = "|c0000ff00";
local blue   = "|c000000ff";
local raidPlayerDatabase = {};
local playerSortedList = {};
local raidConvertArmedFlag = false;
local raidLootTypeArmedFlag = false;
local numMembersToPromoteToAssist = 0;
local guildRankAssistThreshold = 3;  -- 0=Guild Master. 1=Officer; 2=Lieutenant; etc...  Controls if officers get assist.
                                     -- set to 0 for no promote. 1 for GM only, 2 for Officers, GM, etc
local raidMakerLaunchCalEditButton
local raidMakerLaunchCalViewButton
RaidMaker_testData = {};
local RaidMaker_testTrialNum = 1;
local RaidMaker_RollLog = {};
local RaidMaker_sortedRollList = {};
local RaidMaker_sortRollAlgorithm_id = 1;   -- 1=sort by roll value; 2=sort by time; 3=sort by playername

-- change to use the array instead of these locals
local classColorDeathKnight   = "|c00C41F3B";
local classColorDruid         = "|c00FF7D0A";
local classColorHunter        = "|c00ABD473";
local classColorMage          = "|c0069CCF0";
local classColorPaladin       = "|c00F58CBA";
local classColorPriest        = "|c00FFFFFF";
local classColorRogue         = "|c00FFF569";
local classColorShaman        = "|c002459FF";
local classColorWarlock       = "|c009482C9";
local classColorWarrior       = "|c00C79C6E";



-- ****************************************************
-- * ON_LOAD COMMANDS * 
-- ****************************************************
-- * Add any code that needs to be read OnLoad in the section below; for example,
-- * add or delete load messages, and add slash commands here.
--
-- * The first function below prints a small notification in chat to 
-- * let you know that the addon successfully loaded.
-- * useful components: how to add load message, pop up error messages, and set slash commands
--
function RaidMaker_OnLoad()
   if( DEFAULT_CHAT_FRAME ) then
      DEFAULT_CHAT_FRAME:AddMessage("RaidMaker Loaded.");
   end
   UIErrorsFrame:AddMessage("RaidMaker Loaded.", 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME);

-- * The two lines below add an in-game Slash Command for the GUI function, reinstate if 
-- * you are interested in using commands in the slash handler, including the mod's XML frames.
   SlashCmdList["RAIDMAKERCOMMAND"] = RaidMaker_Handler;
   SlashCmdList["RAIDMAKERMAINCOMMAND"] = RaidMaker_Handler;
   SLASH_RAIDMAKERCOMMAND1 = "/at";
   SLASH_RAIDMAKERMAINCOMMAND1 = "/rm";
--   SLASH_RAIDMAKERCOMMAND2 = "/addontemplate";

-- * The two lines below add an in-game Slash Command for the LootDogNow1 function.
--   SlashCmdList["LOOT_DOG_NOW1"] = LootDogNow1;
--   SLASH_LOOT_DOG_NOW11 = "/dog1";

-- * These two lines make a slash command for the Track Item function.
--  SlashCmdList["TRACK_ITEM"] = TrackItem;
--  SLASH_TRACK_ITEM1 = "/ti";

-- * These two lines make a slash command for the CancelMyAuctions function.
--   SlashCmdList["CANCEL_MY_AUCTIONS_COMMAND"] = CancelMyAuctionsCommand;
--   SLASH_CANCEL_MY_AUCTIONS_COMMAND1 = "/cma";

-- * The line below adds a colored load message with instructions for use the Track Item function.
--   DEFAULT_CHAT_FRAME:AddMessage("**To track an item, place it in slot 0,1 and use /ti to announce.**", 1.0, 0.35, 0.15);
-- end;
   RaidMaker_SetUpClassIcons();

end



-- ****************************************************
--   * SLASH HANDLER * 
-- ****************************************************
-- * The slash handler acts as a link between slash commands and functions, reinstate if you are 
-- * interested in seeing this mod's XML frames. If you have the frame code in the 
-- * RaidMaker.xml file active (default), this command opens the GUI template when activated.
-- * useful components: strip/interpret command from slash input, activate GUI window, colorize 
-- * chat text, output text to chat frame, set variable via slash command and report the change in chat
--
function RaidMaker_Handler(msg) 
   if (msg == "gui") then 
      RaidMaker_MainForm:Show();
      
   elseif (msg == "cal") then
      RaidMaker_HandleFetchCalButton();
      
   elseif (msg == "toggle") then
      if ( RaidMaker_MainForm:IsShown() == 1 ) then
         RaidMaker_MainForm:Hide();
      else
         RaidMaker_MainForm:Show();
      end
   elseif (msg == "show") then
      RaidMaker_MainForm:Show();
   elseif (msg == "hide") then
      RaidMaker_MainForm:Hide();
   elseif (msg == "text") then
      -- for testing purposes. can be deleted.
      RaidMaker_TabPage1_SampleTextTab1_GroupedState_1:SetText(red.."not");
      RaidMaker_TabPage1_SampleTextTab1_OnlineState_1:SetText(green.."online");
      RaidMaker_TabPage1_SampleTextTab1_InviteStatus_1:SetText(green.."Accepted");
      RaidMaker_TabPage1_SampleTextTab1_PlayerName_1:SetText(white.."Cellifalas");
      RaidMaker_TabPage1_SampleTextTab1_TankFlag_1:SetText(yellow.."X");
      RaidMaker_TabPage1_SampleTextTab1_HealFlag_1:SetText(yellow.."X");
      RaidMaker_TabPage1_SampleTextTab1_DpsFlag_1:SetText(yellow.."X");
      RaidMaker_TabPage1_SampleTextTab1_Class_1:SetText(yellow.."DRUID");

   raidMakerLaunchCalEditButton:SetParent(TradeSkillFrame)
--   raidMakerLaunchCalEditButton:SetParent(RaidMaker_MainForm)
--   scan_parent = raidMakerLaunchCalEditButton:GetParent()

   raidMakerLaunchCalEditButton:ClearAllPoints()
      
   raidMakerLaunchCalEditButton:SetPoint("RIGHT", TradeSkillFrameCloseButton, "LEFT",4,0)
--   raidMakerLaunchCalEditButton:SetPoint("TOPLEFT", RaidMaker_MainForm, "TOPRIGHT",5,-4)
   raidMakerLaunchCalEditButton:SetWidth(raidMakerLaunchCalEditButton:GetTextWidth() + 10)

--   raidMakerLaunchCalEditButton:Enable()
   raidMakerLaunchCalEditButton:Show()




--   elseif (msg == "secure on") then 
--      RaidMaker_BuffFrame:Show();
--   elseif (msg == "secure off") then 
--      RaidMaker_BuffFrame:Hide();
--   elseif (msg == "") or (msg == "help") then 
--      DEFAULT_CHAT_FRAME:AddMessage(yellow.."RaidMaker: '/at gui on' to show GUI template");
--      DEFAULT_CHAT_FRAME:AddMessage(yellow.."RaidMaker: '/at secure on' to show secure button, '/at secure off' to hide");
--      DEFAULT_CHAT_FRAME:AddMessage(yellow.."RaidMaker: use '/click RaidMaker_BuffFrame' to activate the button via macro");
--   elseif (msg ~= "") then
--      AT_buffname = msg;
--      DEFAULT_CHAT_FRAME:AddMessage(yellow.."RaidMaker: will check for "..AT_buffname..".");
   end
   
   
   
end



-- ****************************************************
-- * FUNCTIONS * 
-- ****************************************************
-- * Add your own functions in the section below. I've also included several basic but 
-- * useful functions below to get you started. 


-- function to announce rez in group-dependent chat and in whisper to target, used with the in-game macro below it works on allied/dead mouseover (takes priority if you have one) or current allied/dead target
-- in-game macro (adjust name of rez spell as necessary): 
-- /run ATRezFunction()
-- /cast [target=mouseover,help,exists,dead][target=target,help,dead] Resurrection

--function ATRezFunction()
--   local c;
--   if (GetNumRaidMembers()>0) then
--      c="RAID";
--   elseif (GetNumPartyMembers()>0) then
--      c="PARTY";
--   else c="SAY";
--   end
--   R=R or CreateFrame("Frame")
--   R:RegisterEvent("UNIT_SPELLCAST_SENT")
--   R:SetScript("OnEvent",
--   function(R,E,C,T,K,T)
--      SendChatMessage(GetRandomArgument("Rezzing "..T..".","Anyone not surprised that "..T.." is getting rezzed... again?", "Ok, "..T..", but this had better not be another attempt to get mouth to mouth!", "I am resurrecting "..T..".", "Ressurecting "..T.." now.", "Oh no, you died, "..T.."!", "Let me fix that, "..T..".", "Stop slacking and get back to work, "..T.."!", "Bringing you back from the dead now, "..T..".", "Oh noes, "..T.."'s got a wittle booboo!"),c)
--      SendChatMessage("Rez incoming, please accept...", "WHISPER", nil, UnitName(T))
--      R:UnregisterEvent(E)
--   end)
--end



-- ****************************************************
-- * IS DE/BUFF ACTIVE CHECKER AND RELATED FUNCTION * 
-- ****************************************************
-- * This function is good for checking to see if a target has a buff or debuff. In this example
-- * it checks the target to see if any of their buffs' names (AT_testname) matches the de/buff 
-- * we're looking for (AT_buffname)
-- * useful components: de/buff iterator
--
--function RaidMaker_IsBuffActive()
--   if (UnitIsDeadOrGhost("target")) then return; end      -- * ...then dead
--   if (not UnitIsConnected("target")) then return; end      -- * ...then DC
--   local AT_testname;
--   local i=1;
--   AT_testname,_,_,_,_,_,_,_,_=UnitBuff("target",1);    -- * buffs
--   while (AT_testname) do
--      if (AT_testname==AT_buffname) then 
--         return true;
--      end
--      i=i+1;
--      AT_testname,_,_,_,_,_,_,_,_=UnitBuff("target",i);
--   end
--   i=1;   -- * debuffs
--   AT_testname,_,_,_,_,_,_,_,_=UnitDebuff("target",1);
--   while (AT_testname) do
--      if (AT_testname==AT_buffname) then 
--         return true;
--      end
--      i=i+1;
--      AT_testname,_,_,_,_,_,_,_,_=UnitDebuff("target",i);
--   end
--end

-- * This function queries RaidMaker_IsBuffActive to see if the target has the buff of interest;
-- * if it is, it plays a little sound, if it isn't, it sets RaidMaker_buffspell to that 
-- * buffname where it can be cast by the secure XML frame.
-- * useful components: if...then variable setting, play sound.
--
--function RaidMaker_SetSpellCast()
--   if RaidMaker_IsBuffActive() then
--         RaidMaker_buffspell = "";
--         PlaySoundFile("Sound\\interface\\FriendJoin.wav");
--   else
--         RaidMaker_buffspell = AT_buffname;
--   end
--end




-- ****************************************************
-- * CANCEL MY AUCTIONS -- WITH INTERACTIVE FUNCTIONS * 
-- ****************************************************
-- * Functions to cancel all of your auctions named "FillInTheBlank"; set the item to be cancelled
-- * by activating and using the slash command above. Provides an example of AH scripting, 
-- * as well as a way to send a mod dynamic input via the chatline interface. Also shows how to strip
-- * the item name from an itemLink or itemString using GetItemInfo.
-- * syntax: "/cma Large Prismatic Shard" to set item to be cancelled
-- * syntax: "/cma all" to actually cancel those auctions
-- * syntax: "/cma" for usage info
--
--function CancelMyAuctionsCommand(msg)
--   if (msg == "") then
--      DEFAULT_CHAT_FRAME:AddMessage("Usage: '/cma 'ItemName'",1,1,0);
--      DEFAULT_CHAT_FRAME:AddMessage("Example: '/cma Large Prismatic Shard'",1,1,0);
--      DEFAULT_CHAT_FRAME:AddMessage("Example: '/cma all' to activate, AH window must be open",1,1,0);
--      DEFAULT_CHAT_FRAME:AddMessage("Enter ItemName as a name, item link, or item string; works with one item at a time.",1,1,0);
--   else
--      if (msg == "all") then
--         CancelMyAuctions();
--      else
--         if (msg ~= "") then
--            local d,_,_,_,_,_,_,_,_,_=GetItemInfo(msg)
--            CANCELMYAUCTIONSTEXT = d;
--            DEFAULT_CHAT_FRAME:AddMessage("Will cancel all auctions for: "..CANCELMYAUCTIONSTEXT..".",1,1,0);
--         end
--      end
--   end
--end
--
--function CancelMyAuctions()
--   local o="owner" p=GetNumAuctionItems(o) n=CANCELMYAUCTIONSTEXT;
--   for i=1,p do
--      local b,_,_,_,_,_,_,_,_=GetAuctionItemInfo(o,i);
--       if (b==n) then
--           CancelAuction(i);
--            DEFAULT_CHAT_FRAME:AddMessage("Canceling all auctions for: "..n.."...",1,1,0);
--       end
--   end
--end




-- ****************************************************
-- * AUTO-DIRECT CHAT MESSAGES * 
-- ****************************************************
-- * Function to auto-direct chat messages to say|party|raid|raidwarning channel depending on your 
-- * group status (all thanks to Thorbjorn, author of SendGroup)
-- * To use, uncomment the function below and for your ingame macros, use some version of the 
-- * following (English client, use single quotes for others): 
-- * /script sg("PutYourMessageHere"); 
--
-- function sg(m)
--    if (UnitName("raid1")) then
--       if ( IsRaidOfficer() ) then
--             SendChatMessage(m,"RAID_WARNING");
--          SendChatMessage(m,"RAID");
--       else
--          SendChatMessage(m,"RAID");
--       end
--    elseif (UnitName("party1")) then
--      SendChatMessage(m,"RAID_WARNING");
--       SendChatMessage(m,"PARTY");
--    else
--       SendChatMessage(m,"SAY");
--    end
-- end




-- ****************************************************
-- * TRACK ITEM AND ANNOUNCE * 
-- ****************************************************
-- * Put any item in the top left slot of your main backpack; when you call this function it counts
-- * the total number of the item you have in your bags and announces it to your party.
--
-- function TrackItem()
--    local itemLink = GetContainerItemLink(0,1); SendChatMessage("I have " .. GetItemCount(GetContainerItemLink(0,1)) .. "x" .. itemLink, "PARTY");
--  end



-- ****************************************************
-- * LOOT HAIKU * 
-- ****************************************************
-- * This function lets you send a haiku to a chat channel (here "raidchat", adjust as necessary)
-- * asking people to loot the dog, and adds a slash command "/dog1"(commented out, above) for 
-- * in-game use. Use with care, as too much haiku can be a dangerous thing!
-- 
-- function LootDogNow1()
--     SendChatMessage("Did you check for loot?", "CHANNEL", lang, GetChannelName("raidchat"));
--     SendChatMessage("Core Hounds carry things in the", "CHANNEL", lang, GetChannelName("raidchat"));
--     SendChatMessage("Strangest of places.", "CHANNEL", lang, GetChannelName("raidchat")); end



-- ****************************************************
-- * RANDOM PHRASE GENERATOR * 
-- ****************************************************
-- * This function lets you build a long list of phrases and then pick 
-- * one at random when casting a given spell or performing another action. 
-- * Note: replace the "Phrase #s" with your funny/cool sayings, and update 
-- * "random(1,6)" to reflect your final number of sayings ("1,50" for ex.).
-- * You can also substitute GUILD or RAID for SAY. English clients use double quotes ("),
-- * others use single quotes (') to separate phrases. All thanks to Tonukuropan for this code.
-- 
-- * In WoW, use the macro:
-- /cast YourDesiredSpellHere(Rank 1)
-- /script SendChatMessage(RandSay1(), "SAY") 
--
-- ***If you want to say something random a certain percent of the time, use the following in-game 
-- * macro instead. If you exclude "(Rank #)" it will automatically cast your highest rank of that spell. 
-- * This code will say something 1% of the time when casting; 
-- * changing the (100) to a (1) gives you 100%, or to (20) for 5% (or 1 time in 20):
-- * /cast YourDesiredSpellHere(Rank 1)
-- * /script if(math.random(100) == 1) then SendChatMessage(RandSay1(), "SAY") end
--
-- * To send the message to a non-standard channel, adapt the following in-game macro:
-- * /cast YourDesiredSpellHere(Rank 1)
-- * /script if(math.random(100) == 1) then SendChatMessage(RandSay1(), "CHANNEL", lang, GetChannelName("channelnamehere")) end

-- * Change the phrases below to whatever you want to say, and update the "6" in "random(1,6)" to 
-- * equal your final number of phrases. 
-- * Example phrases, with dynamic code:
-- * GetZoneText()..": You will never find a more wretched hive of scum and villainy. We must be cautious."
-- * "Resurrecting "..UnitName("target")..", please stand by..."
-- 
-- * To activate the addon uncomment the function below.
--
-- function RandSay1() 
--  local s = { 
--      "Phrase 1", "Phrase 2", 
--      "Phrase 3", "Phrase 4", 
--      "Phrase 5", "Phrase 6" 
--    }; 
--    local i = random(1,6); 
--    return s[i]; 
--  end; 

function RaidMaker_buildRaidList(origDatabase) 
   -- start a new database from scratch
   local newRaidDatabase = {};
   raidConvertArmedFlag = false;
   raidLootTypeArmedFlag = false;
   numMembersToPromoteToAssist = 0;

   -- get the raid title
   local title, description, creator, eventType, repeatOption, maxSize, textureIndex, weekday, month, day, year, hour, minute, lockoutWeekday, lockoutMonth, lockoutDay, lockoutYear, lockoutHour, lockoutMinute, locked, autoApprove, pendingInvite, inviteStatus, inviteType, calendarType = CalendarGetEventInfo();
  
   if ( title ~= nil ) then
   
      newRaidDatabase.title = title;
      
      if ( eventType == 1 ) or ( eventType == 2 ) then -- 1=Raid dungeon; 2=Five-player dungeon
         local raidName, icon, expansion, players= select(1+4*(textureIndex-1), CalendarEventGetTextures(eventType));
         newRaidDatabase.title = newRaidDatabase.title.." - "..raidName.."("..players..")";
      end
      
      newRaidDatabase.classCount = {};
      
      -- clear out the classcount field for all known classes (use RAID_CLASS_COLORS array for list of classes)
      local className, colorValue;
      for className,colorValue in pairs(RAID_CLASS_COLORS) do
         newRaidDatabase.classCount[className] = 0;  
      end   
   
      local numInvites;
      numInvites = CalendarEventGetNumInvites();
      
      newRaidDatabase.playerInfo = {}; -- create empty fields
      
      local name, level, className, classFileName, inviteStatus, modStatus, inviteIsMine, inviteType;
      for index=1,numInvites do
         name, level, className, classFileName, inviteStatus, modStatus, inviteIsMine, inviteType = CalendarEventGetInvite(index);
   --      print (green.."PlayerDB: "..white..name..red.."inviteStatus="..inviteStatus);
   
         newRaidDatabase.playerInfo[name] = {}; -- create empty fields
         newRaidDatabase.playerInfo[name].inviteStatus = inviteStatus; -- INVITED = 1;ACCEPTED = 2;DECLINED = 3;CONFIRMED = 4;OUT = 5;STANDBY = 6;SIGNEDUP = 7;NOT_SIGNEDUP = 8;TENTATIVE = 9
         newRaidDatabase.playerInfo[name].classFilename = classFileName; -- "WARRIOR", "PRIEST", etc
         
         newRaidDatabase.playerInfo[name].tank = 0;
         newRaidDatabase.playerInfo[name].heals = 0;
         newRaidDatabase.playerInfo[name].dps = 0;
   
         newRaidDatabase.playerInfo[name].online = 0;
   
         newRaidDatabase.playerInfo[name].inGroup = 0;
         if ( GetNumRaidMembers() == 0 ) then
            if (UnitInParty(name) ) then
               newRaidDatabase.playerInfo[name].inGroup = 1;
            end
         else
            if (UnitInRaid(name) ) then
               newRaidDatabase.playerInfo[name].inGroup = 1;
            end
         end
         
         newRaidDatabase.playerInfo[name].guildRankIndex = 100; -- big number. means uninitialized
         
         newRaidDatabase.playerInfo[name].partyInviteDeferred = 0; -- no party invite queued at this point.
   
      end
      
      -- set up ourself as dps as a default.
      local selfName = GetUnitName("player",true);
      newRaidDatabase.playerInfo[selfName].dps = 1;
      
   
      GuildRoster(); -- trigger a GUILD_ROSTER_UPDATE event so we can get the online/offline status of players.
   
      RaidMaker_GuildRosterUpdate(); -- try to querry database
      
      
      
      
   --   print (green.."RaidMaker: "..white.." title: "..red..newRaidDatabase.title);
   --   for charName,charFields in pairs(newRaidDatabase.playerInfo) do
   --      local charStatus = "";
   --      charStatus = charStatus..red.."cls="..yellow..charFields.classFilename;
   --      charStatus = charStatus..red..";inv="..yellow..charFields.inviteStatus;
   --      charStatus = charStatus..red..";t="..yellow..charFields.tank;
   --      charStatus = charStatus..red..";h="..yellow..charFields.heals;
   --      charStatus = charStatus..red..";d="..yellow..charFields.dps;
   --      charStatus = charStatus..red..";party="..yellow..charFields.inGroup;
   --      charStatus = charStatus..red..";on="..yellow..charFields.online;
   --      print (green.."PlayerDB: "..white..charName..":" ..charStatus);
   --   end     
   else
      print(red.."RaidMaker error: "..white.."Must open an event through the Calendar first.");
   end
      
   return newRaidDatabase;
end

function RaidMaker_GuildRosterUpdate(flag)
--   print("GUILD_ROSTER_UPDATE received");

   if ( raidPlayerDatabase ~= nil ) then -- only process if there is a database to parse.
      if ( raidPlayerDatabase.playerInfo ~= nil ) then
            
         local name,rank,rankIndex,level,class,zone,note,officernote,online,status,classFileName;
         local numGuildMembers = GetNumGuildMembers(true); --includeOffline

         for index=1,numGuildMembers do
            name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(index);

            if ( raidPlayerDatabase.playerInfo[name] ~= nil ) then
               -- player is included in calendar list. lets look them up.
               if ( online == 1 ) then
                  raidPlayerDatabase.playerInfo[name].online = 1;
               else
                  raidPlayerDatabase.playerInfo[name].online = 0;
               end
               
               raidPlayerDatabase.playerInfo[name].guildRankIndex = rankIndex;
            end
         end
         
         RaidMaker_DisplayDatabase();

      end
      
   end

end

function RaidMaker_DisplayDatabase()

   local currentRow = 1;
   local charName;
   
   if ( raidPlayerDatabase.title ~= nil ) then
      RaidMaker_TabPage1_RaidIdText:SetText(white..raidPlayerDatabase.title);
   end
   
   RaidMaker_TextTableUpdate(RaidMaker_VSlider:GetValue());
   
   -- update the metrics.
   local groupedCountForRaid = 0;
   local onlineCountForRaid = 0;
   local tankCountForRaid = 0;
   local healCountForRaid = 0;
   local dpsCountForRaid = 0;
   local playerCountForRaid = 0;
   
   for className,colorValue in pairs(RAID_CLASS_COLORS) do
      raidPlayerDatabase.classCount[className] = 0;  
   end   
   
   for rowIndex=1,#playerSortedList do
      charName = playerSortedList[rowIndex];
      
      if ( raidPlayerDatabase.playerInfo[charName].tank == 1 ) or
         ( raidPlayerDatabase.playerInfo[charName].heals == 1 ) or
         ( raidPlayerDatabase.playerInfo[charName].dps == 1) then

         if ( raidPlayerDatabase.playerInfo[charName].online == 1 ) then
            onlineCountForRaid  = onlineCountForRaid + 1;
         end

         playerCountForRaid  = playerCountForRaid + 1;
         
         if ( raidPlayerDatabase.playerInfo[charName].classFilename ~= nil) then
            raidPlayerDatabase.classCount[raidPlayerDatabase.playerInfo[charName].classFilename] =  -- add up our class totals
            raidPlayerDatabase.classCount[raidPlayerDatabase.playerInfo[charName].classFilename] + 1;
         end
      end   

      if ( raidPlayerDatabase.playerInfo[charName].tank == 1 ) then
         tankCountForRaid  = tankCountForRaid + 1;
      end

      if ( raidPlayerDatabase.playerInfo[charName].heals == 1 ) then
         healCountForRaid  = healCountForRaid + 1;
      end

      if ( raidPlayerDatabase.playerInfo[charName].dps == 1 ) then
         dpsCountForRaid  = dpsCountForRaid + 1;
      end

      if ( raidPlayerDatabase.playerInfo[charName].inGroup == 1 ) then
         groupedCountForRaid  = groupedCountForRaid + 1;
      end
         
          
   end
   
   
   
   -- Put the various totals into the right boxes.
   if ( groupedCountForRaid == 10 ) or ( groupedCountForRaid == 25 ) then
      RaidMaker_TabPage1_SampleTextTab1_GroupedState_21:SetText(green..groupedCountForRaid);
   else
      RaidMaker_TabPage1_SampleTextTab1_GroupedState_21:SetText(red..groupedCountForRaid);
   end
   if ( onlineCountForRaid == 10 ) or ( onlineCountForRaid == 25 ) then
      RaidMaker_TabPage1_SampleTextTab1_OnlineState_21:SetText(green..onlineCountForRaid);
   else
      RaidMaker_TabPage1_SampleTextTab1_OnlineState_21:SetText(red..onlineCountForRaid);
   end
   RaidMaker_TabPage1_SampleTextTab1_InviteStatus_21:SetText("raid totals");
   if ( playerCountForRaid == 10 ) or ( playerCountForRaid == 25 ) then
      RaidMaker_TabPage1_SampleTextTab1_PlayerName_21:SetText(green..playerCountForRaid);
   else
      RaidMaker_TabPage1_SampleTextTab1_PlayerName_21:SetText(red..playerCountForRaid);
   end
   RaidMaker_TabPage1_SampleTextTab1_TankFlag_21:SetText(tankCountForRaid);
   RaidMaker_TabPage1_SampleTextTab1_HealFlag_21:SetText(healCountForRaid);
   RaidMaker_TabPage1_SampleTextTab1_DpsFlag_21:SetText(dpsCountForRaid);
   RaidMaker_TabPage1_SampleTextTab1_Class_21:SetText(" ");
   
   -- update class count totals
   if ( raidPlayerDatabase.classCount["WARRIOR"] == 0) then
      RaidMaker_WarriorCount:SetText(mediumGrey..raidPlayerDatabase.classCount["WARRIOR"]);
   else
      RaidMaker_WarriorCount:SetText(green..raidPlayerDatabase.classCount["WARRIOR"]);
   end
   if ( raidPlayerDatabase.classCount["MAGE"] == 0) then
      RaidMaker_MageCount:SetText(mediumGrey..raidPlayerDatabase.classCount["MAGE"]);
   else
      RaidMaker_MageCount:SetText(green..raidPlayerDatabase.classCount["MAGE"]);
   end
   if ( raidPlayerDatabase.classCount["ROGUE"] == 0) then
      RaidMaker_RogueCount:SetText(mediumGrey..raidPlayerDatabase.classCount["ROGUE"]);
   else
      RaidMaker_RogueCount:SetText(green..raidPlayerDatabase.classCount["ROGUE"]);
   end
   if ( raidPlayerDatabase.classCount["DRUID"] == 0) then
      RaidMaker_DruidCount:SetText(mediumGrey..raidPlayerDatabase.classCount["DRUID"]);
   else
      RaidMaker_DruidCount:SetText(green..raidPlayerDatabase.classCount["DRUID"]);
   end
   if ( raidPlayerDatabase.classCount["HUNTER"] == 0) then
      RaidMaker_HunterCount:SetText(mediumGrey..raidPlayerDatabase.classCount["HUNTER"]);
   else
      RaidMaker_HunterCount:SetText(green..raidPlayerDatabase.classCount["HUNTER"]);
   end
   
   if ( raidPlayerDatabase.classCount["SHAMAN"] == 0) then
      RaidMaker_ShamanCount:SetText(mediumGrey..raidPlayerDatabase.classCount["SHAMAN"]);
   else
      RaidMaker_ShamanCount:SetText(green..raidPlayerDatabase.classCount["SHAMAN"]);
   end
   
   if ( raidPlayerDatabase.classCount["PRIEST"] == 0) then
      RaidMaker_PriestCount:SetText(mediumGrey..raidPlayerDatabase.classCount["PRIEST"]);
   else
      RaidMaker_PriestCount:SetText(green..raidPlayerDatabase.classCount["PRIEST"]);
   end
   
   if ( raidPlayerDatabase.classCount["WARLOCK"] == 0) then
      RaidMaker_WarlockCount:SetText(mediumGrey..raidPlayerDatabase.classCount["WARLOCK"]);
   else
      RaidMaker_WarlockCount:SetText(green..raidPlayerDatabase.classCount["WARLOCK"]);
   end
   
   if ( raidPlayerDatabase.classCount["PALADIN"] == 0) then
      RaidMaker_PaladinCount:SetText(mediumGrey..raidPlayerDatabase.classCount["PALADIN"]);
   else
      RaidMaker_PaladinCount:SetText(green..raidPlayerDatabase.classCount["PALADIN"]);
   end
   
   if ( raidPlayerDatabase.classCount["DEATHKNIGHT"] == 0) then
      RaidMaker_DeathknightCount:SetText(mediumGrey..raidPlayerDatabase.classCount["DEATHKNIGHT"]);
   else
      RaidMaker_DeathknightCount:SetText(green..raidPlayerDatabase.classCount["DEATHKNIGHT"]);
   end
   
   
   local sliderLimit;
   if ( #playerSortedList < 20 ) then
      sliderLimit = 19;
   else
      sliderLimit = #playerSortedList-19;
   end
   
   -- set up the slider to match the list length.
   RaidMaker_VSlider:SetMinMaxValues(1, sliderLimit);

end


function RaidMaker_buildPlayerListSort(inputDatabase)
   local playerCount = 1;
   local playerList = {};
   
   for charName,charFields in pairs(inputDatabase.playerInfo) do
      playerList[playerCount] = charName;
      
      playerCount = playerCount + 1;
   end

   return playerList;
   
end


-- table to help sort by acceptance level, i.e. ACCEPTED,CONFIRMED,SIGNEDUP first.  then STANDBY,TENTATIVE.  then INVITED,NOT_SIGNEDUP. etc.
local inviteSortOrder = 
{
  3, -- INVITED     
  1, -- ACCEPTED    
  4, -- DECLINED    
  1, -- CONFIRMED   
  4, -- OUT         
  2, -- STANDBY     
  1, -- SIGNEDUP    
  3, -- NOT_SIGNEDUP
  2, -- TENTATIVE   
};


function RaidMaker_ascendInviteStatusOrder(a,b)
   -- a,b are player names.
   local returnVal = false;
   
   if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      returnVal = true;
   elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] == inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
--      if ( raidPlayerDatabase.playerInfo[a].online > raidPlayerDatabase.playerInfo[b].online ) then
--         returnVal = true;
--      elseif ( raidPlayerDatabase.playerInfo[a].online == raidPlayerDatabase.playerInfo[b].online ) then
--         returnVal = a<b;
--      end
      returnVal = a<b;
   end

   return returnVal;
end

function RaidMaker_ascendTankOrder(a,b)
   -- a,b are player names.
   local returnVal = false;
   
   if ( raidPlayerDatabase.playerInfo[a].tank > raidPlayerDatabase.playerInfo[b].tank ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].tank == raidPlayerDatabase.playerInfo[b].tank ) then
      if ( raidPlayerDatabase.playerInfo[a].heals > raidPlayerDatabase.playerInfo[b].heals ) then
         return true;
      elseif ( raidPlayerDatabase.playerInfo[a].heals == raidPlayerDatabase.playerInfo[b].heals ) then
         if ( raidPlayerDatabase.playerInfo[a].dps > raidPlayerDatabase.playerInfo[b].dps ) then
            return true;
         elseif ( raidPlayerDatabase.playerInfo[a].dps == raidPlayerDatabase.playerInfo[b].dps ) then
            if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
               returnVal = true;
            elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] == inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
               returnVal = a<b;
            end
         end
      end
   end

   return returnVal;
end

function RaidMaker_ascendHealOrder(a,b)
   -- a,b are player names.
   local returnVal = false;
   
   if ( raidPlayerDatabase.playerInfo[a].heals > raidPlayerDatabase.playerInfo[b].heals ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].heals == raidPlayerDatabase.playerInfo[b].heals ) then
      if ( raidPlayerDatabase.playerInfo[a].tank > raidPlayerDatabase.playerInfo[b].tank ) then
         return true;
      elseif ( raidPlayerDatabase.playerInfo[a].tank == raidPlayerDatabase.playerInfo[b].tank ) then
         if ( raidPlayerDatabase.playerInfo[a].dps > raidPlayerDatabase.playerInfo[b].dps ) then
            return true;
         elseif ( raidPlayerDatabase.playerInfo[a].dps == raidPlayerDatabase.playerInfo[b].dps ) then
            if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
               returnVal = true;
            elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] == inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
               returnVal = a<b;
            end
         end
      end
   end

   return returnVal;
end

function RaidMaker_ascendDpsOrder(a,b)
   -- a,b are player names.
   local returnVal = false;
   
   if ( raidPlayerDatabase.playerInfo[a].dps > raidPlayerDatabase.playerInfo[b].dps ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].dps == raidPlayerDatabase.playerInfo[b].dps ) then
      if ( raidPlayerDatabase.playerInfo[a].tank > raidPlayerDatabase.playerInfo[b].tank ) then
         return true;
      elseif ( raidPlayerDatabase.playerInfo[a].tank == raidPlayerDatabase.playerInfo[b].tank ) then
         if ( raidPlayerDatabase.playerInfo[a].heals > raidPlayerDatabase.playerInfo[b].heals ) then
            return true;
         elseif ( raidPlayerDatabase.playerInfo[a].heals == raidPlayerDatabase.playerInfo[b].heals ) then
            if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
               returnVal = true;
            elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] == inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
               returnVal = a<b;
            end
         end
      end
   end

   return returnVal;
end

function RaidMaker_ascendClassOrder(a,b)
   -- a,b are player names.
   local returnVal = false;
   
   if ( raidPlayerDatabase.playerInfo[a].classFilename < raidPlayerDatabase.playerInfo[b].classFilename ) then
      returnVal = true;
   elseif ( raidPlayerDatabase.playerInfo[a].classFilename == raidPlayerDatabase.playerInfo[b].classFilename ) then
      returnVal = a<b;
   end

   return returnVal;
end

function RaidMaker_ascendPlayerNameOrder(a,b)
   -- a,b are player names.
   return a<b;
end

function RaidMaker_ascendOnlineStateOrder(a,b)
   -- a,b are player names.
   local returnVal = false;
   
   if ( raidPlayerDatabase.playerInfo[a].online > raidPlayerDatabase.playerInfo[b].online ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].online == raidPlayerDatabase.playerInfo[b].online ) then
      if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
         returnVal = true;
      elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] == inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
         returnVal = a<b;
      end
   end
   return returnVal;
end

function RaidMaker_ascendGroupedStateOrder(a,b)
   -- a,b are player names.
   local returnVal = false;
   
   if ( raidPlayerDatabase.playerInfo[a].inGroup > raidPlayerDatabase.playerInfo[b].inGroup ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].inGroup == raidPlayerDatabase.playerInfo[b].inGroup ) then
      if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
         returnVal = true;
      elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] == inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
         returnVal = a<b;
      end
   end
   return returnVal;
end



function RaidMaker_OnMouseWheel(self, delta)
   local current = RaidMaker_VSlider:GetValue()
   
   if (delta<0) and (current<#playerSortedList-19) then
      RaidMaker_VSlider:SetValue(current+1)
   elseif (delta>0) and (current>1) then
      RaidMaker_VSlider:SetValue(current-1)
   end
end


function RaidMaker_TextTableUpdate(startRow)

   local currentRow = 1;
   local charName;
--print("RaidMaker_TextTableUpdate("..startRow..")" );   
   
--   for charName,charFields in pairs(raidPlayerDatabase.playerInfo) do
   for rowIndex=startRow,#playerSortedList do
      charName = playerSortedList[rowIndex];

      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_GroupedState_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].inGroup == 0 ) then
         textBox:SetText(mediumGrey.."not");
      else
         textBox:SetText(green.."Raid");
      end
      
      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_OnlineState_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].online == 0 ) then
         textBox:SetText(mediumGrey.."offline");
      else
         textBox:SetText(green.."online");
      end
      
      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_InviteStatus_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].inviteStatus == 1 ) then
         textBox:SetText(mediumGrey.."Invited");
      elseif ( raidPlayerDatabase.playerInfo[charName].inviteStatus == 2 ) then
         textBox:SetText(green.."Accepted");
      elseif ( raidPlayerDatabase.playerInfo[charName].inviteStatus == 3 ) then
         textBox:SetText(red.."Declined");
      elseif ( raidPlayerDatabase.playerInfo[charName].inviteStatus == 4 ) then
         textBox:SetText(green.."Confirmed");
      elseif ( raidPlayerDatabase.playerInfo[charName].inviteStatus == 5 ) then
         textBox:SetText(red.."Out");
      elseif ( raidPlayerDatabase.playerInfo[charName].inviteStatus == 6 ) then
         textBox:SetText(yellow.."Standby");
      elseif ( raidPlayerDatabase.playerInfo[charName].inviteStatus == 7 ) then
         textBox:SetText(green.."Signed Up");
      elseif ( raidPlayerDatabase.playerInfo[charName].inviteStatus == 8 ) then
         textBox:SetText(red.."Not Signed Up");
      elseif ( raidPlayerDatabase.playerInfo[charName].inviteStatus == 9 ) then
         textBox:SetText(yellow.."Tentative");
      else
         textBox:SetText(darkGrey.."unknown");
      end
      
      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_PlayerName_"..currentRow);
      textBox:SetText(white..charName);

      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_TankFlag_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].tank == 0 ) then
         textBox:SetText(" ");
      else
         textBox:SetText(yellow.."X");
      end

      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_HealFlag_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].heals == 0 ) then
         textBox:SetText(" ");
      else
         textBox:SetText(yellow.."X");
      end

      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_DpsFlag_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].dps == 0 ) then
         textBox:SetText(" ");
      else
         textBox:SetText(yellow.."X");
      end

      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_Class_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].classFilename == "MAGE" ) then
         textBox:SetText(classColorMage.."Mage");
      elseif ( raidPlayerDatabase.playerInfo[charName].classFilename == "DEATHKNIGHT" ) then
         textBox:SetText(classColorDeathKnight.."Death Knight");
      elseif ( raidPlayerDatabase.playerInfo[charName].classFilename == "WARRIOR" ) then
         textBox:SetText(classColorWarrior.."Warrior");
      elseif ( raidPlayerDatabase.playerInfo[charName].classFilename == "PALADIN" ) then
         textBox:SetText(classColorPaladin.."Paladin");
      elseif ( raidPlayerDatabase.playerInfo[charName].classFilename == "PRIEST" ) then
         textBox:SetText(classColorPriest.."Priest");
      elseif ( raidPlayerDatabase.playerInfo[charName].classFilename == "WARLOCK" ) then
         textBox:SetText(classColorWarlock.."Warlock");
      elseif ( raidPlayerDatabase.playerInfo[charName].classFilename == "ROGUE" ) then
         textBox:SetText(classColorRogue.."Rogue");
      elseif ( raidPlayerDatabase.playerInfo[charName].classFilename == "DRUID" ) then
         textBox:SetText(classColorDruid.."Druid");
      elseif ( raidPlayerDatabase.playerInfo[charName].classFilename == "SHAMAN" ) then
         textBox:SetText(classColorShaman.."Shaman");
      elseif ( raidPlayerDatabase.playerInfo[charName].classFilename == "HUNTER" ) then
         textBox:SetText(classColorHunter.."Hunter");
      else
         textBox:SetText(darkGrey.."unknown");
      end

      currentRow = currentRow + 1;

      if ( currentRow > 20 ) then
         break;   -- abort the loop. the screen is full.
      end

   end
   
   if ( currentRow <= 20 ) then
      for blankRowNum=currentRow,20 do
         -- clear out the text areas. we are past the end of the raid members.
         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_GroupedState_"..blankRowNum);
         textBox:SetText(" ");
         
         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_OnlineState_"..blankRowNum);
         textBox:SetText(" ");
         
         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_InviteStatus_"..blankRowNum);
         textBox:SetText(" ");
         
         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_PlayerName_"..blankRowNum);
         textBox:SetText(" ");
         
         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_TankFlag_"..blankRowNum);
         textBox:SetText(" ");
         
         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_HealFlag_"..blankRowNum);
         textBox:SetText(" ");
         
         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_DpsFlag_"..blankRowNum);
         textBox:SetText(" ");
         
         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_Class_"..blankRowNum);
         textBox:SetText(" ");
      end 
   end     
end


function RaidMaker_ClickHandler_TankFlag(clickedRow)
   if ( clickedRow == 0 ) then
      -- sort according to tank as primary.
      table.sort(playerSortedList, RaidMaker_ascendTankOrder);
      RaidMaker_TextTableUpdate(RaidMaker_VSlider:GetValue());
   else
      local actualRow = clickedRow + RaidMaker_VSlider:GetValue()-1;
      if ( actualRow <= #playerSortedList ) then
         local clickedCharName = playerSortedList[actualRow];
         
         -- toggle the selection
         if ( raidPlayerDatabase.playerInfo[clickedCharName].tank == 1 ) then
            raidPlayerDatabase.playerInfo[clickedCharName].tank = 0;
         else
            raidPlayerDatabase.playerInfo[clickedCharName].tank = 1;
         end
         
         RaidMaker_DisplayDatabase();
      end
   end
end
function RaidMaker_ClickHandler_HealFlag(clickedRow)
   if ( clickedRow == 0 ) then
      -- sort according to tank as primary.
      table.sort(playerSortedList, RaidMaker_ascendHealOrder);
      RaidMaker_TextTableUpdate(RaidMaker_VSlider:GetValue());
   else
      local actualRow = clickedRow + RaidMaker_VSlider:GetValue()-1;
      if ( actualRow <= #playerSortedList ) then
         local clickedCharName = playerSortedList[actualRow];
         
         -- toggle the selection
         if ( raidPlayerDatabase.playerInfo[clickedCharName].heals == 1 ) then
            raidPlayerDatabase.playerInfo[clickedCharName].heals = 0;
         else
            raidPlayerDatabase.playerInfo[clickedCharName].heals = 1;
         end
         
         RaidMaker_DisplayDatabase();
      end
   end
end
function RaidMaker_ClickHandler_DpsFlag(clickedRow)
   if ( clickedRow == 0 ) then
      -- sort according to tank as primary.
      table.sort(playerSortedList, RaidMaker_ascendDpsOrder);
      RaidMaker_TextTableUpdate(RaidMaker_VSlider:GetValue());
   else
      local actualRow = clickedRow + RaidMaker_VSlider:GetValue()-1;
      if ( actualRow <= #playerSortedList ) then
         local clickedCharName = playerSortedList[actualRow];
         
         -- toggle the selection
         if ( raidPlayerDatabase.playerInfo[clickedCharName].dps == 1 ) then
            raidPlayerDatabase.playerInfo[clickedCharName].dps = 0;
         else
            raidPlayerDatabase.playerInfo[clickedCharName].dps = 1;
         end
         
         RaidMaker_DisplayDatabase();
      end
   end
end

function RaidMaker_ClickHandler_ClassHeader()
   table.sort(playerSortedList, RaidMaker_ascendClassOrder);
   RaidMaker_TextTableUpdate(RaidMaker_VSlider:GetValue());
end

function RaidMaker_ClickHandler_PlayerNameHeader()
      table.sort(playerSortedList, RaidMaker_ascendPlayerNameOrder);
      RaidMaker_TextTableUpdate(RaidMaker_VSlider:GetValue());
end

function RaidMaker_ClickHandler_InviteStatusHeader()
      table.sort(playerSortedList, RaidMaker_ascendInviteStatusOrder);
      RaidMaker_TextTableUpdate(RaidMaker_VSlider:GetValue());
end

function RaidMaker_ClickHandler_OnlineStateHeader()
      table.sort(playerSortedList, RaidMaker_ascendOnlineStateOrder);
      RaidMaker_TextTableUpdate(RaidMaker_VSlider:GetValue());
end

function RaidMaker_ClickHandler_GroupedStateHeader()
      table.sort(playerSortedList, RaidMaker_ascendGroupedStateOrder);
      RaidMaker_TextTableUpdate(RaidMaker_VSlider:GetValue());
end

function RaidMaker_handle_CHAT_MSG_LOOT(message, sender, language, channelString, target, flags, unknown1, channelNumber, channelName, unknown2, counter)
   local startIndex,endIndex,playerName,itemLink

RaidMaker_testData[RaidMaker_testTrialNum]=message; --for testing. delete me.
RaidMaker_testTrialNum = RaidMaker_testTrialNum +1; --for testing. delete me.

--CHAT_MSG_LOOT
--   You receive loot: [link].
--   Flapjacckk receive loot: [link].

   -- Check if another player won something
   startIndex,endIndex,playerName,itemLink = strfind(message, "(%a+) receives loot: (.*)." );
   if (playerName == nil ) then

      -- wasnt someone else getting loot. check if it was us.
      startIndex,endIndex,itemLink = strfind(message, "You receive loot: (.*)." );
      if (itemLink ~= nil ) then
         playerName = GetUnitName("player",true);
      end
   end

   -- if someone won something, parse the details.
   if (playerName ~= nil ) then
      local startIndex,endIndex,itemID = strfind(arg1, "(%d+):")
      local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemID);
      if ( quality == 4 ) or ( quality == 3 ) then -- epic(purple)=4;  superior(blue)=3;  green=2; white=1; grey=0
         -- epic loot found event.
         print(red.."Player="..playerName..white.." got "..green.." itemID="..itemID.." link="..itemLink);
      end
   end
end

function RaidMaker_handle_LOOT_OPENED(autoloot)
--print("LOOT_OPENED event: autoloot="..autoloot);
end

--function RaidMaker_handle_CHAT_MSG_EMOTE(autoloot)
--print("EMOTE event: sender="..sender.." msg="..message.." target="..target);
--end


function RaidMaker_handle_CHAT_MSG_GUILD(message, sender, language, channelString, target, flags, unknown1, channelNumber, channelName, unknown2, counter)
   RaidMaker_parse_for_pass(message, sender);
end

function RaidMaker_handle_CHAT_MSG_RAID(message, sender, language, channelString, target, flags, unknown1, channelNumber, channelName, unknown2, counter)
   RaidMaker_parse_for_pass(message, sender);
end

function RaidMaker_handle_CHAT_MSG_SAY(message, sender, language, channelString, target, flags, unknown1, channelNumber, channelName, unknown2, counter)
   RaidMaker_parse_for_pass(message, sender);
end

function RaidMaker_handle_CHAT_MSG_PARTY(message, sender, language, channelString, target, flags, unknown1, channelNumber, channelName, unknown2, counter)
   RaidMaker_parse_for_pass(message, sender);
end

function RaidMaker_parse_for_pass(message, playerName)
   local lowerCaseMessage = string.lower(message);
RaidMaker_testData[RaidMaker_testTrialNum]=playerName..message; --for testing. delete me.
RaidMaker_testTrialNum = RaidMaker_testTrialNum +1; --for testing. delete me.

   startIndex,endIndex = strfind(lowerCaseMessage, "pass" );
   if ( startIndex ~= nil ) then
print(yellow.."Pass found by "..red..playerName);
      RaidMaker_addRollEntryToRollLog(playerName, "0");
   end
end

function RaidMaker_addRollEntryToRollLog(playerName, rollValue)
   local loggedEntryIndex;
   
   loggedEntryIndex = #RaidMaker_RollLog+1;
   RaidMaker_RollLog[loggedEntryIndex] = {};  -- make it a structure so we can put some fields in.
   RaidMaker_RollLog[loggedEntryIndex].rollValue = rollValue;
   RaidMaker_RollLog[loggedEntryIndex].playerName = playerName;
   RaidMaker_RollLog[loggedEntryIndex].epocTime = time();

   -- need to resort and redisplay
   RaidMaker_resortRollsList();
   RaidMaker_DisplayRollsDatabase();

end

function RaidMaker_DisplayRollsDatabase()
   
   local indexToDisplay;
   local playerNameColor;
   local rollValueColor;
   local rollAgeColor;
   local currentTime = time();
   local timeDeltaSeconds;
   
   for index = 1,10 do
--      indexToDisplay = index; -- eventually make this the sorted index starting at the scroll bar position.
      indexToDisplay = RaidMaker_sortedRollList[index]; -- eventually make this the sorted index starting at the scroll bar position.

      if ( index <= #RaidMaker_RollLog ) then
         -- It will fit on the screen and we are not past the end of the list.
         
         playerNameColor = white;
         rollValueColor = yellow;
         rollAgeColor = yellow;
         
         timeDeltaSeconds = currentTime - RaidMaker_RollLog[indexToDisplay].epocTime;
         
         if ( timeDeltaSeconds > (2*60) ) then -- roll is old. color the entry grey
            playerNameColor = mediumGrey;
            rollValueColor = mediumGrey;
            rollAgeColor = mediumGrey;
         end
         
         RaidMaker_LogTab_Rolls_FieldPlayerNames[index+1]:SetText(playerNameColor..RaidMaker_RollLog[indexToDisplay].playerName);
         RaidMaker_LogTab_Rolls_FieldRollValues[index+1]:SetText(rollValueColor..RaidMaker_RollLog[indexToDisplay].rollValue);
         RaidMaker_LogTab_Rolls_FieldRollAges[index+1]:SetText(rollAgeColor..timeDeltaSeconds);
      else
         -- blank out the row
         RaidMaker_LogTab_Rolls_FieldPlayerNames[index+1]:SetText(" ");
         RaidMaker_LogTab_Rolls_FieldRollValues[index+1]:SetText(" ");
         RaidMaker_LogTab_Rolls_FieldRollAges[index+1]:SetText(" ");
      end
   end
end

function RaidMaker_resortRollsList()
   local index

   RaidMaker_sortedRollList = {}; -- start with a blank array.
   
   for index = 1,#RaidMaker_RollLog do -- pre-fill the array 
      RaidMaker_sortedRollList[index] = index;
   end
   
   -- sort the table
   if ( RaidMaker_sortRollAlgorithm_id == 1 ) then -- sort by roll
      table.sort(RaidMaker_sortedRollList, RaidMaker_RollDisplay_descendRollOrder);
   elseif ( RaidMaker_sortRollAlgorithm_id == 2 ) then -- sort by age
      table.sort(RaidMaker_sortedRollList, RaidMaker_RollDisplay_ascendRollAgeOrder);
   elseif ( RaidMaker_sortRollAlgorithm_id == 3 ) then -- sort by player name
      table.sort(RaidMaker_sortedRollList, RaidMaker_RollDisplay_ascendPlayerNameOrder);
   else
      table.sort(RaidMaker_sortedRollList, RaidMaker_RollDisplay_descendRollOrder); -- default to roll value
   end

end


function RaidMaker_RollDisplay_descendRollOrder(a,b)
   -- a,b are indexes into the roll table.
   
   -- primary sort key
   if ( RaidMaker_RollLog[a].rollValue > RaidMaker_RollLog[b].rollValue ) then
      return true;
   elseif ( RaidMaker_RollLog[a].rollValue < RaidMaker_RollLog[b].rollValue ) then
      return false;
   end

   -- secondary sort key
   if ( RaidMaker_RollLog[a].epocTime < RaidMaker_RollLog[b].epocTime ) then
      return true;
   elseif ( RaidMaker_RollLog[a].epocTime > RaidMaker_RollLog[b].epocTime ) then
      return false;
   end
   
   -- third level sort key
   return RaidMaker_RollLog[a].playerName < RaidMaker_RollLog[a].playerName;
end

function RaidMaker_RollDisplay_ascendRollAgeOrder(a,b)
   -- a,b are indexes into the roll table.
   
   -- primary sort key
   if ( RaidMaker_RollLog[a].epocTime < RaidMaker_RollLog[b].epocTime ) then
      return true;
   elseif ( RaidMaker_RollLog[a].epocTime > RaidMaker_RollLog[b].epocTime ) then
      return false;
   end

   -- secondary sort key
   if ( RaidMaker_RollLog[a].rollValue > RaidMaker_RollLog[b].rollValue ) then
      return true;
   elseif ( RaidMaker_RollLog[a].rollValue < RaidMaker_RollLog[b].rollValue ) then
      return false;
   end
   
   -- third level sort key
   return RaidMaker_RollLog[a].playerName < RaidMaker_RollLog[a].playerName;

end

function RaidMaker_RollDisplay_ascendPlayerNameOrder(a,b)
   -- a,b are indexes into the roll table.
   
   return RaidMaker_RollLog[a].playerName < RaidMaker_RollLog[a].playerName;
end


function RaidMaker_handle_CHAT_MSG_SYSTEM(message, sender, language, channelString, target, flags, unknown1, channelNumber, channelName, unknown2, counter)

-- Lotusblossem has gone offline
-- [Lotusblossem] has come online.
print("MSG_SYSTEM event");
RaidMaker_testData[RaidMaker_testTrialNum]=message;
RaidMaker_testTrialNum = RaidMaker_testTrialNum +1;

   startIndex,endIndex,playerName,rollValue = strfind(message, "^(%a+) rolls (%d+) .*1-100%)" );
   if ( rollValue ~= nil ) then
      -- roll event detected.
print(white.."Roll of "..red..rollValue..white.." done by "..green..playerName);
      RaidMaker_addRollEntryToRollLog(playerName, rollValue);
   end
   
   startIndex,endIndex,playerName = strfind(message, "(%a+)]|h has come online." );
   if ( playerName ~= nil ) then
      -- player online status.
--      print(white..playerName..yellow.." has come "..green.."online");
      if ( raidPlayerDatabase ~= nil ) then -- only process if there is a database to parse.
         if ( raidPlayerDatabase.playerInfo ~= nil ) then
            if ( raidPlayerDatabase.playerInfo[playerName] ~= nil ) then
               raidPlayerDatabase.playerInfo[playerName].online = 1;
               RaidMaker_DisplayDatabase();
            end
         end
      end
   end
   
   startIndex,endIndex,playerName = strfind(message, "^(%a+) has gone offline." );
   if ( playerName ~= nil ) then
      -- player offline status.
--      print(white..playerName..yellow.." has gone "..red.."offline");
      if ( raidPlayerDatabase ~= nil ) then -- only process if there is a database to parse.
         if ( raidPlayerDatabase.playerInfo ~= nil ) then
            if ( raidPlayerDatabase.playerInfo[playerName] ~= nil ) then
               raidPlayerDatabase.playerInfo[playerName].online = 0;
               RaidMaker_DisplayDatabase();
            end
         end
      end
   end
   
   
end




function RaidMaker_handle_CALENDAR_OPEN_EVENT(selection)
   if ( selection == "PLAYER" ) then
   
      raidMakerLaunchCalEditButton:SetParent(CalendarCreateEventFrame)
      raidMakerLaunchCalEditButton:ClearAllPoints()
      raidMakerLaunchCalEditButton:SetPoint("RIGHT", CalendarCreateEventCloseButton, "LEFT",4,0)
      raidMakerLaunchCalEditButton:SetWidth(raidMakerLaunchCalEditButton:GetTextWidth() + 10)
      raidMakerLaunchCalEditButton:Enable()
      raidMakerLaunchCalEditButton:Show()
      
      
      raidMakerLaunchCalViewButton:SetParent(CalendarViewEventFrame)
      raidMakerLaunchCalViewButton:ClearAllPoints()
      raidMakerLaunchCalViewButton:SetPoint("RIGHT", CalendarViewEventCloseButton, "LEFT",4,0)
      raidMakerLaunchCalViewButton:SetWidth(raidMakerLaunchCalViewButton:GetTextWidth() + 10)
      raidMakerLaunchCalViewButton:Enable()
      raidMakerLaunchCalViewButton:Show()
   end
end

function RaidMaker_handle_PARTY_MEMBERS_CHANGED()

   if ( raidPlayerDatabase ~= nil ) then -- only process if there is a database to parse.
      if ( raidPlayerDatabase.playerInfo ~= nil ) then

         -- only set up the group if the user has selected the feature.
         if ( raidConvertArmedFlag == true ) then
            
            if ( GetNumRaidMembers() == 0 ) then
               -- we are not in a raid. might need to convert it to one
                        
               if ( GetNumPartyMembers() > 0 ) then
                  -- we are in a party. lets convert it to a raid.
                  raidConvertArmedFlag = false; -- dont run this again.
      
                  ConvertToRaid();
                  
                  -- set master looter
                  local selfName = GetUnitName("player",true); -- get the raid leader name (one running this)
                  SetLootMethod("master", selfName);
      
                  -- set loot rules
                  raidLootTypeArmedFlag = true;
               end
            else
               -- we are already in a raid.  just need to configure looting.
               raidConvertArmedFlag = false; -- dont run this again.
      
               -- set master looter
               local selfName = GetUnitName("player",true); -- get the raid leader name (one running this)
               SetLootMethod("master", selfName, 4);
               
               -- set loot rules
               raidLootTypeArmedFlag = true;
                              
            end
         elseif ( raidLootTypeArmedFlag == true ) then
            raidLootTypeArmedFlag = false;
            -- set loot rules
            SetLootThreshold(4);  -- set the threshold to epic.
            
            -- invite the pending players
            for rowIndex=1,#playerSortedList do
               charName = playerSortedList[rowIndex];
               if ( raidPlayerDatabase.playerInfo[charName].partyInviteDeferred == 1) then
                  -- player needs an invite
                  raidPlayerDatabase.playerInfo[charName].partyInviteDeferred = 0;
                  InviteUnit(charName);
--print("sending deferred invite to "..charName);
               end
            end
         end
      
            
         if ( numMembersToPromoteToAssist > 0 ) then -- do we have some assists left to promote
            
            local numRaidMembers = GetNumRaidMembers();
            
            if ( numRaidMembers > 0 ) then -- make sure we are in a raid already.
      
               -- loop through the raid members, promoting any tanks.
               for memberIndex=1,numRaidMembers do
               
                  local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(memberIndex);
                  -- promote any tanks who are not at the right level.
                  if (rank == 0 ) and -- 0 raid member;  1 raid assistant; 2 raid leader
                     (raidPlayerDatabase.playerInfo[name].tank == 1 ) then
                     -- We need to promote a tank.
                     PromoteToAssistant(name);
                     numMembersToPromoteToAssist = numMembersToPromoteToAssist - 1; -- account for the assist we promoted.
                  elseif (rank == 0 ) and -- 0 raid member;  1 raid assistant; 2 raid leader
                     (raidPlayerDatabase.playerInfo[name].guildRankIndex < guildRankAssistThreshold ) then
                     -- We need to promote an officer to assist.
                     PromoteToAssistant(name);
                     numMembersToPromoteToAssist = numMembersToPromoteToAssist - 1; -- account for the assist we promoted.
                  end
               end 
            end
         end
         
         -- update the database with online status and in group status
         
         for rowIndex=1,#playerSortedList do
            charName = playerSortedList[rowIndex];
            if (raidPlayerDatabase.playerInfo[charName] ~= nil ) then
               raidPlayerDatabase.playerInfo[charName].inGroup = 0;  -- clear everyone's status.  We'll update next.
            end
         end
         
         local numRaidMembers = GetNumRaidMembers();
            
         if ( numRaidMembers == 0 ) then -- make sure we are in a raid already.
            -- we are by ourself. set our flag only. 
            local selfName = GetUnitName("player",true); -- get the raid leader name (one running this)
            if ( raidPlayerDatabase.playerInfo[selfName] ~= nil ) then
               raidPlayerDatabase.playerInfo[selfName].inGroup = 1;
            end
         else
            -- update our party flags.
         end
      
         -- loop through the raid members, promoting any tanks.
         for memberIndex=1,numRaidMembers do
            
            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(memberIndex);
            -- promote any tanks who are not at the right level.
            if ( raidPlayerDatabase.playerInfo[name] ~= nil ) then
               if ( online == 1 ) then
                  raidPlayerDatabase.playerInfo[name].online = 1;
               else
                  raidPlayerDatabase.playerInfo[name].online = 0;
               end
               raidPlayerDatabase.playerInfo[name].inGroup = 1;
            end
         end
         
         RaidMaker_DisplayDatabase();
      end
   end
end

function RaidMaker_HandleSendInvitesButton()
   local selfName = GetUnitName("player",true); -- get the raid leader name (one running this)
   numMembersToPromoteToAssist = 0;
   local numInvitesToSendHere = 4 - GetNumPartyMembers();
--   local numInvitesToSendHere = 1;
   
   for rowIndex=1,#playerSortedList do
      charName = playerSortedList[rowIndex];

      -- invite everyone but ourself
      if ( selfName ~= charName ) then

         if ( raidPlayerDatabase.playerInfo[charName].tank == 1 ) or
            ( raidPlayerDatabase.playerInfo[charName].heals == 1 ) or
            ( raidPlayerDatabase.playerInfo[charName].dps == 1) then
               
            if ( raidPlayerDatabase.playerInfo[charName].tank == 1 ) or -- prepare to promote them when they join group.
               (raidPlayerDatabase.playerInfo[charName].guildRankIndex < guildRankAssistThreshold ) then
               numMembersToPromoteToAssist = numMembersToPromoteToAssist +1;
            end

            if ( UnitInRaid(charName) == nil ) then -- player isnt in raid already. need to bring them in.
               if ( numInvitesToSendHere >= 1 ) then
                  
                  
                  numInvitesToSendHere = numInvitesToSendHere - 1;
                  
--print("sending invite to "..charName);
                  
                  InviteUnit(charName);


               else
                  -- need to defer the invitation.
                  raidPlayerDatabase.playerInfo[charName].partyInviteDeferred = 1;
--print("Deferring invite to "..charName);
               end
            end
         end
      end
   end
   raidConvertArmedFlag = true; -- indicate that on subsequent party change event we might need to convert to raid and configure looting.
   
 end

function RaidMaker_HandleFetchCalButton()
   raidPlayerDatabase = RaidMaker_buildRaidList(raidPlayerDatabase);
   if ( raidPlayerDatabase.title ~= nil ) then
      playerSortedList = RaidMaker_buildPlayerListSort(raidPlayerDatabase);
      table.sort(playerSortedList, RaidMaker_ascendInviteStatusOrder);
      RaidMaker_DisplayDatabase();
   end
end

function RaidMaker_HandleSendRaidAnnouncementButton()
   if ( raidPlayerDatabase.title ~= nil ) then
      SendChatMessage("Invites will be coming soon for: "..raidPlayerDatabase.title, "GUILD" );
   end
end

function RaidMaker_HandleAnnounceInvitesDoneButton()
   if ( raidPlayerDatabase.title ~= nil ) then
      SendChatMessage("Invites have been sent for: "..raidPlayerDatabase.title..".  Thank you to all who signed up.", "GUILD" );
   end
end



function RaidMaker_HandleSendRolesToRaidButton()

   local tankList = "";
   local healList = "";
   local dpslist = "";
   local tankCount = 0;
   local healCount = 0;
   local dpsCount = 0;
   

   for rowIndex=1,#playerSortedList do
      charName = playerSortedList[rowIndex];

      if ( raidPlayerDatabase.playerInfo[charName].tank == 1 ) then
         if ( tankCount ~= 0 ) then
            tankList = tankList..", ";
         end
         tankList = tankList..charName
         tankCount = tankCount + 1;
      end
      if ( raidPlayerDatabase.playerInfo[charName].heals == 1 ) then
         if ( healCount ~= 0 ) then
            healList = healList..", ";
         end
         healList = healList..charName
         healCount = healCount + 1;
      end
      if ( raidPlayerDatabase.playerInfo[charName].dps == 1) then
         if ( dpsCount ~= 0 ) then
            dpslist = dpslist..", ";
         end
         dpslist = dpslist..charName
         dpsCount = dpsCount + 1;
      end
   end
   
   SendChatMessage("Roles for the raid are:", "RAID" );
   SendChatMessage("   Tanks: "..tankList , "RAID" );
   SendChatMessage("   Healers: "..healList , "RAID" );
   SendChatMessage("   DPS: "..dpslist , "RAID" );
   
end

function RaidMaker_SetUpClassIcons()
   local index;

   -- 
   -- Set up the Class Icons.
   --
   
   -- take the Blizzard UI graphic with a grid of 4x4 class icons and crop out the desired class one at a time.
   -- Warrior
   CreateFrame("Frame", "RaidMaker_WarriorClassPicture", RaidMaker_TabPage1_SampleTextTab1 )
   RaidMaker_WarriorClassPicture:SetWidth(25)
   RaidMaker_WarriorClassPicture:SetHeight(25)
   RaidMaker_WarriorClassPicture:SetPoint("TOPRIGHT", RaidMaker_WarriorCount, "TOPLEFT", 0,3)
   RaidMaker_WarriorClassPicture:CreateTexture("RaidMaker_WarriorClassPictureTexture")
   RaidMaker_WarriorClassPictureTexture:SetAllPoints()
   RaidMaker_WarriorClassPictureTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   RaidMaker_WarriorClassPictureTexture:SetTexCoord(0,0.25,0,0.25)
   -- mage
   CreateFrame("Frame", "RaidMaker_MageClassPicture", RaidMaker_TabPage1_SampleTextTab1 )
   RaidMaker_MageClassPicture:SetWidth(25)
   RaidMaker_MageClassPicture:SetHeight(25)
   RaidMaker_MageClassPicture:SetPoint("TOPRIGHT", RaidMaker_MageCount, "TOPLEFT", 0,3)
   RaidMaker_MageClassPicture:CreateTexture("RaidMaker_MageClassPictureTexture")
   RaidMaker_MageClassPictureTexture:SetAllPoints()
   RaidMaker_MageClassPictureTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   RaidMaker_MageClassPictureTexture:SetTexCoord(.25,0.5,0,0.25)
   -- rogue
   CreateFrame("Frame", "RaidMaker_RogueClassPicture", RaidMaker_TabPage1_SampleTextTab1 )
   RaidMaker_RogueClassPicture:SetWidth(25)
   RaidMaker_RogueClassPicture:SetHeight(25)
   RaidMaker_RogueClassPicture:SetPoint("TOPRIGHT", RaidMaker_RogueCount, "TOPLEFT", 0,3)
   RaidMaker_RogueClassPicture:CreateTexture("RaidMaker_RogueClassPictureTexture")
   RaidMaker_RogueClassPictureTexture:SetAllPoints()
   RaidMaker_RogueClassPictureTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   RaidMaker_RogueClassPictureTexture:SetTexCoord(0.5,0.75,0,0.25)
   -- druid
   CreateFrame("Frame", "RaidMaker_DruidClassPicture", RaidMaker_TabPage1_SampleTextTab1 )
   RaidMaker_DruidClassPicture:SetWidth(25)
   RaidMaker_DruidClassPicture:SetHeight(25)
   RaidMaker_DruidClassPicture:SetPoint("TOPRIGHT", RaidMaker_DruidCount, "TOPLEFT", 0,3)
   RaidMaker_DruidClassPicture:CreateTexture("RaidMaker_DruidClassPictureTexture")
   RaidMaker_DruidClassPictureTexture:SetAllPoints()
   RaidMaker_DruidClassPictureTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   RaidMaker_DruidClassPictureTexture:SetTexCoord(0.75,1.0,0,0.25)
   -- hunter
   CreateFrame("Frame", "RaidMaker_HunterClassPicture", RaidMaker_TabPage1_SampleTextTab1 )
   RaidMaker_HunterClassPicture:SetWidth(25)
   RaidMaker_HunterClassPicture:SetHeight(25)
   RaidMaker_HunterClassPicture:SetPoint("TOPRIGHT", RaidMaker_HunterCount, "TOPLEFT", 0,3)
   RaidMaker_HunterClassPicture:CreateTexture("RaidMaker_HunterClassPictureTexture")
   RaidMaker_HunterClassPictureTexture:SetAllPoints()
   RaidMaker_HunterClassPictureTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   RaidMaker_HunterClassPictureTexture:SetTexCoord(0,0.25,0.25,0.5)
   -- shaman
   CreateFrame("Frame", "RaidMaker_ShamanClassPicture", RaidMaker_TabPage1_SampleTextTab1 )
   RaidMaker_ShamanClassPicture:SetWidth(25)
   RaidMaker_ShamanClassPicture:SetHeight(25)
   RaidMaker_ShamanClassPicture:SetPoint("TOPRIGHT", RaidMaker_ShamanCount, "TOPLEFT", 0,3)
   RaidMaker_ShamanClassPicture:CreateTexture("RaidMaker_ShamanClassPictureTexture")
   RaidMaker_ShamanClassPictureTexture:SetAllPoints()
   RaidMaker_ShamanClassPictureTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   RaidMaker_ShamanClassPictureTexture:SetTexCoord(.25,0.5,0.25,0.5)
   -- priest
   CreateFrame("Frame", "RaidMaker_PriestClassPicture", RaidMaker_TabPage1_SampleTextTab1 )
   RaidMaker_PriestClassPicture:SetWidth(25)
   RaidMaker_PriestClassPicture:SetHeight(25)
   RaidMaker_PriestClassPicture:SetPoint("TOPRIGHT", RaidMaker_PriestCount, "TOPLEFT", 0,3)
   RaidMaker_PriestClassPicture:CreateTexture("RaidMaker_PriestClassPictureTexture")
   RaidMaker_PriestClassPictureTexture:SetAllPoints()
   RaidMaker_PriestClassPictureTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   RaidMaker_PriestClassPictureTexture:SetTexCoord(0.5,0.75,0.25,0.5)
   -- warlock
   CreateFrame("Frame", "RaidMaker_WarlockClassPicture", RaidMaker_TabPage1_SampleTextTab1 )
   RaidMaker_WarlockClassPicture:SetWidth(25)
   RaidMaker_WarlockClassPicture:SetHeight(25)
   RaidMaker_WarlockClassPicture:SetPoint("TOPRIGHT", RaidMaker_WarlockCount, "TOPLEFT", 0,3)
   RaidMaker_WarlockClassPicture:CreateTexture("RaidMaker_WarlockClassPictureTexture")
   RaidMaker_WarlockClassPictureTexture:SetAllPoints()
   RaidMaker_WarlockClassPictureTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   RaidMaker_WarlockClassPictureTexture:SetTexCoord(0.75,1.0,0.25,0.5)
   --   paladin
   CreateFrame("Frame", "RaidMaker_PaladinClassPicture", RaidMaker_TabPage1_SampleTextTab1 )
   RaidMaker_PaladinClassPicture:SetWidth(25)
   RaidMaker_PaladinClassPicture:SetHeight(25)
   RaidMaker_PaladinClassPicture:SetPoint("TOPRIGHT", RaidMaker_PaladinCount, "TOPLEFT", 0,3)
   RaidMaker_PaladinClassPicture:CreateTexture("RaidMaker_PaladinClassPictureTexture")
   RaidMaker_PaladinClassPictureTexture:SetAllPoints()
   RaidMaker_PaladinClassPictureTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   RaidMaker_PaladinClassPictureTexture:SetTexCoord(0,0.25,0.5,0.75)
   --   deathknight
   CreateFrame("Frame", "RaidMaker_DeathKnightClassPicture", RaidMaker_TabPage1_SampleTextTab1 )
   RaidMaker_DeathKnightClassPicture:SetWidth(25)
   RaidMaker_DeathKnightClassPicture:SetHeight(25)
   RaidMaker_DeathKnightClassPicture:SetPoint("TOPRIGHT", RaidMaker_DeathknightCount, "TOPLEFT", 0,3)
   RaidMaker_DeathKnightClassPicture:CreateTexture("RaidMaker_DeathKnightClassPictureTexture")
   RaidMaker_DeathKnightClassPictureTexture:SetAllPoints()
   RaidMaker_DeathKnightClassPictureTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
   RaidMaker_DeathKnightClassPictureTexture:SetTexCoord(.25,0.5,0.5,0.75)

   -- 
   -- Set up the tooltips for the buttons.
   --
   RaidMaker_FetchCalendarButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Fetches most recently opened calander and resets role selections.");
                  GameTooltip:Show()
               end)
   RaidMaker_FetchCalendarButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
   
   RaidMaker_SendAnnouncementButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Announces to /guild that invites will be coming soon.");
                  GameTooltip:Show()
               end)
   RaidMaker_SendAnnouncementButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
   
   RaidMaker_SendInvitesButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Sends group invites to all checked players and forms raid group.");
                  GameTooltip:Show()
               end)
   RaidMaker_SendInvitesButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
   
   RaidMaker_SendInvDoneMsgButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Sends msg to /guild indicating that all invites are sent.");
                  GameTooltip:Show()
               end)
   RaidMaker_SendInvDoneMsgButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_SendRolesButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Sends the list of tanks, healers, and dps to /raid.");
                  GameTooltip:Show()
               end)
   RaidMaker_SendRolesButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_ButtonRefresh:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Forces refresh on player online status.  Throttled by server.");
                  GameTooltip:Show()
               end)
   RaidMaker_ButtonRefresh:SetScript("OnLeave", function() GameTooltip:Hide() end)


   --
   -- Set up the RM button on the blizzard calendar event and calendar view screens.
   --
   
   -- create the button for the Raid Edit screen
   raidMakerLaunchCalEditButton = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
   raidMakerLaunchCalEditButton:SetHeight(20)

   raidMakerLaunchCalEditButton:RegisterForClicks("LeftButtonUp")
   raidMakerLaunchCalEditButton:SetScript("OnClick",
               function(self, button, down)

                  if RaidMaker_MainForm:IsVisible() then
                     RaidMaker_MainForm:Hide()
                  else
                     RaidMaker_MainForm:Show()
                  end
               end)

   raidMakerLaunchCalEditButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("show RaidMaker gui. Same as /rm toggle")
                  GameTooltip:Show()
               end)
   raidMakerLaunchCalEditButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
   raidMakerLaunchCalEditButton:SetText("RM")
   
   
   -- create the button for the Raid Viewer screen
   raidMakerLaunchCalViewButton = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
   raidMakerLaunchCalViewButton:SetHeight(20)

   raidMakerLaunchCalViewButton:RegisterForClicks("LeftButtonUp")
   raidMakerLaunchCalViewButton:SetScript("OnClick",
               function(self, button, down)

                  if RaidMaker_MainForm:IsVisible() then
                     RaidMaker_MainForm:Hide()
                  else
                     RaidMaker_MainForm:Show()
                  end
               end)

   raidMakerLaunchCalViewButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("show RaidMaker gui. Same as /rm toggle")
                  GameTooltip:Show()
               end)
   raidMakerLaunchCalViewButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
   raidMakerLaunchCalViewButton:SetText("RM")
   -- must wait for the CALENDAR_OPEN_EVENT event to complete the initialization.
   
   
   --
   -- Set up FontString fields from the Roll Log area
   --
   
   RaidMaker_LogTab_Rolls_FieldPlayerNames = {}
   RaidMaker_LogTab_Rolls_FieldRollValues = {}
   RaidMaker_LogTab_Rolls_FieldRollAges = {}
   for index=1,11 do
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Rolls_FieldNamesField"..index-1, "ARTWORK", "GameFontNormalSmall" )
      item:SetWidth(100);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetPoint("TOPLEFT", RaidMaker_GroupRollFrame, "TOPLEFT", 5,-5);
         item:SetText("Player");
      else
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Rolls_FieldPlayerNames[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_LogTab_Rolls_FieldPlayerNames[index] = item;
   end
   for index=1,11 do
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Rolls_RollValue"..index-1, "ARTWORK", "GameFontNormalSmall" )
      item:SetWidth(100);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Rolls_FieldPlayerNames[1], "TOPRIGHT", 0,0);
         item:SetText("Roll Value");
      else
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Rolls_FieldRollValues[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_LogTab_Rolls_FieldRollValues[index] = item;
   end
   for index=1,11 do
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Rolls_RollAges"..index-1, "ARTWORK", "GameFontNormalSmall" )
      item:SetWidth(100);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Rolls_FieldRollValues[1], "TOPRIGHT", 0,0);
         item:SetText("Roll Age");
      else
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Rolls_FieldRollAges[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_LogTab_Rolls_FieldRollAges[index] = item;
   end
   
   --
   -- Set up text fields from the Loot Log area
   --
   RaidMaker_LogTab_Loot_FieldNames = {}
   RaidMaker_LogTab_Loot_FieldRollValues = {}
   RaidMaker_LogTab_Loot_FieldRollAges = {}
   RaidMaker_LogTab_Loot_FieldItemLink = {}
   for index=1,11 do
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Loot_FieldNamesField"..index-1, "ARTWORK", "GameFontNormalSmall" )
      item:SetWidth(100);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetPoint("TOPLEFT", RaidMaker_GroupLootFrame, "TOPLEFT", 5,-5);
         item:SetText("Player");
      else
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldNames[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_LogTab_Loot_FieldNames[index] = item;
   end
   for index=1,11 do
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Loot_ItemLink"..index-1, "ARTWORK", "GameFontNormalSmall" )
      item:SetWidth(200);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldNames[1], "TOPRIGHT", 0,0);
         item:SetText("Item Name");
      else
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldItemLink[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_LogTab_Loot_FieldItemLink[index] = item;
   end
   for index=1,11 do
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Loot_RollValue"..index-1, "ARTWORK", "GameFontNormalSmall" )
      item:SetWidth(100);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldItemLink[1], "TOPRIGHT", 0,0);
         item:SetText("Roll Value");
      else
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldRollValues[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_LogTab_Loot_FieldRollValues[index] = item;
   end
   for index=1,11 do
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Loot_RollAges"..index-1, "ARTWORK", "GameFontNormalSmall" )
      item:SetWidth(100);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldRollValues[1], "TOPRIGHT", 0,0);
         item:SetText("Roll Age");
      else
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldRollAges[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_LogTab_Loot_FieldRollAges[index] = item;
   end




end

