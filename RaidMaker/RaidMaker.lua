-- ****************************************************
-- * DECLARE VARIABLES *
-- ****************************************************
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
local raidSetupArmedFlag = false;
local pendingInvitesReadyArmedFlag = false;
local isRoleUpdateArmed = false;
local numMembersToPromoteToAssist = 0;
local numMembersWithRoles = 0;
local guildRankAssistThreshold = 3;  -- 0=Guild Master. 1=Officer; 2=Lieutenant; etc...  Controls if officers get assist.
                                     -- set to 0 for no promote. 1 for GM only, 2 for Officers, GM, etc
local raidMakerLaunchCalEditButton
local raidMakerLaunchCalViewButton
RaidMaker_lootLogData = {};
RaidMaker_RaidParticipantLog = {};
--RaidMaker_GuildRoster = {}
local RaidMaker_testTrialNum = 1;
local RaidMaker_RollLog = {};
local RaidMaker_sortedRollList = {};
local RaidMaker_sortRollAlgorithm_id = 1;   -- 1=sort by roll value; 2=sort by time; 3=sort by playername
local RaidMaker_highestRoll = 0;
local RaidMaker_menu_playerName = "";
local RaidMaker_appInstanceId = random(1,9999);
local RaidMaker_msgSequenceNumber = random(1,9999);
local RaidMaker_appMessagePrefix = "DbtRm";
local RaidMaker_appSyncPrefix = "DbtRs";
local RaidMaker_sync_enabled;
local previousGuildRosterUpdateTime = 0
local RaidMaker_syncIndexToNameTable = {};
local RaidMaker_syncProtocolVersion = 4
local RaidMaker_RaidPlannerList = {}
local RaidMaker_RaidPlannerListDisplayActive = 0;
local RaidMaker_GroupNumber_ButtonObject;
local RaidMaker_GroupNumber_FontStringObject;
local RaidMaker_currentGroupNumber = 1;
local RaidMaker_LogTab_Loot_PlayerNameButtonObject;
local RaidMaker_LogTab_Loot_RollValueButtonObject;
local RaidMaker_LogTab_Loot_RollAgeButtonObject;
local RaidMaker_lootLogSortList = {};

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

local CALENDAR_FULLDATE_MONTH_NAMES = {
	FULLDATE_MONTH_JANUARY,
	FULLDATE_MONTH_FEBRUARY,
	FULLDATE_MONTH_MARCH,
	FULLDATE_MONTH_APRIL,
	FULLDATE_MONTH_MAY,
	FULLDATE_MONTH_JUNE,
	FULLDATE_MONTH_JULY,
	FULLDATE_MONTH_AUGUST,
	FULLDATE_MONTH_SEPTEMBER,
	FULLDATE_MONTH_OCTOBER,
	FULLDATE_MONTH_NOVEMBER,
	FULLDATE_MONTH_DECEMBER,
};

local CALENDAR_WEEKDAY_NAMES = {
	WEEKDAY_SUNDAY,
	WEEKDAY_MONDAY,
	WEEKDAY_TUESDAY,
	WEEKDAY_WEDNESDAY,
	WEEKDAY_THURSDAY,
	WEEKDAY_FRIDAY,
	WEEKDAY_SATURDAY,
};


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
--      DEFAULT_CHAT_FRAME:AddMessage("RaidMaker Loaded.");
   end
--   UIErrorsFrame:AddMessage("RaidMaker Loaded.", 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME);

   SlashCmdList["RAIDMAKERCOMMAND"] = RaidMaker_Handler;
   SlashCmdList["RAIDMAKERMAINCOMMAND"] = RaidMaker_Handler;
   SLASH_RAIDMAKERCOMMAND1 = "/at";
   SLASH_RAIDMAKERMAINCOMMAND1 = "/rm";

   RaidMaker_InitLootSortList();

   RaidMaker_SetUpGuiFields();

   RaidMaker_DisplayLootDatabase();
   
   RaidMaker_UpdateOldLootLogs();
   
   RaidMaker_SetUpSync();
   
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
   elseif (msg == "atlog") then
      RaidMaker_UpdatePlayerAttendanceLog();
   elseif (msg == "hide") then
      RaidMaker_MainForm:Hide();
   elseif (msg == "center") then
      RaidMaker_MainForm:ClearAllPoints()
      RaidMaker_MainForm:SetPoint("CENTER", UIParent, "CENTER",0,0)
--   elseif (msg == "getroster") then
--      local index;
--      local name,rank,rankIndex,level,class,zone,note,officernote,online,status,classFileName;
--      local numGuildMembers = GetNumGuildMembers(true); --includeOffline
--
--      for index=1,numGuildMembers do
--         local tempLine = ""
--
--         name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(index);
--
--         tempLine = name
--         tempLine = tempLine.."::"..rank
--         tempLine = tempLine.."::"..rankIndex
--         tempLine = tempLine.."::"..level
--         tempLine = tempLine.."::"..class
----         tempLine = tempLine.."::"..zone
--         tempLine = tempLine.."::"..note
--         tempLine = tempLine.."::"..officernote
----         tempLine = tempLine.."::"..online
----         tempLine = tempLine.."::"..status
--         tempLine = tempLine.."::"..classFileName
--         RaidMaker_GuildRoster[index] = tempLine;
--      end
--   elseif (msg == "guildinfo") then
--      local index;
--      local numRanks = GuildControlGetNumRanks();
--
--      for index=1,numRanks do
--         print(index.." "..GuildControlGetRankName(index) )
--      end
   elseif (msg == "text") then
      -- for testing purposes. can be deleted.
      RaidMaker_TabPage1_SampleTextTab1_GroupedState_1:SetText(red.."not");
      RaidMaker_TabPage1_SampleTextTab1_OnlineState_1:SetText(green.."online");
      RaidMaker_TabPage1_SampleTextTab1_InviteStatus_1:SetText(green.."Accepted");
      RaidMaker_TabPage1_SampleTextTab1_PlayerName_1:SetText(white.."Cellifalas");
--      RaidMaker_TabPage1_SampleTextTab1_PlayerName_1:SetText("|cffa335ee|Hitem:47813:0:0:0:0:0:0:640536288:80|h[Helmet of the Crypt Lord]|h|r");
      RaidMaker_TabPage1_SampleTextTab1_TankButton_1:SetText(yellow.."X");
      RaidMaker_TabPage1_SampleTextTab1_HealButton_1:SetText(yellow.."X");
      RaidMaker_TabPage1_SampleTextTab1_mDpsButton_1:SetText(yellow.."X");
      RaidMaker_TabPage1_SampleTextTab1_rDpsButton_1:SetText(yellow.."X");
      RaidMaker_TabPage1_SampleTextTab1_Class_1:SetText(yellow.."DRUID");

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
   elseif (msg == "test") then
      local tempPlayerName;
      local tempOnlineText;

      tempPlayerName = "Artera";
      tempOnlineText = RaidMaker_GetOnlineStatusText(tempPlayerName);
      print(white..tempPlayerName.." is "..tempOnlineText);

      tempPlayerName = "Sanydrewstg";
      tempOnlineText = RaidMaker_GetOnlineStatusText(tempPlayerName);
      print(white..tempPlayerName.." is "..tempOnlineText);

      tempPlayerName = "Tyrlidd";
      tempOnlineText = RaidMaker_GetOnlineStatusText(tempPlayerName);
      print(white..tempPlayerName.." is "..tempOnlineText);

      tempPlayerName = "Cherdrion";
      tempOnlineText = RaidMaker_GetOnlineStatusText(tempPlayerName);
      print(white..tempPlayerName.." is "..tempOnlineText);

      tempPlayerName = "Falfurien";
      tempOnlineText = RaidMaker_GetOnlineStatusText(tempPlayerName);
      print(white..tempPlayerName.." is "..tempOnlineText);



   elseif ( msg ~= nil ) then
      local tempOnlineText = RaidMaker_GetOnlineStatusText(msg);
      print(tempOnlineText);
   else
      print(green.."RaidMaker:"..white.." Arguments to "..yellow.."/rm");
      print(yellow.." show - "..white.."Shows the main window.");
      print(yellow.." hide - "..white.."Hides the main window.");
      print(yellow.." toggle - "..white.."Toggles the main window.");
      print(yellow.." center - "..white.."Centers the main window.");
      print(yellow.." cal - "..white.."Fetches the most recently opened Calendar Event.");
      print(yellow.." atlog - "..white.."Manually record log of online player zones.");
   end



end

function RaidMaker_SetUpSync()
   local result = true;
   
   result = RegisterAddonMessagePrefix(RaidMaker_appSyncPrefix)
   if ( result == false ) then
      print(red.."RaidMaker Error:"..white.." unable to register Sync Init prefix.");
   end

   result = RegisterAddonMessagePrefix(RaidMaker_appMessagePrefix)  
   if ( result == false ) then
      print(red.."RaidMaker Error:"..white.." unable to register Sync Normal prefix.");
   end
end

function RaidMaker_UpdateOldLootLogs()
   local index; 
   
   if ( RaidMaker_lootLogData ~= nil ) then
   
      for index=1,#RaidMaker_lootLogData do        -- loop through each historical log entry.
         
         if ( RaidMaker_lootLogData[index].itemName == nil ) then
            -- we have an old entry from when the name extraction was broken.  lets fix it.
            RaidMaker_lootLogData[index].AggregateLootInfo = nil; -- clear out the aggregate log.  it will be fixed right after this.
            
            local startIndex1,endIndex1,itemNameText = strfind(RaidMaker_lootLogData[index].itemLink, "%[(.*)%]");
            RaidMaker_lootLogData[index].itemName = itemNameText;
         end

         if ( RaidMaker_lootLogData[index] ~= nil ) and
            ( RaidMaker_lootLogData[index].AggregateLootInfo   == nil ) and
            ( RaidMaker_lootLogData[index].itemName   ~= nil ) and
            ( RaidMaker_lootLogData[index].epocTime   ~= nil ) and
            ( RaidMaker_lootLogData[index].playerName ~= nil ) and
            ( RaidMaker_lootLogData[index].rollValue  ~= nil ) and
            ( RaidMaker_lootLogData[index].itemLink   ~= nil ) and
            ( RaidMaker_lootLogData[index].itemId     ~= nil ) then
            
            -- append each field in a super field.  Use "^" as the separator
            RaidMaker_lootLogData[index].AggregateLootInfo = RaidMaker_lootLogData[index].itemName  .."^" ..
                                                             RaidMaker_lootLogData[index].epocTime  .."^" ..
                                                             RaidMaker_lootLogData[index].playerName.."^" ..
                                                             RaidMaker_lootLogData[index].rollValue .."^" ..
                                                             RaidMaker_lootLogData[index].itemId    .."^" ..
                                                             RaidMaker_lootLogData[index].itemLink     ;
         end      
      end
   end
end


function RaidMaker_repeatLoggedRaid(historyIndex)

   if ( raidPlayerDatabase ~= nil ) then -- only process if there is a database to parse.
      if ( raidPlayerDatabase.playerInfo ~= nil ) then
         if ( historyIndex <= #RaidMaker_RaidParticipantLog) then

            -- clear out our roles.
            RaidMaker_ClearAllRolesWithSync();


            local menuPlayerNameInfo
            for charName, menuPlayerNameInfo in pairs(RaidMaker_RaidParticipantLog[historyIndex].playerInfo) do
               if ( menuPlayerNameInfo.tank == 1 ) or
                  ( menuPlayerNameInfo.heals == 1 ) or
                  ( menuPlayerNameInfo.mDps == 1 ) or
                  ( menuPlayerNameInfo.rDps == 1 ) then

                  if ( raidPlayerDatabase.playerInfo[charName] ~= nil ) then
                     if ( menuPlayerNameInfo.tank == 1 ) then
                        raidPlayerDatabase.playerInfo[charName].tank = 1;
                        raidPlayerDatabase.playerInfo[charName].groupNum = RaidMaker_currentGroupNumber;
                        RaidMaker_sendUpdateToRemoteApps(charName, "T");
                     end
                     if ( menuPlayerNameInfo.heals == 1 ) then
                        raidPlayerDatabase.playerInfo[charName].heals = 1;
                        raidPlayerDatabase.playerInfo[charName].groupNum = RaidMaker_currentGroupNumber;
                        RaidMaker_sendUpdateToRemoteApps(charName, "H");
                     end
                     if ( menuPlayerNameInfo.mDps == 1 ) then
                        raidPlayerDatabase.playerInfo[charName].mDps = 1;
                        raidPlayerDatabase.playerInfo[charName].groupNum = RaidMaker_currentGroupNumber;
                        RaidMaker_sendUpdateToRemoteApps(charName, "M");
                     end
                     if ( menuPlayerNameInfo.rDps == 1 ) then
                        raidPlayerDatabase.playerInfo[charName].rDps = 1;
                        raidPlayerDatabase.playerInfo[charName].groupNum = RaidMaker_currentGroupNumber;
                        RaidMaker_sendUpdateToRemoteApps(charName, "R");
                     end


                  end
               end
            end

            RaidMaker_DisplayDatabase();

         end
      end
   end
end


function RaidMaker_buildRaidList(origDatabase)
   -- start a new database from scratch
   local newRaidDatabase = {};
   local copyRaidPlayerSettings = false;
   raidSetupArmedFlag = false;
   numMembersToPromoteToAssist = 0;

   -- get the raid title
   local title, description, creator, eventType, repeatOption, maxSize, textureIndex, weekday, month, day, year, hour, minute, lockoutWeekday, lockoutMonth, lockoutDay, lockoutYear, lockoutHour, lockoutMinute, locked, autoApprove, pendingInvite, inviteStatus, inviteType, calendarType = CalendarGetEventInfo();

   if ( title ~= nil ) then

      newRaidDatabase.month  = month;
      newRaidDatabase.day    = day;
      newRaidDatabase.year   = year;
      newRaidDatabase.hour   = hour;
      newRaidDatabase.minute = minute;
      newRaidDatabase.textureIndex = textureIndex;

      newRaidDatabase.title = title;

      if ( eventType == 1 ) or ( eventType == 2 ) then -- 1=Raid dungeon; 2=Five-player dungeon
         local raidName, icon, expansion, players= select(1+4*(textureIndex-1), CalendarEventGetTextures(eventType));
         newRaidDatabase.title = newRaidDatabase.title.." - "..raidName.."("..players..")";
      end

      if ( origDatabase ~= nil ) then
         if ( newRaidDatabase.title  == origDatabase.title  ) and
            ( newRaidDatabase.month  == origDatabase.month  ) and
            ( newRaidDatabase.day    == origDatabase.day    ) and
            ( newRaidDatabase.year   == origDatabase.year   ) and
            ( newRaidDatabase.hour   == origDatabase.hour   ) and
            ( newRaidDatabase.minute == origDatabase.minute ) then
            -- the raid settings of the newly opened calendar match the current one. we should copy the role selections and online status.
            copyRaidPlayerSettings = true;
         end
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
      RaidMaker_syncIndexToNameTable = {}; -- clear out the sorting table.

      local index;
      local name, level, className, classFileName, inviteStatus, modStatus, inviteIsMine, inviteType;
      for index=1,numInvites do
         name, level, className, classFileName, inviteStatus, modStatus, inviteIsMine, inviteType = CalendarEventGetInvite(index);

         newRaidDatabase.playerInfo[name] = {}; -- create empty fields
         newRaidDatabase.playerInfo[name].inviteStatus = inviteStatus; -- INVITED = 1;ACCEPTED = 2;DECLINED = 3;CONFIRMED = 4;OUT = 5;STANDBY = 6;SIGNEDUP = 7;NOT_SIGNEDUP = 8;TENTATIVE = 9
         newRaidDatabase.playerInfo[name].classFilename = classFileName; -- "WARRIOR", "PRIEST", etc

         newRaidDatabase.playerInfo[name].tank = 0;
         newRaidDatabase.playerInfo[name].heals = 0;
         newRaidDatabase.playerInfo[name].mDps = 0;
         newRaidDatabase.playerInfo[name].rDps = 0;
         newRaidDatabase.playerInfo[name].online = "";
         newRaidDatabase.playerInfo[name].syncIndex = 0;
         newRaidDatabase.playerInfo[name].inGroup = 0;
         newRaidDatabase.playerInfo[name].guildRankIndex = 100; -- big number. means uninitialized
         newRaidDatabase.playerInfo[name].partyInviteDeferred = 0; -- no party invite queued at this point.
         newRaidDatabase.playerInfo[name].groupNum = 255;

         local su_weekday, su_month, su_day, su_year, su_hour, su_minute = CalendarEventGetInviteResponseTime(index);
         newRaidDatabase.playerInfo[name].signupInfo = {};

         newRaidDatabase.playerInfo[name].signupInfo.weekday = su_weekday;
         newRaidDatabase.playerInfo[name].signupInfo.month   = su_month  ;
         newRaidDatabase.playerInfo[name].signupInfo.day     = su_day    ;
         newRaidDatabase.playerInfo[name].signupInfo.year    = su_year   ;
         newRaidDatabase.playerInfo[name].signupInfo.hour    = su_hour   ;
         newRaidDatabase.playerInfo[name].signupInfo.minute  = su_minute ;
         -- NOTE. if any fields are added and initialized here, add them to guild roster update area too.
         

         if ( copyRaidPlayerSettings == true ) then
            -- its the same calendar. copy the fields from the old one
            if ( origDatabase.playerInfo[name] ~= nil ) then
               newRaidDatabase.playerInfo[name].tank     = origDatabase.playerInfo[name].tank ;
               newRaidDatabase.playerInfo[name].heals    = origDatabase.playerInfo[name].heals;
               newRaidDatabase.playerInfo[name].mDps     = origDatabase.playerInfo[name].mDps ;
               newRaidDatabase.playerInfo[name].rDps     = origDatabase.playerInfo[name].rDps ;
               newRaidDatabase.playerInfo[name].online   = origDatabase.playerInfo[name].online;
               newRaidDatabase.playerInfo[name].groupNum = origDatabase.playerInfo[name].groupNum;
            end
         end

         if ( GetNumRaidMembers() == 0 ) then
            if (UnitInParty(name) ) then
               newRaidDatabase.playerInfo[name].inGroup = 1;
            end
         else
            if (UnitInRaid(name) ) then
               newRaidDatabase.playerInfo[name].inGroup = 1;
            end
         end

         RaidMaker_syncIndexToNameTable[index] = name; -- build up the list of names. will be sorted later.
      end

      -- set up ourself as dps as a default.
      local selfName = GetUnitName("player",true);
      if ( newRaidDatabase.playerInfo[selfName] ~= nil ) then
         newRaidDatabase.playerInfo[selfName].rDps = 1;
         newRaidDatabase.playerInfo[selfName].groupNum = RaidMaker_currentGroupNumber;
      end

      --
      -- build up sync list (alphabetical sorted list of names)
      --
      table.sort(RaidMaker_syncIndexToNameTable);  -- default sort is ascending alphabetical
      for index=1,numInvites do
         local tempName = RaidMaker_syncIndexToNameTable[index];
         if ( newRaidDatabase.playerInfo[tempName] ~= nil ) then -- need this check in case non-guildie invited
            newRaidDatabase.playerInfo[tempName].syncIndex = index;
         end
      end

      GuildRoster(); -- trigger a GUILD_ROSTER_UPDATE event so we can get the online/offline status of players.

      RaidMaker_GuildRosterUpdate(); -- try to querry database

   else
      print(red.."RaidMaker error: "..white.."Must open an event through the Calendar first.");
   end

   local selfName = GetUnitName("player",true);
   RaidMaker_RaidPlannerList = {};  -- clear out the planner participant list.
   RaidMaker_updateRaidPlannerList_seen(selfName)
   RaidMaker_updateRaidPlannerList_active(selfName)

   return newRaidDatabase;
end

function RaidMaker_GuildRosterUpdate(flag)
   -- timestamp the update.
   previousGuildRosterUpdateTime = time();
   local raidDatabaseResortNeeded = 0;
   guildRosterInformation = {}

   if ( raidPlayerDatabase ~= nil ) then -- only process if there is a database to parse.
      if ( raidPlayerDatabase.playerInfo ~= nil ) then

         local name,rank,rankIndex,level,class,zone,note,officernote,online,status,classFileName;
         local numGuildMembers = GetNumGuildMembers(true); --includeOffline

         for index=1,numGuildMembers do
            name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(index);

            if ( raidPlayerDatabase.playerInfo[name] == nil ) then
               raidPlayerDatabase.playerInfo[name] = {}; -- create empty fields
               raidPlayerDatabase.playerInfo[name].inviteStatus = 8; -- INVITED = 1;ACCEPTED = 2;DECLINED = 3;CONFIRMED = 4;OUT = 5;STANDBY = 6;SIGNEDUP = 7;NOT_SIGNEDUP = 8;TENTATIVE = 9
               raidPlayerDatabase.playerInfo[name].classFilename = classFileName; -- "WARRIOR", "PRIEST", etc

               raidPlayerDatabase.playerInfo[name].tank = 0;
               raidPlayerDatabase.playerInfo[name].heals = 0;
               raidPlayerDatabase.playerInfo[name].mDps = 0;
               raidPlayerDatabase.playerInfo[name].rDps = 0;
               raidPlayerDatabase.playerInfo[name].online = "";
               raidPlayerDatabase.playerInfo[name].syncIndex = 0;
               raidPlayerDatabase.playerInfo[name].inGroup = 0;
               raidPlayerDatabase.playerInfo[name].guildRankIndex = 100; -- big number. means uninitialized
               raidPlayerDatabase.playerInfo[name].partyInviteDeferred = 0; -- no party invite queued at this point.
               raidPlayerDatabase.playerInfo[name].groupNum = 255;
      
               raidPlayerDatabase.playerInfo[name].signupInfo = {};      
               raidPlayerDatabase.playerInfo[name].signupInfo.weekday = 1;
               raidPlayerDatabase.playerInfo[name].signupInfo.month   = 1  ;
               raidPlayerDatabase.playerInfo[name].signupInfo.day     = 1    ;
               raidPlayerDatabase.playerInfo[name].signupInfo.year    = 3000   ;
               raidPlayerDatabase.playerInfo[name].signupInfo.hour    = 1   ;
               raidPlayerDatabase.playerInfo[name].signupInfo.minute  = 1 ;
               -- NOTE. if any fields are added and initialized here, add them to guild roster update area too.

               ---xxx
               
               raidDatabaseResortNeeded = 1;
            end

            -- build guild roster database so we can look up main chars
            local startIndex,endIndex,nameOfMainChar;
            if ( note ~= nil ) then
               startIndex,endIndex,nameOfMainChar = strfind(note, "%((.*)%)" );
            end
            guildRosterInformation[name] = {}
            guildRosterInformation[name].rankIndex = rankIndex
            if ( online == 1 ) then
               guildRosterInformation[name].online = 1;
            else
               guildRosterInformation[name].online = 0;
            end
            guildRosterInformation[name].nameOfMainChar = nameOfMainChar

            -- update the raid database with this guild member information
            if ( raidPlayerDatabase.playerInfo[name] ~= nil ) then
               raidPlayerDatabase.playerInfo[name].zone           = zone;
               raidPlayerDatabase.playerInfo[name].guildRankIndex = rankIndex;
            end            
         end
         
         -- resort the display order if we added any members.
         if (raidDatabaseResortNeeded == 1) then
            if ( raidPlayerDatabase.title ~= nil ) then
               playerSortedList = RaidMaker_buildPlayerListSort(raidPlayerDatabase);
               table.sort(playerSortedList, RaidMaker_ascendInviteStatusOrder);
            end
         end

         --
         -- build up sync list (alphabetical sorted list of names combined from calendar and guild roster)
         --
         RaidMaker_syncIndexToNameTable = RaidMaker_buildPlayerListSort(raidPlayerDatabase);
         table.sort(RaidMaker_syncIndexToNameTable);  -- default sort is ascending alphabetical
         local playerIndex,tempName;
         for playerSyncIndex,tempName in pairs(RaidMaker_syncIndexToNameTable) do
            if ( tempName ~= nil) then
               if ( raidPlayerDatabase.playerInfo[tempName] ~= nil ) then -- need this check in case non-guildie invited
                  raidPlayerDatabase.playerInfo[tempName].syncIndex = playerSyncIndex;
               end
            end
         end

         -- make pass through roster updating alt information and officer information.
         local charName,charFields;
         for charName,charFields in pairs(guildRosterInformation) do
            if ( guildRosterInformation[charName] ~= nil ) then -- make sure the player is in the guild
               local nameOfMainChar = guildRosterInformation[charName].nameOfMainChar

               if ( nameOfMainChar ~= nil ) then -- make sure the char has a main.
                  if ( guildRosterInformation[nameOfMainChar] ~= nil ) then -- make sure the main is in the guild (might be some other text)

                     -- Update the rank field to be that of the main
                     if ( guildRosterInformation[nameOfMainChar].rankIndex ~= nil ) and
                        ( raidPlayerDatabase.playerInfo[charName] ~= nil ) and
                        ( raidPlayerDatabase.playerInfo[charName].guildRankIndex ~= nil ) then
                        if ( guildRosterInformation[nameOfMainChar].rankIndex < raidPlayerDatabase.playerInfo[charName].guildRankIndex ) then
                           -- update the database with the main's rank.
                           raidPlayerDatabase.playerInfo[charName].guildRankIndex = guildRosterInformation[nameOfMainChar].rankIndex;
                        end
                     end

                     -- Add the alt to the alt-list of the main.
                     if ( guildRosterInformation[nameOfMainChar].nameOfAlts == nil ) then
                        guildRosterInformation[nameOfMainChar].nameOfAlts = {}; -- guarantee that we have a structure to place our field
                     end
                     guildRosterInformation[nameOfMainChar].nameOfAlts[charName] = true;

                  end
               end
            end
         end

         -- update online status text.
         for charName,charFields in pairs(raidPlayerDatabase.playerInfo) do
            raidPlayerDatabase.playerInfo[charName].online = RaidMaker_GetOnlineStatusText(charName);
         end

         -- refresh screen
         RaidMaker_DisplayDatabase();

      end

   end

end

function RaidMaker_GetOnlineStatusText(player)

--( raidPlayerDatabase ~= nil ) and
--      ( raidPlayerDatabase.playerInfo ~= nil ) and
--      ( raidPlayerDatabase.playerInfo[player] ~= nil ) and
--

   if ( guildRosterInformation ~= nil ) and
      ( guildRosterInformation[player] ~= nil ) then
      -- check if player to be checked is online (GREEN)
      if ( guildRosterInformation[player].online == 1 ) then
         return green.."online";
      end

      -- check if player to be checked is on main (yellow)
      local nameOfMainChar = guildRosterInformation[player].nameOfMainChar
      if ( nameOfMainChar ~= nil ) then -- make sure the char has a main.
         if ( guildRosterInformation[nameOfMainChar] ~= nil ) then -- make sure the main is in the guild (might be some other text)
            if ( guildRosterInformation[nameOfMainChar].online == 1 ) then
               return yellow.."on "..nameOfMainChar;
            end
         end
      end

      -- check if player to be checked is alt logged in on alt (yellow)
      if ( guildRosterInformation[player] ~= nil ) then -- make sure the main is in the guild (might be some other text)
         if ( guildRosterInformation[player].nameOfAlts ~= nil ) then
            local altName,charFields;
            for altName,charFields in pairs(guildRosterInformation[player].nameOfAlts) do
               if ( guildRosterInformation[altName].online == 1 ) then
                  return yellow.."on "..altName;
               end
            end
         end
      end

      -- check if player to be checked is alt logged in on alt (yellow)
      local nameOfMainChar = guildRosterInformation[player].nameOfMainChar
      if ( nameOfMainChar ~= nil ) then -- make sure the char has a main.
         if ( guildRosterInformation[nameOfMainChar] ~= nil ) then -- make sure the main is in the guild (might be some other text)

            if ( guildRosterInformation[nameOfMainChar].nameOfAlts ~= nil ) then
               local altName,charFields;
               for altName,charFields in pairs(guildRosterInformation[nameOfMainChar].nameOfAlts) do
                  if ( guildRosterInformation[altName].online == 1 ) then
                     return yellow.."on "..altName;
                  end
               end
            end
         end
      end
   end

   return mediumGrey.."offline";
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
   local mDpsCountForRaid = 0;
   local rDpsCountForRaid = 0;
   local playerCountForRaid = 0;

   for className,colorValue in pairs(RAID_CLASS_COLORS) do
      raidPlayerDatabase.classCount[className] = 0;
   end

   for rowIndex=1,#playerSortedList do
      charName = playerSortedList[rowIndex];

      if ( raidPlayerDatabase.playerInfo[charName].groupNum == RaidMaker_currentGroupNumber ) then -- only consider ones in our group.

         if ( raidPlayerDatabase.playerInfo[charName].tank == 1 ) or
            ( raidPlayerDatabase.playerInfo[charName].heals == 1 ) or
            ( raidPlayerDatabase.playerInfo[charName].mDps == 1 ) or
            ( raidPlayerDatabase.playerInfo[charName].rDps == 1) then
   
            if ( guildRosterInformation[charName] ~= nil ) and
               ( guildRosterInformation[charName].online == 1 ) then
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
   
         if ( raidPlayerDatabase.playerInfo[charName].mDps == 1 ) then
            mDpsCountForRaid  = mDpsCountForRaid + 1;
         end
   
         if ( raidPlayerDatabase.playerInfo[charName].rDps == 1 ) then
            rDpsCountForRaid  = rDpsCountForRaid + 1;
         end
   
         if ( raidPlayerDatabase.playerInfo[charName].inGroup == 1 ) then
            groupedCountForRaid  = groupedCountForRaid + 1;
         end
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
   RaidMaker_TabPage1_SampleTextTab1_TankButton_21:SetText(tankCountForRaid);
   RaidMaker_TabPage1_SampleTextTab1_HealButton_21:SetText(healCountForRaid);
   RaidMaker_TabPage1_SampleTextTab1_mDpsButton_21:SetText(mDpsCountForRaid);
   RaidMaker_TabPage1_SampleTextTab1_rDpsButton_21:SetText(rDpsCountForRaid);
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

   if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return true;
   elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] > inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].signupInfo.year < raidPlayerDatabase.playerInfo[b].signupInfo.year ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].signupInfo.year > raidPlayerDatabase.playerInfo[b].signupInfo.year ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].signupInfo.month < raidPlayerDatabase.playerInfo[b].signupInfo.month ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].signupInfo.month > raidPlayerDatabase.playerInfo[b].signupInfo.month ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].signupInfo.day < raidPlayerDatabase.playerInfo[b].signupInfo.day ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].signupInfo.day > raidPlayerDatabase.playerInfo[b].signupInfo.day ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].signupInfo.hour < raidPlayerDatabase.playerInfo[b].signupInfo.hour ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].signupInfo.hour > raidPlayerDatabase.playerInfo[b].signupInfo.hour ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].signupInfo.minute < raidPlayerDatabase.playerInfo[b].signupInfo.minute ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].signupInfo.minute > raidPlayerDatabase.playerInfo[b].signupInfo.minute ) then
      return false;
   end

   return a<b;
end

function RaidMaker_ascendTankOrder(a,b)
   -- a,b are player names.

   if ( raidPlayerDatabase.playerInfo[a].groupNum < raidPlayerDatabase.playerInfo[b].groupNum ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].groupNum > raidPlayerDatabase.playerInfo[b].groupNum ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].tank > raidPlayerDatabase.playerInfo[b].tank ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].tank < raidPlayerDatabase.playerInfo[b].tank ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].heals > raidPlayerDatabase.playerInfo[b].heals ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].heals < raidPlayerDatabase.playerInfo[b].heals ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].mDps > raidPlayerDatabase.playerInfo[b].mDps ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].mDps < raidPlayerDatabase.playerInfo[b].mDps ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].rDps > raidPlayerDatabase.playerInfo[b].rDps ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].rDps < raidPlayerDatabase.playerInfo[b].rDps ) then
      return false;
   end

   if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return true;
   elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] > inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return false;
   end

   return a<b;
end

function RaidMaker_ascendHealOrder(a,b)
   -- a,b are player names.

   if ( raidPlayerDatabase.playerInfo[a].groupNum < raidPlayerDatabase.playerInfo[b].groupNum ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].groupNum > raidPlayerDatabase.playerInfo[b].groupNum ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].heals > raidPlayerDatabase.playerInfo[b].heals ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].heals < raidPlayerDatabase.playerInfo[b].heals ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].tank > raidPlayerDatabase.playerInfo[b].tank ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].tank < raidPlayerDatabase.playerInfo[b].tank ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].mDps > raidPlayerDatabase.playerInfo[b].mDps ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].mDps < raidPlayerDatabase.playerInfo[b].mDps ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].rDps > raidPlayerDatabase.playerInfo[b].rDps ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].rDps < raidPlayerDatabase.playerInfo[b].rDps ) then
      return false;
   end

   if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return true;
   elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] > inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return false;
   end

   return a<b;
end

function RaidMaker_ascend_mDpsOrder(a,b)
   -- a,b are player names.

   if ( raidPlayerDatabase.playerInfo[a].groupNum < raidPlayerDatabase.playerInfo[b].groupNum ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].groupNum > raidPlayerDatabase.playerInfo[b].groupNum ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].mDps > raidPlayerDatabase.playerInfo[b].mDps ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].mDps < raidPlayerDatabase.playerInfo[b].mDps ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].rDps > raidPlayerDatabase.playerInfo[b].rDps ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].rDps < raidPlayerDatabase.playerInfo[b].rDps ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].tank > raidPlayerDatabase.playerInfo[b].tank ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].tank < raidPlayerDatabase.playerInfo[b].tank ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].heals > raidPlayerDatabase.playerInfo[b].heals ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].heals < raidPlayerDatabase.playerInfo[b].heals ) then
      return false;
   end

   if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return true;
   elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] > inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return false;
   end

   return a<b;
end

function RaidMaker_ascend_rDpsOrder(a,b)
   -- a,b are player names.

   if ( raidPlayerDatabase.playerInfo[a].groupNum < raidPlayerDatabase.playerInfo[b].groupNum ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].groupNum > raidPlayerDatabase.playerInfo[b].groupNum ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].rDps > raidPlayerDatabase.playerInfo[b].rDps ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].rDps < raidPlayerDatabase.playerInfo[b].rDps ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].mDps > raidPlayerDatabase.playerInfo[b].mDps ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].mDps < raidPlayerDatabase.playerInfo[b].mDps ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].tank > raidPlayerDatabase.playerInfo[b].tank ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].tank < raidPlayerDatabase.playerInfo[b].tank ) then
      return false;
   end

   if ( raidPlayerDatabase.playerInfo[a].heals > raidPlayerDatabase.playerInfo[b].heals ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].heals < raidPlayerDatabase.playerInfo[b].heals ) then
      return false;
   end

   if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return true;
   elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] > inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return false;
   end

   return a<b;
end

function RaidMaker_ascendClassOrder(a,b)
   -- a,b are player names.

   if ( raidPlayerDatabase.playerInfo[a].classFilename < raidPlayerDatabase.playerInfo[b].classFilename ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].classFilename > raidPlayerDatabase.playerInfo[b].classFilename ) then
      return false;
   end

   return a<b;
end

function RaidMaker_ascendPlayerNameOrder(a,b)
   -- a,b are player names.
   return a<b;
end

function RaidMaker_ascendOnlineStateOrder(a,b)
   -- a,b are player names.

--   if ( guildRosterInformation[a] ~= nil ) and
--      ( guildRosterInformation[b] ~= nil ) then
   local status_a = strsub(raidPlayerDatabase.playerInfo[a].online, 10 ); -- sort without the color information.
   local status_b = strsub(raidPlayerDatabase.playerInfo[b].online, 10 )

      if ( status_a > status_b ) then
         return true;
      elseif ( status_a < status_b ) then
         return false;
      end
--      if ( raidPlayerDatabase.playerInfo[a].online > raidPlayerDatabase.playerInfo[b].online ) then
--         return true;
--      elseif ( raidPlayerDatabase.playerInfo[a].online < raidPlayerDatabase.playerInfo[b].online ) then
--         return false;
--      end
--   end

   if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return true;
   elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] > inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return false;
   end

   return a<b;
end

function RaidMaker_ascendGroupedStateOrder(a,b)
   -- a,b are player names.

   if ( raidPlayerDatabase.playerInfo[a].inGroup > raidPlayerDatabase.playerInfo[b].inGroup ) then
      return true;
   elseif ( raidPlayerDatabase.playerInfo[a].inGroup < raidPlayerDatabase.playerInfo[b].inGroup ) then
      return false;
   end

   if ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] < inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return true;
   elseif ( inviteSortOrder[raidPlayerDatabase.playerInfo[a].inviteStatus] > inviteSortOrder[raidPlayerDatabase.playerInfo[b].inviteStatus] ) then
      return false;
   end

   return a<b;
end


function RaidMaker_LootLog_ascendRollValue(a,b)
   -- a,b are log index.

   if ( RaidMaker_lootLogData[a].rollValue < RaidMaker_lootLogData[b].rollValue ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].rollValue > RaidMaker_lootLogData[b].rollValue ) then
      return false;
   end

   if ( RaidMaker_lootLogData[a].epocTime < RaidMaker_lootLogData[b].epocTime ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].epocTime > RaidMaker_lootLogData[b].epocTime ) then
      return false;
   end

   if ( RaidMaker_lootLogData[a].playerName < RaidMaker_lootLogData[b].playerName ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].playerName > RaidMaker_lootLogData[b].playerName ) then
      return false;
   end

   if ( RaidMaker_lootLogData[a].itemName < RaidMaker_lootLogData[b].itemName ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].itemName > RaidMaker_lootLogData[b].itemName ) then
      return false;
   end

   return false;
end

function RaidMaker_LootLog_ascendRollTime(a,b)

   if ( RaidMaker_lootLogData[a].epocTime < RaidMaker_lootLogData[b].epocTime ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].epocTime > RaidMaker_lootLogData[b].epocTime ) then
      return false;
   end

   if ( RaidMaker_lootLogData[a].itemName < RaidMaker_lootLogData[b].itemName ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].itemName > RaidMaker_lootLogData[b].itemName ) then
      return false;
   end

   return false;

end



function RaidMaker_LootLog_ascendPlayerName(a,b)
   -- a,b are log index.

   if ( RaidMaker_lootLogData[a].playerName < RaidMaker_lootLogData[b].playerName ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].playerName > RaidMaker_lootLogData[b].playerName ) then
      return false;
   end

   if ( RaidMaker_lootLogData[a].itemName < RaidMaker_lootLogData[b].itemName ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].itemName > RaidMaker_lootLogData[b].itemName ) then
      return false;
   end

   if ( RaidMaker_lootLogData[a].epocTime < RaidMaker_lootLogData[b].epocTime ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].epocTime > RaidMaker_lootLogData[b].epocTime ) then
      return false;
   end

   if ( RaidMaker_lootLogData[a].rollValue < RaidMaker_lootLogData[b].rollValue ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].rollValue > RaidMaker_lootLogData[b].rollValue ) then
      return false;
   end

   return false;
end

function RaidMaker_LootLog_ascendItemName(a,b)
   -- a,b are log index.

   if ( RaidMaker_lootLogData[a].itemName < RaidMaker_lootLogData[b].itemName ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].itemName > RaidMaker_lootLogData[b].itemName ) then
      return false;
   end

   if ( RaidMaker_lootLogData[a].playerName < RaidMaker_lootLogData[b].playerName ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].playerName > RaidMaker_lootLogData[b].playerName ) then
      return false;
   end

   if ( RaidMaker_lootLogData[a].epocTime < RaidMaker_lootLogData[b].epocTime ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].epocTime > RaidMaker_lootLogData[b].epocTime ) then
      return false;
   end

   if ( RaidMaker_lootLogData[a].rollValue < RaidMaker_lootLogData[b].rollValue ) then
      return true;
   elseif ( RaidMaker_lootLogData[a].rollValue > RaidMaker_lootLogData[b].rollValue ) then
      return false;
   end

   return false;
end






function RaidMaker_OnMouseWheel(self, delta)
   local current = RaidMaker_VSlider:GetValue()

   if (delta<0) and (current<#playerSortedList-19) then
      RaidMaker_VSlider:SetValue(current+1)
   elseif (delta>0) and (current>1) then
      RaidMaker_VSlider:SetValue(current-1)
   end
end


function RaidMaker_OnMouseWheelRollLog(self, delta)
   local current = RaidMaker_RollLog_Slider:GetValue()

   if (delta<0) and (current<#RaidMaker_sortedRollList-9) then
      RaidMaker_RollLog_Slider:SetValue(current+1)
   elseif (delta>0) and (current>1) then
      RaidMaker_RollLog_Slider:SetValue(current-1)
   end
end

function RaidMaker_OnMouseWheelLootLog(self, delta)
   local current = RaidMaker_LootLog_Slider:GetValue()

   if (delta<0) and (current<#RaidMaker_lootLogData-9) then
      RaidMaker_LootLog_Slider:SetValue(current+1)
   elseif (delta>0) and (current>1) then
      RaidMaker_LootLog_Slider:SetValue(current-1)
   end
end


function RaidMaker_TextTableUpdate()

   local currentRow = 1;
   local charName;
   local startRow = RaidMaker_VSlider:GetValue();

   for rowIndex=startRow,#playerSortedList do
      charName = playerSortedList[rowIndex];

      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_GroupedState_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].inGroup == 0 ) then
         textBox:SetText(mediumGrey.."not");
      else
         textBox:SetText(green.."Raid");
      end

      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_OnlineState_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].online ~= nil ) then
         textBox:SetText(raidPlayerDatabase.playerInfo[charName].online);
      else
         textBox:SetText(mediumGrey.."offline");
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
         textBox:SetText(mediumGrey.."Not Signed Up");
      elseif ( raidPlayerDatabase.playerInfo[charName].inviteStatus == 9 ) then
         textBox:SetText(yellow.."Tentative");
      else
         textBox:SetText(darkGrey.."unknown");
      end

      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_PlayerName_"..currentRow);
      textBox:SetText(white..charName);

      local playerSelectionText = "X";
      if ( raidPlayerDatabase.playerInfo[charName].groupNum ~= nil ) and
         ( raidPlayerDatabase.playerInfo[charName].groupNum ~= RaidMaker_currentGroupNumber ) then
         playerSelectionText = raidPlayerDatabase.playerInfo[charName].groupNum;
      end

      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_TankButton_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].tank == 0 ) then
         textBox:SetText(" ");
      else
         textBox:SetText(yellow..playerSelectionText);
      end

      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_HealButton_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].heals == 0 ) then
         textBox:SetText(" ");
      else
         textBox:SetText(yellow..playerSelectionText);
      end

      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_mDpsButton_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].mDps == 0 ) then
         textBox:SetText(" ");
      else
         textBox:SetText(yellow..playerSelectionText);
      end

      local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_rDpsButton_"..currentRow);
      if ( raidPlayerDatabase.playerInfo[charName].rDps == 0 ) then
         textBox:SetText(" ");
      else
         textBox:SetText(yellow..playerSelectionText);
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

         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_TankButton_"..blankRowNum);
         textBox:SetText(" ");

         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_HealButton_"..blankRowNum);
         textBox:SetText(" ");

         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_mDpsButton_"..blankRowNum);
         textBox:SetText(" ");

         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_rDpsButton_"..blankRowNum);
         textBox:SetText(" ");

         local textBox = getglobal("RaidMaker_TabPage1_SampleTextTab1_Class_"..blankRowNum);
         textBox:SetText(" ");
      end
   end
end


function RaidMaker_updateGroupNumber(playerName)

--   if ( raidPlayerDatabase ~= nil ) and
--      ( raidPlayerDatabase.playerInfo ~= nil ) and
--      ( raidPlayerDatabase.playerInfo[player] ~= nil ) then
   
      if (raidPlayerDatabase.playerInfo[playerName].tank  == 1 ) or
         (raidPlayerDatabase.playerInfo[playerName].heals == 1 ) or
         (raidPlayerDatabase.playerInfo[playerName].mDps  == 1 ) or
         (raidPlayerDatabase.playerInfo[playerName].rDps  == 1 ) then
         raidPlayerDatabase.playerInfo[playerName].groupNum = RaidMaker_currentGroupNumber;
      else
         raidPlayerDatabase.playerInfo[playerName].groupNum = 255;
      end

--   end
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
            RaidMaker_updateGroupNumber(clickedCharName);
            RaidMaker_sendUpdateToRemoteApps(clickedCharName, "t");
         else
            raidPlayerDatabase.playerInfo[clickedCharName].tank = 1;
            RaidMaker_updateGroupNumber(clickedCharName);
            RaidMaker_sendUpdateToRemoteApps(clickedCharName, "T");
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
            RaidMaker_updateGroupNumber(clickedCharName);
            RaidMaker_sendUpdateToRemoteApps(clickedCharName, "h");
         else
            raidPlayerDatabase.playerInfo[clickedCharName].heals = 1;
            RaidMaker_updateGroupNumber(clickedCharName);
            RaidMaker_sendUpdateToRemoteApps(clickedCharName, "H");
         end

         RaidMaker_DisplayDatabase();
      end
   end
end
function RaidMaker_ClickHandler_mDpsFlag(clickedRow)
   if ( clickedRow == 0 ) then
      -- sort according to tank as primary.
      table.sort(playerSortedList, RaidMaker_ascend_mDpsOrder);
      RaidMaker_TextTableUpdate(RaidMaker_VSlider:GetValue());
   else
      local actualRow = clickedRow + RaidMaker_VSlider:GetValue()-1;
      if ( actualRow <= #playerSortedList ) then
         local clickedCharName = playerSortedList[actualRow];

         -- toggle the selection
         if ( raidPlayerDatabase.playerInfo[clickedCharName].mDps == 1 ) then
            raidPlayerDatabase.playerInfo[clickedCharName].mDps = 0;
            RaidMaker_updateGroupNumber(clickedCharName);
            RaidMaker_sendUpdateToRemoteApps(clickedCharName, "m");
         else
            raidPlayerDatabase.playerInfo[clickedCharName].mDps = 1;
            RaidMaker_updateGroupNumber(clickedCharName);
            RaidMaker_sendUpdateToRemoteApps(clickedCharName, "M");
         end

         RaidMaker_DisplayDatabase();
      end
   end
end
function RaidMaker_ClickHandler_rDpsFlag(clickedRow)
   if ( clickedRow == 0 ) then
      -- sort according to tank as primary.
      table.sort(playerSortedList, RaidMaker_ascend_rDpsOrder);
      RaidMaker_TextTableUpdate(RaidMaker_VSlider:GetValue());
   else
      local actualRow = clickedRow + RaidMaker_VSlider:GetValue()-1;
      if ( actualRow <= #playerSortedList ) then
         local clickedCharName = playerSortedList[actualRow];

         -- toggle the selection
         if ( raidPlayerDatabase.playerInfo[clickedCharName].rDps == 1 ) then
            raidPlayerDatabase.playerInfo[clickedCharName].rDps = 0;
            RaidMaker_updateGroupNumber(clickedCharName);
            RaidMaker_sendUpdateToRemoteApps(clickedCharName, "r");
         else
            raidPlayerDatabase.playerInfo[clickedCharName].rDps = 1;
            RaidMaker_updateGroupNumber(clickedCharName);
            RaidMaker_sendUpdateToRemoteApps(clickedCharName, "R");
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

function RaidMaker_LootLog_ClickHandler_PlayerName()
   table.sort(RaidMaker_lootLogSortList, RaidMaker_LootLog_ascendPlayerName);
   RaidMaker_DisplayLootDatabase();
end

function RaidMaker_LootLog_ClickHandler_ItemName()
   table.sort(RaidMaker_lootLogSortList, RaidMaker_LootLog_ascendItemName);
   RaidMaker_DisplayLootDatabase();
end

function RaidMaker_LootLog_ClickHandler_RollValue()
   table.sort(RaidMaker_lootLogSortList, RaidMaker_LootLog_ascendRollValue);
   RaidMaker_DisplayLootDatabase();
end

function RaidMaker_LootLog_ClickHandler_RollAge()
   table.sort(RaidMaker_lootLogSortList, RaidMaker_LootLog_ascendRollTime );
   RaidMaker_DisplayLootDatabase();
end

function RaidMaker_handle_CHAT_MSG_LOOT(message, sender, language, channelString, target, flags, unknown1, channelNumber, channelName, unknown2, counter)
   local startIndex,endIndex,playerName,itemLink

   --CHAT_MSG_LOOT
   --   You receive loot: [link].
   --   Flapjacckk receive loot: [link].

   -- Check if another player won something
   startIndex,endIndex,playerName,itemLink = strfind(message, "^(.*) receives loot: (.*)." );
   if (playerName == nil ) then

      -- wasnt someone else getting loot. check if it was us.
      startIndex,endIndex,itemLink = strfind(message, "You receive loot: (.*)." );
      if (itemLink ~= nil ) then
         playerName = GetUnitName("player",true);
      end
   end

   -- if someone won something, parse the details.
   if (playerName ~= nil ) then
      local startIndex,endIndex,itemID = strfind(itemLink, "(%d+):")
      local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemID);
      if ( quality == 4  ) then -- epic(purple)=4;  superior(blue)=3;  green=2; white=1; grey=0
         if ( GetNumRaidMembers() ~= 0 ) then -- only log it if we are in a raid. i.e. filter heroics
            if ( itemID ~= "49426" ) and  -- filter Emblem of Frost
               ( itemID ~= "22450" ) and -- filter Void Crystal
               ( itemID ~= "34057" ) and -- filter Abyss Crystal
               ( itemID ~= "52722" ) and -- filter Maelstrom Crystal
               ( itemID ~= "71998" ) then -- filter Essence of Destruction
               RaidMaker_addLootEntryToLootLog(playerName, itemID, itemLink);
            end
         end
      end
   end
end

function RaidMaker_addLootEntryToLootLog(playerName, itemId, itemLink)
   local loggedEntryIndex;
   local startIndex1,endIndex1,itemNameText = strfind(itemLink, "%[(.*)%]");

   loggedEntryIndex = #RaidMaker_lootLogData+1;
   RaidMaker_lootLogData[loggedEntryIndex] = {};  -- make it a structure so we can put some fields in.
   RaidMaker_lootLogData[loggedEntryIndex].itemLink = itemLink;
   RaidMaker_lootLogData[loggedEntryIndex].playerName = playerName;
   RaidMaker_lootLogData[loggedEntryIndex].epocTime = time();
   RaidMaker_lootLogData[loggedEntryIndex].itemId = tonumber( itemId );
   RaidMaker_lootLogData[loggedEntryIndex].itemName = itemNameText;
   RaidMaker_lootLogData[loggedEntryIndex].rollValue = 0;
--   RaidMaker_lootLogData[loggedEntryIndex].rollLog = RaidMaker_RollLog;
   -- append each field in a super field.  Use "^" as the separator
   RaidMaker_lootLogData[loggedEntryIndex].AggregateLootInfo = RaidMaker_lootLogData[loggedEntryIndex].itemName  .."^" ..
                                                               RaidMaker_lootLogData[loggedEntryIndex].epocTime  .."^" ..
                                                               RaidMaker_lootLogData[loggedEntryIndex].playerName.."^" ..
                                                               RaidMaker_lootLogData[loggedEntryIndex].rollValue .."^" ..
                                                               RaidMaker_lootLogData[loggedEntryIndex].itemId    .."^" ..
                                                               RaidMaker_lootLogData[loggedEntryIndex].itemLink     ;
   

   -- find the roll value if its in the list
   local index;
   for index = 1,#RaidMaker_RollLog do
      if ( playerName == RaidMaker_RollLog[index].playerName ) then
         RaidMaker_lootLogData[loggedEntryIndex].rollValue = tonumber(RaidMaker_RollLog[index].rollValue);
      end
   end


   if ( #RaidMaker_lootLogData <= 10 ) then
      RaidMaker_LootLog_Slider:SetMinMaxValues(#RaidMaker_lootLogData-9,#RaidMaker_lootLogData-9);
      RaidMaker_LootLog_Slider:SetValue(#RaidMaker_lootLogData-9);
   else
      RaidMaker_LootLog_Slider:SetMinMaxValues(1,#RaidMaker_lootLogData-9);
      RaidMaker_LootLog_Slider:SetValue(#RaidMaker_lootLogData-9);
   end
   
   RaidMaker_InitLootSortList(); -- resort the database according to the default sort criteria.
   table.sort(RaidMaker_lootLogSortList, RaidMaker_LootLog_ascendRollTime );

   RaidMaker_DisplayLootDatabase();
   RaidMaker_ResetRolls(0);
end

function RaidMaker_InitLootSortList()
   local index;
   for index = 1,#RaidMaker_lootLogData do
      RaidMaker_lootLogSortList[index] = index;
   end
end

function RaidMaker_DisplayLootDatabase()
   local timeDeltaSeconds;
   local indexToDisplay;
   local playerNameColor;
   local rollValueColor;
   local rollAgeColor;
   local currentTime = time();
   local index;
   local sortedTableInputIndex;

  
   if ( RaidMaker_lootLogData ~= nil ) then
      for index = 1,10 do
   --      indexToDisplay = index+RaidMaker_LootLog_Slider:GetValue()-1; -- eventually make this the sorted index starting at the scroll bar position.
         sortedTableInputIndex = index+RaidMaker_LootLog_Slider:GetValue()-1;
         if ( sortedTableInputIndex <= #RaidMaker_lootLogSortList ) then
            indexToDisplay = RaidMaker_lootLogSortList[sortedTableInputIndex]; 
         else
            indexToDisplay = 0; 
         end
   
         playerNameColor = white;
         rollValueColor = yellow;
         rollAgeColor = yellow;
   
         if ( indexToDisplay == nil ) or 
            ( indexToDisplay<1 ) or 
            ( #RaidMaker_lootLogData == 0 ) then
            RaidMaker_LogTab_Loot_FieldNames[index+1]:SetText(" ");
            RaidMaker_LogTab_Loot_FieldItemLinkButton[index+1]:SetText(" ");
            RaidMaker_LogTab_Loot_FieldRollValues[index+1]:SetText(" ");
            RaidMaker_LogTab_Loot_FieldRollAges[index+1]:SetText(" ");
         else
            timeDeltaSeconds = currentTime - RaidMaker_lootLogData[indexToDisplay].epocTime;
   
            if ( timeDeltaSeconds > 14400 ) then -- 4 hours = 4*60*60
               playerNameColor = mediumGrey;
               rollValueColor = mediumGrey;
               rollAgeColor = mediumGrey;
            end
   
            RaidMaker_LogTab_Loot_FieldNames[index+1]:SetText(playerNameColor..RaidMaker_lootLogData[indexToDisplay].playerName);
            RaidMaker_LogTab_Loot_FieldItemLinkButton[index+1]:SetText(RaidMaker_lootLogData[indexToDisplay].itemLink);
            RaidMaker_LogTab_Loot_FieldRollValues[index+1]:SetText(rollValueColor..RaidMaker_lootLogData[indexToDisplay].rollValue);
            RaidMaker_LogTab_Loot_FieldRollAges[index+1]:SetText(rollAgeColor.. RaidMaker_getAgeText(timeDeltaSeconds) );
         end
      end
   end
end

function RaidMaker_getAgeText(ageInSeconds)
   local returnText;

   if ( ageInSeconds < 3600 ) then
      -- age is less than one hour. display in mins.
      returnText = math.floor(ageInSeconds/60);
      returnText = returnText.." mins";
   elseif ( ageInSeconds < 86400 ) then
      -- age is less than one day. display in hours.
      returnText = math.floor(ageInSeconds/3600);
      returnText = returnText.." hours";
   else
      -- age is more than one day. display in days.
      returnText = math.floor(ageInSeconds/86400);
      returnText = returnText.." days";
   end

   return returnText;
end

function RaidMaker_handle_LOOT_OPENED(autoloot)
--print("LOOT_OPENED event: autoloot="..autoloot);
end




function RaidMaker_handle_CHAT_MSG_ADDON(prefix, message, channel, sender)
   local index,charName,charFields
   if ( RaidMaker_sync_enabled == 1 ) then -- only process messages if sync is enabled.
      if ( prefix == RaidMaker_appMessagePrefix ) then -- make sure its not our message
--print("Got prefix <"..RaidMaker_appMessagePrefix.."> msg <"..message..">");
         if ( raidPlayerDatabase ~= nil ) then -- only process if there is a database to parse.
            if ( raidPlayerDatabase.textureIndex ~= nil ) then
               local raidId, msgFormat, rxDay, rxHour, rxMin, appId, msgSeqNum, remoteAction, remoteDataBase = strsplit(":",message, 9 );

               if ( tonumber(msgFormat) == RaidMaker_syncProtocolVersion ) then -- only process messages if the protocol matches ours
                  if ( tonumber(RaidMaker_appInstanceId) ~= tonumber(appId) ) then -- only process messages from remote instances. Different id from ours.
                     if ( tonumber(raidPlayerDatabase.textureIndex) == tonumber(raidId) ) and -- make sure the remote person is on the same raid
                        ( tonumber(raidPlayerDatabase.day         ) == tonumber(rxDay ) ) and -- and
                        ( tonumber(raidPlayerDatabase.hour        ) == tonumber(rxHour) ) and -- and
                        ( tonumber(raidPlayerDatabase.minute      ) == tonumber(rxMin ) ) then
--print(message);

      --                  if ( RaidMaker_msgSequenceNumber+1 == tonumber(msgSeqNum) ) or -- remote seq number is one more than ours. its a remote update of a click.
                        if ( RaidMaker_msgSequenceNumber   == tonumber(msgSeqNum) ) then -- remote seq number matches ours. There was probably a collision. only accept the remote change. discard the database.
                           local startIndex1,endIndex1,playerIndex,playerAction,groupNum = strfind(remoteAction, "(%d+)(%a+)(%d+)" );
                           if ( playerIndex ~= nil ) and
                              ( groupNum ~= nil ) and
                              ( playerAction ~= nil ) then
                              local name = RaidMaker_syncIndexToNameTable[tonumber(playerIndex)];

                              if ( name ~= nil ) then
                                 RaidMaker_processRemoteTransaction(name,playerAction)
                              end
                           end

                           RaidMaker_msgSequenceNumber = tonumber(msgSeqNum);
                        else
                           --
                           -- remote number is totally different.  Sync up with them.
                           --

                           -- clear out our roles.
                           for charName,charFields in pairs(raidPlayerDatabase.playerInfo) do
                              raidPlayerDatabase.playerInfo[charName].tank = 0;
                              raidPlayerDatabase.playerInfo[charName].heals = 0;
                              raidPlayerDatabase.playerInfo[charName].mDps = 0;
                              raidPlayerDatabase.playerInfo[charName].rDps = 0;
                              raidPlayerDatabase.playerInfo[charName].groupNum = 255;
                           end

                           local workingDatabase = remoteDataBase;

                           while true do
                              local currentAction

                              if ( workingDatabase == nil ) then
                                 break;
                              end

                              currentAction, workingDatabase = strsplit(":",workingDatabase, 2 );

                              if ( currentAction == nil ) then
                                 break;
                              else
                                 local startIndex1,endIndex1,playerIndex,playerAction,groupNum = strfind(currentAction, "(%d+)(%a+)(%d+)" );

                                 if ( playerIndex ~= nil ) and
                                    ( groupNum ~= nil ) and
                                    ( playerAction ~= nil ) then
                                    local name = RaidMaker_syncIndexToNameTable[tonumber(playerIndex)];

                                    if ( name ~= nil ) then
                                       RaidMaker_processRemoteTransaction(name,playerAction,groupNum)
                                    end
                                 end
                              end
                           end

                           -- set our local seq number to that in the message.
                           RaidMaker_msgSequenceNumber = tonumber(msgSeqNum);
                        end

                        -- updates may have been made. update the display.
                        RaidMaker_DisplayDatabase();

                        -- track who has been contributing.
                        RaidMaker_updateRaidPlannerList_seen(sender)

                     end
                  end
               end
            end
         end
      elseif ( prefix == RaidMaker_appSyncPrefix ) then
--print("Got prefix <"..RaidMaker_appSyncPrefix.."> msg <"..message..">");
         if ( raidPlayerDatabase ~= nil ) then -- only process if there is a database to parse.
            local remoteAppInstanceId, msgFormat, opcode, raidId = strsplit(":",message, 4 );
            if ( remoteAppInstanceId ~= nil ) and
               ( msgFormat ~= nil ) and
               ( opcode ~= nil ) and
               ( raidId ~= nil ) then
               if ( tonumber(remoteAppInstanceId) ~= RaidMaker_appInstanceId ) then -- make sure its not our own broadcast.
                  if ( tonumber(msgFormat) == RaidMaker_syncProtocolVersion ) then -- only process messages if the protocol matches ours.
                     if ( tonumber(raidId) == tonumber(raidPlayerDatabase.textureIndex)  ) then -- only process messages if the raid matches ours.
                        if ( opcode == "SyncReq" ) then
                           -- we received a request for sync. send our database.
                           RaidMaker_sendUpdateToRemoteApps("SYNCDB");
--print("Sending Database due to sync request.");
                           -- track who has been contributing.
                           RaidMaker_updateRaidPlannerList_seen(sender)

                        elseif ( opcode == "PingReq" ) then
                           -- We received a ping request. Handle it.
                           RaidMaker_generatePingResponse()

                           -- track who has been contributing.
                           RaidMaker_updateRaidPlannerList_seen(sender)

                        elseif ( opcode == "PingResp" ) then
                           -- track who has been contributing.
                           RaidMaker_updateRaidPlannerList_seen(sender)
                           RaidMaker_updateRaidPlannerList_active(sender)

                           -- We received a ping response. Handle it.
                           RaidMaker_handlePingResponse(sender)
                        end

                     end
                  end
               end
            end
         end
      end
   end
end

function RaidMaker_updateRaidPlannerList_seen(player)
   if ( player ~= nil ) then
      if ( RaidMaker_RaidPlannerList == nil ) then
         RaidMaker_RaidPlannerList = {}
      end

      if ( RaidMaker_RaidPlannerList[player] == nil ) then
         RaidMaker_RaidPlannerList[player] = {}; -- create an entry for this player. havent seen them before
      end

      RaidMaker_RaidPlannerList[player].seen = 1;
   end
end

function RaidMaker_updateRaidPlannerList_active(player)
   if ( player ~= nil ) then
      if ( RaidMaker_RaidPlannerList == nil ) then
         RaidMaker_RaidPlannerList = {}
      end

      if ( RaidMaker_RaidPlannerList[player] == nil ) then
         RaidMaker_RaidPlannerList[player] = {}; -- create an entry for this player. havent seen them before
      end

      RaidMaker_RaidPlannerList[player].active = 1;
   end
end

function RaidMaker_generatePingResponse()
   if ( raidPlayerDatabase ~= nil ) then
      SendAddonMessage(RaidMaker_appSyncPrefix, RaidMaker_appInstanceId..":"..
                                                RaidMaker_syncProtocolVersion..":"..
                                                "PingResp:"..
                                                raidPlayerDatabase.textureIndex, "GUILD" );
   end
end

function RaidMaker_generatePingRequest()
   if ( raidPlayerDatabase ~= nil ) then
      SendAddonMessage(RaidMaker_appSyncPrefix, RaidMaker_appInstanceId..":"..
                                                RaidMaker_syncProtocolVersion..":"..
                                                "PingReq:"..
                                                raidPlayerDatabase.textureIndex, "GUILD" );
   end
end

function RaidMaker_handlePingResponse( player )
   RaidMaker_updateRaidPlannerList_seen(player)

   if ( RaidMaker_RaidPlannerListDisplayActive == 1 ) then
      RaidMaker_updateRaidPlannerList_active(player)

      local tipText;
      tipText = RaidMaker_buildRaidPlannerTooltipText()

      GameTooltip:SetText(tipText);
   end
end

function RaidMaker_buildRaidPlannerTooltipText()
   local charName,charFields;
   local tipText = "Raid Planners with Sync:";
   if ( RaidMaker_RaidPlannerList ~= nil ) then
      for charName,charFields in pairs(RaidMaker_RaidPlannerList) do
         if ( charFields.active ~= nil ) and
            ( charFields.active == 1 ) then
            tipText = tipText..green;
         else
            tipText = tipText..mediumGrey;
         end

         tipText = tipText.."\n"..charName;
      end
   end

   return tipText;
end

function RaidMaker_sendUpdateToRemoteApps(playerName, actionId)
   if ( RaidMaker_sync_enabled == 1 ) then

      local transaction = nil

      RaidMaker_msgSequenceNumber = RaidMaker_msgSequenceNumber + 1; -- increment the global sequence number

      if ( playerName == "SYNCDB" ) then
         transaction = ""; -- leave transaction field blank since we just need to push database state.
      elseif ( playerName ~= nil ) then
         if ( raidPlayerDatabase ~= nil ) then
            if ( raidPlayerDatabase.playerInfo ~= nil ) then
               if ( raidPlayerDatabase.playerInfo[playerName] ~= nil ) then
                  transaction = raidPlayerDatabase.playerInfo[playerName].syncIndex..actionId..RaidMaker_currentGroupNumber;
               end
            end
         end
      end

      if ( transaction ~= nil ) then
         local txMsg = "";

         txMsg = txMsg..raidPlayerDatabase.textureIndex..":"; -- Raid Id
         txMsg = txMsg..RaidMaker_syncProtocolVersion..":";  -- protocol version
         txMsg = txMsg..raidPlayerDatabase.day..":";
         txMsg = txMsg..raidPlayerDatabase.hour..":";
         txMsg = txMsg..raidPlayerDatabase.minute..":";
         txMsg = txMsg..RaidMaker_appInstanceId..":";      -- id of this instance of the app
         txMsg = txMsg..RaidMaker_msgSequenceNumber..":";

         txMsg = txMsg..transaction

         for charName,charFields in pairs(raidPlayerDatabase.playerInfo) do
            if ( charFields.tank   == 1 ) or
               ( charFields.heals  == 1 ) or
               ( charFields.mDps   == 1 ) or
               ( charFields.rDps   == 1 ) then

               txMsg = txMsg..":"..raidPlayerDatabase.playerInfo[charName].syncIndex;

               if ( charFields.tank   == 1 ) then
                  txMsg = txMsg.."T";
               end

               if ( charFields.heals  == 1 ) then
                  txMsg = txMsg.."H";
               end

               if ( charFields.mDps   == 1 ) then
                  txMsg = txMsg.."M";
               end

               if ( charFields.rDps   == 1 ) then
                  txMsg = txMsg.."R";
               end
               
               -- append the group number.
               txMsg = txMsg..charFields.groupNum;
               
            end
         end

         SendAddonMessage(RaidMaker_appMessagePrefix, txMsg, "GUILD" );
      end
   end
end



function RaidMaker_processRemoteTransaction(name,playerAction,groupNum)
   local length, singleAction, index

   length = strlen(playerAction)
   
   for index = 1,10 do
      singleAction = strsub(playerAction, index,index)

      if ( singleAction == "T" ) then
         raidPlayerDatabase.playerInfo[name].tank = 1;
      elseif ( singleAction == "t" ) then
         raidPlayerDatabase.playerInfo[name].tank = 0;
      elseif ( singleAction == "H" ) then
         raidPlayerDatabase.playerInfo[name].heals = 1;
      elseif ( singleAction == "h" ) then
         raidPlayerDatabase.playerInfo[name].heals = 0;
      elseif ( singleAction == "M" ) then
         raidPlayerDatabase.playerInfo[name].mDps = 1;
      elseif ( singleAction == "m" ) then
         raidPlayerDatabase.playerInfo[name].mDps = 0;
      elseif ( singleAction == "R" ) then
         raidPlayerDatabase.playerInfo[name].rDps = 1;
      elseif ( singleAction == "r" ) then
         raidPlayerDatabase.playerInfo[name].rDps = 0;
      end
   end
   
   if ( raidPlayerDatabase.playerInfo[name].tank == 0 ) and
      ( raidPlayerDatabase.playerInfo[name].heals == 0 ) and
      ( raidPlayerDatabase.playerInfo[name].mDps == 0 ) and
      ( raidPlayerDatabase.playerInfo[name].rDps == 0 ) then
      raidPlayerDatabase.playerInfo[name].groupNum = 255; -- if they have no role, set group to nogroup (255)
   else
      raidPlayerDatabase.playerInfo[name].groupNum = tonumber(groupNum);
   end
end



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

function RaidMaker_handle_CHAT_MSG_PARTY_LEADER(message, sender, language, channelString, target, flags, unknown1, channelNumber, channelName, unknown2, counter)
   RaidMaker_parse_for_pass(message, sender);
end

function RaidMaker_handle_CHAT_MSG_RAID_LEADER(message, sender, language, channelString, target, flags, unknown1, channelNumber, channelName, unknown2, counter)
   RaidMaker_parse_for_pass(message, sender);
end

function RaidMaker_handle_CHAT_MSG_RAID_WARNING(message, sender, language, channelString, target, flags, unknown1, channelNumber, channelName, unknown2, counter)
   RaidMaker_parse_for_pass(message, sender);
end





function RaidMaker_parse_for_pass(message, playerName)
   local lowerCaseMessage = string.lower(message);

   startIndex,endIndex = strfind(lowerCaseMessage, "pass" );
   if ( startIndex ~= nil ) then
      RaidMaker_addRollEntryToRollLog(playerName, 0);
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

   if ( #RaidMaker_RollLog <= 10 ) then
      RaidMaker_RollLog_Slider:SetMinMaxValues(1,1);
   else
      RaidMaker_RollLog_Slider:SetMinMaxValues(1,#RaidMaker_RollLog-9);
   end

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
      indexToDisplay = RaidMaker_sortedRollList[index + RaidMaker_RollLog_Slider:GetValue()-1]; -- eventually make this the sorted index starting at the scroll bar position.

      if ( index <= #RaidMaker_RollLog ) then
         -- It will fit on the screen and we are not past the end of the list.

         playerNameColor = white;
         rollValueColor = yellow;
         rollAgeColor = yellow;

         timeDeltaSeconds = currentTime - RaidMaker_RollLog[indexToDisplay].epocTime;

         if ( RaidMaker_RollLog[indexToDisplay].rollValue == RaidMaker_highestRoll ) then
            playerNameColor = green;
            rollValueColor = green;
            rollAgeColor = green;
         end

         if ( timeDeltaSeconds > (2*60) ) then -- roll is old. color the entry grey
            playerNameColor = mediumGrey;
            rollValueColor = mediumGrey;
            rollAgeColor = mediumGrey;
         end

         if ( RaidMaker_RollLog[indexToDisplay].preceedingRolls ~= 0 ) then -- roll is a duplicate color the entry grey
            playerNameColor = mediumGrey;
            rollValueColor = mediumGrey;
            rollAgeColor = mediumGrey;
         end

         -- display player name
         RaidMaker_LogTab_Rolls_FieldPlayerNames[index+1]:SetText(playerNameColor..RaidMaker_RollLog[indexToDisplay].playerName);

         -- display roll value
         local rollText;
         if ( RaidMaker_RollLog[indexToDisplay].rollValue == 0 ) then
            rollText = "pass";
         else
            rollText = RaidMaker_RollLog[indexToDisplay].rollValue;
         end
         if ( RaidMaker_RollLog[indexToDisplay].preceedingRolls ~= 0 ) then
            local rollCount = RaidMaker_RollLog[indexToDisplay].preceedingRolls+1;
            rollText = rollText.." #"..rollCount;
         end
         RaidMaker_LogTab_Rolls_FieldRollValues[index+1]:SetText(rollValueColor..rollText);

         -- display roll age
         RaidMaker_LogTab_Rolls_FieldRollAges[index+1]:SetText(rollAgeColor.. RaidMaker_getAgeText(timeDeltaSeconds));
      else
         -- blank out the row
         RaidMaker_LogTab_Rolls_FieldPlayerNames[index+1]:SetText(" ");
         RaidMaker_LogTab_Rolls_FieldRollValues[index+1]:SetText(" ");
         RaidMaker_LogTab_Rolls_FieldRollAges[index+1]:SetText(" ");
      end
   end
end

function RaidMaker_ResetRolls(maxAge)
   if ( RaidMaker_RollLog == nil ) then
      RaidMaker_RollLog = {}; -- start with a blank array.
   end

   local readIndex;
   local writeIndex = 1;
   local timeCutoff = time()-maxAge;
   local newRaidMaker_RollLog = {}; -- create a blank array

   for readIndex = 1,#RaidMaker_RollLog do
      if ( timeCutoff < RaidMaker_RollLog[readIndex].epocTime ) then
         newRaidMaker_RollLog[writeIndex] = RaidMaker_RollLog[readIndex]; -- copy over all the fields
         writeIndex = writeIndex + 1;
      end
   end

   RaidMaker_RollLog = newRaidMaker_RollLog; -- replace the roll log with the new shortened one.
   RaidMaker_resortRollsList();

   if ( #RaidMaker_RollLog <= 10 ) then
      RaidMaker_RollLog_Slider:SetMinMaxValues(1,1);
      RaidMaker_RollLog_Slider:SetValue(1);
   else
      RaidMaker_RollLog_Slider:SetMinMaxValues(1,#RaidMaker_RollLog-9);
      RaidMaker_RollLog_Slider:SetValue(1);
   end
   RaidMaker_DisplayRollsDatabase();
end

function RaidMaker_resortRollsList()
   local index

   RaidMaker_sortedRollList = {}; -- start with a blank array.

   for index = 1,#RaidMaker_RollLog do
      RaidMaker_sortedRollList[index] = index; -- pre-fill the sorting array

      RaidMaker_RollLog[index].preceedingRolls = 0; -- clear out the scratch fields.
      RaidMaker_RollLog[index].highestPrimaryRoll = 0; -- clear out the scratch fields.
   end

   if ( #RaidMaker_RollLog > 1 ) then -- only look for duplicates if there is more than one roll in the db.

      -- sort according to the player name and then roll age so we can figure out which is the primary roll for each person.
      table.sort(RaidMaker_sortedRollList, RaidMaker_RollDisplay_ascendPlayerNameOrder);

      -- find all the duplicate rolls and number them.  table is sorted by player then roll age.
      for index = 1,#RaidMaker_RollLog-1 do
         if ( RaidMaker_RollLog[RaidMaker_sortedRollList[index+0]].playerName ==
              RaidMaker_RollLog[RaidMaker_sortedRollList[index+1]].playerName ) then
            -- name matches, so there is a duplicate roll.
            RaidMaker_RollLog[RaidMaker_sortedRollList[index+1]].preceedingRolls = RaidMaker_RollLog[RaidMaker_sortedRollList[index+0]].preceedingRolls + 1;
         end
      end

      -- find the highest roll
      RaidMaker_highestRoll = 0;
      for index = 1,#RaidMaker_RollLog do
         if ( RaidMaker_RollLog[index].preceedingRolls == 0 ) then -- only accept primary rolls
            if ( RaidMaker_highestRoll < RaidMaker_RollLog[index].rollValue ) then
               RaidMaker_highestRoll = RaidMaker_RollLog[index].rollValue; -- we have a new highest.
            end
         end
      end

      -- sort the table for presentation
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

   if ( RaidMaker_RollLog[a].playerName < RaidMaker_RollLog[b].playerName ) then
      return true;
   elseif ( RaidMaker_RollLog[a].playerName > RaidMaker_RollLog[b].playerName ) then
      return false;
   end

   if ( RaidMaker_RollLog[a].epocTime < RaidMaker_RollLog[b].epocTime ) then
      return true;
   elseif ( RaidMaker_RollLog[a].epocTime > RaidMaker_RollLog[b].epocTime ) then
      return false;
   end

end


function RaidMaker_handle_CHAT_MSG_SYSTEM(message, sender, language, channelString, target, flags, unknown1, channelNumber, channelName, unknown2, counter)

   -- Lotusblossem has gone offline
   -- [Lotusblossem] has come online.

   startIndex,endIndex,playerName,rollValue = strfind(message, "^(.*) rolls (%d+) %(1%-100%)" );
   if ( rollValue ~= nil ) then
      -- roll event detected.
      RaidMaker_addRollEntryToRollLog(playerName, tonumber(rollValue) );
   end

--   startIndex,endIndex,playerName = strfind(message, "%[(.*)%]|h has come online." );
--   if ( playerName ~= nil ) then
--      -- player online status.
--      if ( raidPlayerDatabase ~= nil ) then -- only process if there is a database to parse.
--         if ( raidPlayerDatabase.playerInfo ~= nil ) then
--            if ( raidPlayerDatabase.playerInfo[playerName] ~= nil ) then
--               raidPlayerDatabase.playerInfo[playerName].online = 1;
--               RaidMaker_DisplayDatabase();
--            end
--         end
--      end
--   end
--
--   startIndex,endIndex,playerName = strfind(message, "^(.*) has gone offline." );
--   if ( playerName ~= nil ) then
--      -- player offline status.
--      if ( raidPlayerDatabase ~= nil ) then -- only process if there is a database to parse.
--         if ( raidPlayerDatabase.playerInfo ~= nil ) then
--            if ( raidPlayerDatabase.playerInfo[playerName] ~= nil ) then
--               raidPlayerDatabase.playerInfo[playerName].online = 0;
--               RaidMaker_DisplayDatabase();
--            end
--         end
--      end
--   end

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
         if ( raidSetupArmedFlag == true ) then

            local method, partyMaster, raidMaster
            local numRaidMembers

            lootMethod, partyMaster, raidMaster = GetLootMethod()
            numRaidMembers = GetNumRaidMembers()
            lootThreshold = GetLootThreshold()

            if ( numRaidMembers == 0 ) then
               -- we are not in a raid. might need to convert it to one

               if ( GetNumPartyMembers() > 0 ) then
                  -- we are in a party. lets convert it to a raid.
                  ConvertToRaid();
               end
               pendingInvitesReadyArmedFlag = true

            elseif ( pendingInvitesReadyArmedFlag == true ) then

               -- invite the pending players
               for rowIndex=1,#playerSortedList do
                  charName = playerSortedList[rowIndex];
                  if ( raidPlayerDatabase.playerInfo[charName].partyInviteDeferred == 1) then
                     -- player needs an invite
                     raidPlayerDatabase.playerInfo[charName].partyInviteDeferred = 0;
                     InviteUnit(charName);
                  end
               end
               pendingInvitesReadyArmedFlag = false

            elseif ( lootMethod ~= "master" ) then
               -- raid is not yet configured for master looter.  lets set that up.

               -- set master looter
               local selfName = GetUnitName("player",true); -- get the raid leader name (one running this)
               SetLootMethod("master", selfName);

            elseif ( lootThreshold ~= 4 ) then
               -- loot threshold is not yet set to epic.  configure it.

               -- set loot to epic
               SetLootThreshold(4);  -- set the threshold to epic.


            else
               -- raid setup is complete.  all checks passed.
               raidSetupArmedFlag = false

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


         if ( isRoleUpdateArmed == true ) then -- do we have some assists left to promote

            local numRaidMembers = GetNumRaidMembers();

            if ( numRaidMembers > 0 ) then -- make sure we are in a raid already.
               local allRolesCorrect = 1;

               -- loop through the raid members, promoting any tanks.
               for memberIndex=1,numRaidMembers do

                  local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(memberIndex);

                  local role = UnitGroupRolesAssigned(name)

                  if ( raidPlayerDatabase.playerInfo[name] ~= nil ) then
                     if ( raidPlayerDatabase.playerInfo[name].tank == 1 ) then
                        if ( role ~= "TANK" ) then
                           UnitSetRole(name,"TANK");
                           allRolesCorrect = 0;
                        end
                     elseif ( raidPlayerDatabase.playerInfo[name].heals == 1 ) then
                        if ( role ~= "HEALER" ) then
                           UnitSetRole(name,"HEALER");
                           allRolesCorrect = 0;
                        end
                     elseif ( raidPlayerDatabase.playerInfo[name].mDps == 1 ) then
                        if ( role ~= "DAMAGER" ) then
                           UnitSetRole(name,"DAMAGER");
                           allRolesCorrect = 0;
                        end
                     elseif ( raidPlayerDatabase.playerInfo[name].rDps == 1 ) then
                        if ( role ~= "DAMAGER" ) then
                           UnitSetRole(name,"DAMAGER");
                           allRolesCorrect = 0;
                        end
                     end
                  end
               end

               if ( allRolesCorrect == 1 ) and
                  ( numRaidMembers == numMembersWithRoles ) then -- make sure all roles are set and raid is fully present
                  isRoleUpdateArmed = false;
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

         -- loop through the raid members, updating online status
         for memberIndex=1,numRaidMembers do

            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(memberIndex);
            -- udpate status.
            if ( raidPlayerDatabase.playerInfo[name] ~= nil ) then
--               if ( online == 1 ) then
--                  raidPlayerDatabase.playerInfo[name].online = 1;
--               else
--                  raidPlayerDatabase.playerInfo[name].online = 0;
--               end
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
   numMembersWithRoles = 0;
   local numInvitesToSendHere = 4 - GetNumPartyMembers();
   local rowIndex;
   local charName;


   for rowIndex=1,#playerSortedList do
      charName = playerSortedList[rowIndex];

      if ( raidPlayerDatabase.playerInfo[charName].groupNum == RaidMaker_currentGroupNumber ) then -- only invite ones in our group.
         if ( raidPlayerDatabase.playerInfo[charName].tank == 1 ) or
            ( raidPlayerDatabase.playerInfo[charName].heals == 1 ) or
            ( raidPlayerDatabase.playerInfo[charName].mDps == 1 ) or
            ( raidPlayerDatabase.playerInfo[charName].rDps == 1) then
   
            numMembersWithRoles = numMembersWithRoles + 1;
   
            if ( selfName ~= charName ) then -- invite everyone but ourself
   
               if ( raidPlayerDatabase.playerInfo[charName].tank == 1 ) or -- prepare to promote them when they join group.
                  (raidPlayerDatabase.playerInfo[charName].guildRankIndex < guildRankAssistThreshold ) then
                  numMembersToPromoteToAssist = numMembersToPromoteToAssist +1;
               end
   
               if ( UnitInRaid(charName) == nil ) then -- player isnt in raid already. need to bring them in.
                  if ( numInvitesToSendHere >= 1 ) then
   
   
                     numInvitesToSendHere = numInvitesToSendHere - 1;
   
                     InviteUnit(charName);
   
   
                  else
                     -- need to defer the invitation.
                     raidPlayerDatabase.playerInfo[charName].partyInviteDeferred = 1;
                  end
               end
            end
         end
      end

   end
   
   if ( numMembersWithRoles > 5 ) then
      raidSetupArmedFlag = true; -- indicate that on subsequent party change event we might need to convert to raid and configure looting.
      isRoleUpdateArmed = true; -- indicate that we should update assigned roles.
   end

   RaidMaker_UpdatePlayerAttendanceLog();

end

function RaidMaker_UpdatePlayerAttendanceLog()

   local rowIndex;
   local charName;
   local currentIndex;

   if ( RaidMaker_RaidParticipantLog == nil ) then -- create the database if it doesnt exist
      RaidMaker_RaidParticipantLog = {}
   end

   if ( raidPlayerDatabase ~= nil ) and -- only process if there is a database to parse.
      ( guildRosterInformation ~= nil ) then -- only process if there is a database to parse.
      if ( raidPlayerDatabase.playerInfo ~= nil ) then

         -- get the raid date and other info
         local title, description, creator, eventType, repeatOption, maxSize, textureIndex, weekday, month, day, year, hour, minute, lockoutWeekday, lockoutMonth, lockoutDay, lockoutYear, lockoutHour, lockoutMinute, locked, autoApprove, pendingInvite, inviteStatus, inviteType, calendarType = CalendarGetEventInfo();

         if ( title ~= nil ) then -- only continue if there is an open calendar entry.



            if ( #RaidMaker_RaidParticipantLog == 0 ) then
               -- its a new raid event. we havent logged it before. make a new entry.
               currentIndex = #RaidMaker_RaidParticipantLog+1;
               RaidMaker_RaidParticipantLog[currentIndex] = {}; -- create the structure
            else
               if ( RaidMaker_RaidParticipantLog[#RaidMaker_RaidParticipantLog].year    ~= year   ) or
                  ( RaidMaker_RaidParticipantLog[#RaidMaker_RaidParticipantLog].month   ~= month  ) or
                  ( RaidMaker_RaidParticipantLog[#RaidMaker_RaidParticipantLog].day     ~= day    ) or
                  ( RaidMaker_RaidParticipantLog[#RaidMaker_RaidParticipantLog].hour    ~= hour   ) or
                  ( RaidMaker_RaidParticipantLog[#RaidMaker_RaidParticipantLog].minute  ~= minute ) or
                  ( RaidMaker_RaidParticipantLog[#RaidMaker_RaidParticipantLog].title   ~= title  ) or
                  ( RaidMaker_RaidParticipantLog[#RaidMaker_RaidParticipantLog].weekday ~= weekday) then
                  -- its a new raid event. we havent logged it before. make a new entry.
                  currentIndex = #RaidMaker_RaidParticipantLog+1;
                  RaidMaker_RaidParticipantLog[currentIndex] = {}; -- create the structure
               else
                  currentIndex = #RaidMaker_RaidParticipantLog;
               end
            end



            RaidMaker_RaidParticipantLog[currentIndex].title = title;

            if ( eventType == 1 ) or ( eventType == 2 ) then -- 1=Raid dungeon; 2=Five-player dungeon
               local raidName, icon, expansion, players= select(1+4*(textureIndex-1), CalendarEventGetTextures(eventType));
               RaidMaker_RaidParticipantLog[currentIndex].zone = raidName.."("..players..")";
            end

            RaidMaker_RaidParticipantLog[currentIndex].year    = year;
            RaidMaker_RaidParticipantLog[currentIndex].month   = month;
            RaidMaker_RaidParticipantLog[currentIndex].day     = day;
            RaidMaker_RaidParticipantLog[currentIndex].hour    = hour;
            RaidMaker_RaidParticipantLog[currentIndex].minute  = minute;
            RaidMaker_RaidParticipantLog[currentIndex].weekday = weekday;

            RaidMaker_RaidParticipantLog[currentIndex].playerInfo = {}; -- create the structure

            local charFields;
            for charName,charFields in pairs(raidPlayerDatabase.playerInfo) do

--            for rowIndex=1,#playerSortedList do
--               charName = playerSortedList[rowIndex];

               local inviteStatus;
               inviteStatus = raidPlayerDatabase.playerInfo[charName].inviteStatus;

               if (inviteStatus == 2 ) or   -- ACCEPTED
                  (inviteStatus == 4 ) or   -- CONFIRMED
                  (inviteStatus == 6 ) or   -- STANDBY
                  (inviteStatus == 7 ) or   -- SIGNEDUP
                  (inviteStatus == 9 ) or   -- TENTATIVE
                  (raidPlayerDatabase.playerInfo[charName].tank  == 1 ) or
                  (raidPlayerDatabase.playerInfo[charName].mDps  == 1 ) or
                  (raidPlayerDatabase.playerInfo[charName].rDps  == 1 ) or
                  (raidPlayerDatabase.playerInfo[charName].heals == 1 ) or
                  ( (guildRosterInformation[charName] ~= nil ) and (guildRosterInformation[charName].online == 1 )) then

                  -- player has indicated acceptance of the raid.  add them to the log.
                  RaidMaker_RaidParticipantLog[currentIndex].playerInfo[charName] = {}; -- create the empty structure.
                  RaidMaker_RaidParticipantLog[currentIndex].playerInfo[charName].tank         = raidPlayerDatabase.playerInfo[charName].tank;
                  RaidMaker_RaidParticipantLog[currentIndex].playerInfo[charName].mDps         = raidPlayerDatabase.playerInfo[charName].mDps;
                  RaidMaker_RaidParticipantLog[currentIndex].playerInfo[charName].rDps         = raidPlayerDatabase.playerInfo[charName].rDps;
                  RaidMaker_RaidParticipantLog[currentIndex].playerInfo[charName].heals        = raidPlayerDatabase.playerInfo[charName].heals;
                  RaidMaker_RaidParticipantLog[currentIndex].playerInfo[charName].online       = raidPlayerDatabase.playerInfo[charName].online;
                  RaidMaker_RaidParticipantLog[currentIndex].playerInfo[charName].inviteStatus = raidPlayerDatabase.playerInfo[charName].inviteStatus
                  RaidMaker_RaidParticipantLog[currentIndex].playerInfo[charName].zone         = raidPlayerDatabase.playerInfo[charName].zone;

               end
            end
         end
      end
   end
end



function RaidMaker_ClearAllRolesWithSync()
   local charName,charFields
   for charName,charFields in pairs(raidPlayerDatabase.playerInfo) do
      if ( raidPlayerDatabase.playerInfo[charName].tank == 1 ) then
         raidPlayerDatabase.playerInfo[charName].tank = 0;
         RaidMaker_sendUpdateToRemoteApps(charName, "t");
      end
      if ( raidPlayerDatabase.playerInfo[charName].heals == 1 ) then
         raidPlayerDatabase.playerInfo[charName].heals = 0;
         RaidMaker_sendUpdateToRemoteApps(charName, "h");
      end
      if ( raidPlayerDatabase.playerInfo[charName].mDps == 1 ) then
         raidPlayerDatabase.playerInfo[charName].mDps = 0;
         RaidMaker_sendUpdateToRemoteApps(charName, "m");
      end
      if ( raidPlayerDatabase.playerInfo[charName].rDps == 1 ) then
         raidPlayerDatabase.playerInfo[charName].rDps = 0;
         RaidMaker_sendUpdateToRemoteApps(charName, "r");
      end
   end

   RaidMaker_DisplayDatabase();
end


function RaidMaker_HandleClearAllRolesButton()
   if ( raidPlayerDatabase ~= nil ) then
      if ( raidPlayerDatabase.playerInfo ~= nil ) then
         RaidMaker_ClearAllRolesWithSync();
      end
   end
end

function RaidMaker_HandleFetchCalButton()
   raidPlayerDatabase = RaidMaker_buildRaidList(raidPlayerDatabase);
   if ( raidPlayerDatabase.title ~= nil ) then
      playerSortedList = RaidMaker_buildPlayerListSort(raidPlayerDatabase);
      table.sort(playerSortedList, RaidMaker_ascendInviteStatusOrder);
      RaidMaker_DisplayDatabase();
   end
   numMembersWithRoles = 0; -- reset the flag
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
   local mDpslist = "";
   local rDpslist = "";
   local tankCount = 0;
   local healCount = 0;
   local mDpsCount = 0;
   local rDpsCount = 0;


   for rowIndex=1,#playerSortedList do
      charName = playerSortedList[rowIndex];

      if ( raidPlayerDatabase.playerInfo[charName].groupNum == RaidMaker_currentGroupNumber ) then -- only consider ones in our group.

         if ( raidPlayerDatabase.playerInfo[charName].tank == 1 ) then
            if ( tankCount ~= 0 ) then
               tankList = tankList..", ";
            end
            tankList = tankList..charName
            tankCount = tankCount + 1;
            UnitSetRole(charName,"TANK");
            
         elseif ( raidPlayerDatabase.playerInfo[charName].heals == 1 ) then
            if ( healCount ~= 0 ) then
               healList = healList..", ";
            end
            healList = healList..charName
            healCount = healCount + 1;
            UnitSetRole(charName,"HEALER");
            
         elseif ( raidPlayerDatabase.playerInfo[charName].mDps == 1 ) then
            if ( mDpsCount ~= 0 ) then
               mDpslist = mDpslist..", ";
            end
            mDpslist = mDpslist..charName
            mDpsCount = mDpsCount + 1;
            UnitSetRole(charName,"DAMAGER");
            
         elseif ( raidPlayerDatabase.playerInfo[charName].rDps == 1 ) then
            if ( rDpsCount ~= 0 ) then
               rDpslist = rDpslist..", ";
            end
            rDpslist = rDpslist..charName
            rDpsCount = rDpsCount + 1;
            UnitSetRole(charName,"DAMAGER");
         end
      end
   end

   local numRaidMembers = GetNumRaidMembers();
   local chatDestination = "PARTY"
   if ( numRaidMembers > 0 ) then -- check if its actaully a raid.
      chatDestination = "RAID";
   end
      
   SendChatMessage("Roles for the raid are:", chatDestination );
   SendChatMessage("   Tanks: "..tankList , chatDestination );
   SendChatMessage("   Healers: "..healList , chatDestination );
   SendChatMessage("   Melee DPS: "..mDpslist , chatDestination );
   SendChatMessage("   Ranged DPS: "..rDpslist , chatDestination );

end

function RaidMaker_SetGroupNumber(newGroupNumber)
   RaidMaker_currentGroupNumber = newGroupNumber;

   RaidMaker_GroupNumber_ButtonObject:SetText("Group "..newGroupNumber);

   if ( raidPlayerDatabase ~= nil ) then
      RaidMaker_DisplayDatabase();
   end
end



function RaidMaker_SetUpGuiFields()
   local index;

   --
   -- Set up the Main Field grid
   --

   RaidMaker_TabPage1_SampleTextTab1_GroupedState_Objects = {};
   for index=1,22 do
      local item = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_TabPage1_SampleTextTab1_GroupedState_"..index-1, "OVERLAY", "GameFontNormalSmall" )
      item:SetWidth(50);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetPoint("TOPLEFT", "RaidMaker_TabPage1_SampleTextTab1", "TOPLEFT", 0,0);
         item:SetText("In Raid");
      else
         item:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_GroupedState_Objects[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_TabPage1_SampleTextTab1_GroupedState_Objects[index] = item;
   end

   -- Set up row separators
   RaidMaker_RaidBuilder_row_frame_Objects = {};
   RaidMaker_RaidBuilder_row_frameTexture_Objects = {};
   for index=1,10 do
      local myFrame = CreateFrame("Frame", "RaidMaker_RaidBuilder_row_frame"..index, RaidMaker_TabPage1_SampleTextTab1 )
      myFrame:SetWidth(546)
      local frameLevel = myFrame:GetFrameLevel();
      myFrame:SetFrameLevel(frameLevel -1);
      myFrame:SetHeight(18)
      myFrame:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_GroupedState_Objects[2*index], "TOPLEFT", 0,0)
      local myTexture = myFrame:CreateTexture("RaidMaker_RaidBuilder_row_frameTexture"..index, "BACKGROUND")
      myTexture:SetAllPoints()
      myTexture:SetTexture(0.15, 0.15, 0.15, .25);
      RaidMaker_RaidBuilder_row_frame_Objects[index] = myFrame;
      RaidMaker_RaidBuilder_row_frameTexture_Objects[index] = myTexture;
   end


   RaidMaker_TabPage1_SampleTextTab1_OnlineState_Objects = {};
   for index=1,22 do
      local item = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_TabPage1_SampleTextTab1_OnlineState_"..index-1, "OVERLAY", "GameFontNormalSmall" )
      item:SetWidth(100);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_GroupedState_Objects[1], "TOPRIGHT", 0,0);
         item:SetText("Online");
      else
         item:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_OnlineState_Objects[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_TabPage1_SampleTextTab1_OnlineState_Objects[index] = item;
   end

   RaidMaker_TabPage1_SampleTextTab1_InviteStatus_Objects = {};
   for index=1,22 do
      local item = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_TabPage1_SampleTextTab1_InviteStatus_"..index-1, "OVERLAY", "GameFontNormalSmall" )
      item:SetWidth(75);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_OnlineState_Objects[1], "TOPRIGHT", 0,0);
         item:SetText("Response");
      else
         item:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_InviteStatus_Objects[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_TabPage1_SampleTextTab1_InviteStatus_Objects[index] = item;
   end

   RaidMaker_TabPage1_SampleTextTab1_PlayerName_Objects = {};
   for index=1,22 do
      local item = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_TabPage1_SampleTextTab1_PlayerName_"..index-1, "OVERLAY", "GameFontNormalSmall" )
      item:SetWidth(100);
      item:SetHeight(18);
      item:ClearAllPoints();
      if ( index == 1 ) then
         item:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_InviteStatus_Objects[1], "TOPRIGHT", 0,0);
         item:SetText("Char Name");
      elseif ( index == 22 ) then
         item:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_PlayerName_Objects[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_TabPage1_SampleTextTab1_PlayerName_Objects[index] = item;
   end

   RaidMaker_TabPage1_SampleTextTab1_TankFlag_ButtonObjects = {};
   for index=1,22 do
      local myButton = getglobal("RaidMaker_TabPage1_SampleTextTab1_TankButton_"..index-1);
      local myFontString = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_TabPage1_SampleTextTab1_TankFlag_"..index-1, "OVERLAY", "GameFontNormalSmall" )
      myButton:SetFontString( myFontString )
      myButton:SetWidth(38);
      myButton:SetHeight(18);
      myButton:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_InviteStatus_Objects[index], "TOPRIGHT", 100,0);
      if ( index == 1 ) then
         myButton:SetText("Tank");
      else
         myButton:SetText(" ");
      end
      RaidMaker_TabPage1_SampleTextTab1_TankFlag_ButtonObjects[index] = myButton;
   end

   RaidMaker_TabPage1_SampleTextTab1_HealFlag_ButtonObjects = {};
   for index=1,22 do
      local myButton = getglobal("RaidMaker_TabPage1_SampleTextTab1_HealButton_"..index-1);
      local myFontString = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_TabPage1_SampleTextTab1_HealFlag_"..index-1, "OVERLAY", "GameFontNormalSmall" )
      myButton:SetFontString( myFontString )
      myButton:SetWidth(38);
      myButton:SetHeight(18);
      myButton:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_TankFlag_ButtonObjects[index], "TOPRIGHT", 0,0);
      if ( index == 1 ) then
         myButton:SetText("Heal");
      else
         myButton:SetText(" ");
      end
      RaidMaker_TabPage1_SampleTextTab1_HealFlag_ButtonObjects[index] = myButton;
   end

   RaidMaker_TabPage1_SampleTextTab1_mDpsFlag_ButtonObjects = {};
   for index=1,22 do
      local myButton = getglobal("RaidMaker_TabPage1_SampleTextTab1_mDpsButton_"..index-1);
      local myFontString = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_TabPage1_SampleTextTab1_mDpsFlag_"..index-1, "OVERLAY", "GameFontNormalSmall" )
      myButton:SetFontString( myFontString )
      myButton:SetWidth(37);
      myButton:SetHeight(18);
      myButton:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_HealFlag_ButtonObjects[index], "TOPRIGHT", 0,0);
      if ( index == 1 ) then
         myButton:SetText("mDPS");
      else
         myButton:SetText(" ");
      end
      RaidMaker_TabPage1_SampleTextTab1_mDpsFlag_ButtonObjects[index] = myButton;
   end

   RaidMaker_TabPage1_SampleTextTab1_rDpsFlag_ButtonObjects = {};
   for index=1,22 do
      local myButton = getglobal("RaidMaker_TabPage1_SampleTextTab1_rDpsButton_"..index-1);
      local myFontString = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_TabPage1_SampleTextTab1_rDpsFlag_"..index-1, "OVERLAY", "GameFontNormalSmall" )
      myButton:SetFontString( myFontString )
      myButton:SetWidth(37);
      myButton:SetHeight(18);
      myButton:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_mDpsFlag_ButtonObjects[index], "TOPRIGHT", 0,0);
      if ( index == 1 ) then
         myButton:SetText("rDPS");
      else
         myButton:SetText(" ");
      end
      RaidMaker_TabPage1_SampleTextTab1_rDpsFlag_ButtonObjects[index] = myButton;
   end

   RaidMaker_TabPage1_SampleTextTab1_Class_Objects = {};
   for index=1,22 do
      local item = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_TabPage1_SampleTextTab1_Class_"..index-1, "OVERLAY", "GameFontNormalSmall" )
      item:SetWidth(75);
      item:SetHeight(18);
      item:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_rDpsFlag_ButtonObjects[index], "TOPRIGHT", 0,0);
      if ( index == 1 ) then
         item:SetText("Class");
      else
         item:SetText(" ");
      end
      RaidMaker_TabPage1_SampleTextTab1_Class_Objects[index] = item;
   end



   --
   -- Set up player name buttons
   --


   local menuTbl = {
      {
         text = "Alantodne",
         isTitle = true,
         notCheckable = true,
      },
      {
         text = "Invite",
         notCheckable = true,
         func = function(self)
            InviteUnit(RaidMaker_menu_playerName);
            end,
      },
      {
         text = "Whisper",
         notCheckable = true,
         func = function()
            print(red.."whisper "..white..RaidMaker_menu_playerName..red.." not yet implemented.") end,
      },
      {
         text = "Raid History",
         notCheckable = true,
         hasArrow = true,
         menuList = {
            { text = "raid 1", },
            { text = "raid 2", },
            { text = "raid 3", },
         },
      },
   }

   --
   -- build raid history menu
   --


   local numMenuEntries, menuIndex;
   if ( RaidMaker_RaidParticipantLog ~= nil ) then
      numMenuEntries = #RaidMaker_RaidParticipantLog
      if ( numMenuEntries > 5 ) then
         numMenuEntries = 5; -- limit the number of histories to 10.
      end
      local raidIndexOffset = #RaidMaker_RaidParticipantLog-numMenuEntries;  -- difference in index between menu and corresponding history entry


      local tempMenuList = {};
      for menuIndex=1,numMenuEntries do
         tempMenuList[menuIndex] = {};
         tempMenuList[menuIndex].hasArrow = true;
         tempMenuList[menuIndex].notCheckable = true;
         tempMenuList[menuIndex].text = RaidMaker_RaidParticipantLog[menuIndex+raidIndexOffset].title
         tempMenuList[menuIndex].arg1 = menuIndex+raidIndexOffset
         tempMenuList[menuIndex].func = function(self, arg)
            RaidMaker_repeatLoggedRaid(arg);
            end



         local tempPlayerList = {};
         local currentPlayerIndex = 1;
         local menuPlayerName, menuPlayerNameInfo
         for menuPlayerName, menuPlayerNameInfo in pairs(RaidMaker_RaidParticipantLog[menuIndex+raidIndexOffset].playerInfo) do
            if ( menuPlayerNameInfo.tank == 1 ) or
               ( menuPlayerNameInfo.heals == 1 ) or
               ( menuPlayerNameInfo.mDps == 1 ) or
               ( menuPlayerNameInfo.rDps == 1 ) then


               tempPlayerList[currentPlayerIndex] = {};
               tempPlayerList[currentPlayerIndex].hasArrow = false;
               tempPlayerList[currentPlayerIndex].notCheckable = true;

               tempPlayerList[currentPlayerIndex].text = yellow;
               if ( menuPlayerNameInfo.tank == 1 ) then
                  tempPlayerList[currentPlayerIndex].text = tempPlayerList[currentPlayerIndex].text.." tank"
               end
               if ( menuPlayerNameInfo.heals == 1 ) then
                  tempPlayerList[currentPlayerIndex].text = tempPlayerList[currentPlayerIndex].text.." heal"
               end
               if ( menuPlayerNameInfo.mDps == 1 ) then
                  tempPlayerList[currentPlayerIndex].text = tempPlayerList[currentPlayerIndex].text.." mDps"
               end
               if ( menuPlayerNameInfo.rDps == 1 ) then
                  tempPlayerList[currentPlayerIndex].text = tempPlayerList[currentPlayerIndex].text.." rDps"
               end
               tempPlayerList[currentPlayerIndex].text = tempPlayerList[currentPlayerIndex].text.."  - "..white..menuPlayerName

               currentPlayerIndex = currentPlayerIndex + 1;
            end
         end
         tempMenuList[menuIndex].menuList = tempPlayerList;


      end
--         xxx = yellow.."\nResponded on:\n"..white..format(FULLDATE, CALENDAR_WEEKDAY_NAMES[weekday],CALENDAR_FULLDATE_MONTH_NAMES[month],day, year, month ).."\n"..GameTime_GetFormattedTime(hour, minute, true)



      menuTbl[4].menuList = tempMenuList;
   end

   --
   -- set up player name menu
   --

   RaidMaker_PlayerName_Button_Objects = {};
   for index=1,20 do
      local item = CreateFrame("Button", "RaidMaker_PlayerName_Button_"..index-1, RaidMaker_TabPage1_SampleTextTab1 )
      item:SetFontString( RaidMaker_TabPage1_SampleTextTab1_PlayerName_Objects[index+1] )
      item:SetWidth(100);
      item:SetHeight(18);
      item:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_InviteStatus_Objects[index+1], "TOPRIGHT", 0,0);
      item:SetText("X");
      item:SetScript("OnClick", function(self,button)
         local myText = self:GetText();
         local startIndex1,endIndex1,playerName = strfind(myText, "c%x%x%x%x%x%x%x%x(.*)");
         if ( playerName ~= nil ) then
            menuTbl[1].text = playerName;
            RaidMaker_menu_playerName = playerName;
            EasyMenu(menuTbl, RaidMaker_TabPage1_SampleTextTab1, "RaidMaker_PlayerName_Button_"..index-1 ,0,0, nil, 10)
         end
      end)
      item:SetScript("OnEnter",
         function(self)
            local myText = self:GetText();
            local startIndex1,endIndex1,playerName = strfind(myText, "c%x%x%x%x%x%x%x%x(.*)");
            if ( playerName ~= nil ) then
               if ( raidPlayerDatabase ~= nil ) then -- only process if there is a database to parse.
                  if ( raidPlayerDatabase.playerInfo ~= nil ) then
                     if ( raidPlayerDatabase.playerInfo[playerName] ~= nil ) then
                        local currentTime = time()
                        if ( currentTime - previousGuildRosterUpdateTime > 15 ) then
                           GuildRoster(); -- trigger a GUILD_ROSTER_UPDATE event so we can get the online/offline status of players.
                        end

                        if ( raidPlayerDatabase.playerInfo[playerName].zone ~= nil ) then

                           local signupText = ""
                           GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT",0,0)
                           if ( raidPlayerDatabase.playerInfo[playerName].signupInfo ~= nil ) then

                              local weekday = raidPlayerDatabase.playerInfo[playerName].signupInfo.weekday;
                              local month   = raidPlayerDatabase.playerInfo[playerName].signupInfo.month  ;
                              local day     = raidPlayerDatabase.playerInfo[playerName].signupInfo.day    ;
                              local year    = raidPlayerDatabase.playerInfo[playerName].signupInfo.year   ;
                              local hour    = raidPlayerDatabase.playerInfo[playerName].signupInfo.hour   ;
                              local minute  = raidPlayerDatabase.playerInfo[playerName].signupInfo.minute ;

                              if ( weekday ~= nil ) and
                                 ( weekday ~= 0 ) then
                                 signupText = yellow.."\nResponded on:\n"..white..format(FULLDATE, CALENDAR_WEEKDAY_NAMES[weekday],CALENDAR_FULLDATE_MONTH_NAMES[month],day, year, month ).."\n"..GameTime_GetFormattedTime(hour, minute, true)
                              end
                           end
                           GameTooltip:SetText(white..playerName..yellow.." last seen in "..green..raidPlayerDatabase.playerInfo[playerName].zone..signupText);
                           GameTooltip:Show()
                        end
                     end
                  end
               end
            end
         end)
      item:SetScript("OnLeave", function() GameTooltip:Hide() end)



      RaidMaker_PlayerName_Button_Objects[index] = item;


   end



   --
   -- Set up class totals text fields.
   --

   RaidMaker_WarriorCount_Object = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_WarriorCount", "OVERLAY", "GameFontNormalSmall" )
   RaidMaker_WarriorCount_Object:SetWidth(18);
   RaidMaker_WarriorCount_Object:SetHeight(18);
   RaidMaker_WarriorCount_Object:SetPoint("TOPLEFT", RaidMaker_TabPage1_SampleTextTab1_Class_1, "TOPRIGHT", 55,-7);
   RaidMaker_WarriorCount_Object:SetText(" ");

   RaidMaker_MageCount_Object = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_MageCount", "OVERLAY", "GameFontNormalSmall" )
   RaidMaker_MageCount_Object:SetWidth(18);
   RaidMaker_MageCount_Object:SetHeight(18);
   RaidMaker_MageCount_Object:SetPoint("TOPLEFT", RaidMaker_WarriorCount_Object, "BOTTOMLEFT", 0,-18);
   RaidMaker_MageCount_Object:SetText(" ");

   RaidMaker_RogueCount_Object = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_RogueCount", "OVERLAY", "GameFontNormalSmall" )
   RaidMaker_RogueCount_Object:SetWidth(18);
   RaidMaker_RogueCount_Object:SetHeight(18);
   RaidMaker_RogueCount_Object:SetPoint("TOPLEFT", RaidMaker_MageCount_Object, "BOTTOMLEFT", 0,-18);
   RaidMaker_RogueCount_Object:SetText(" ");

   RaidMaker_DruidCount_Object = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_DruidCount", "OVERLAY", "GameFontNormalSmall" )
   RaidMaker_DruidCount_Object:SetWidth(18);
   RaidMaker_DruidCount_Object:SetHeight(18);
   RaidMaker_DruidCount_Object:SetPoint("TOPLEFT", RaidMaker_RogueCount_Object, "BOTTOMLEFT", 0,-18);
   RaidMaker_DruidCount_Object:SetText(" ");

   RaidMaker_HunterCount_Object = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_HunterCount", "OVERLAY", "GameFontNormalSmall" )
   RaidMaker_HunterCount_Object:SetWidth(18);
   RaidMaker_HunterCount_Object:SetHeight(18);
   RaidMaker_HunterCount_Object:SetPoint("TOPLEFT", RaidMaker_DruidCount_Object, "BOTTOMLEFT", 0,-18);
   RaidMaker_HunterCount_Object:SetText(" ");

   RaidMaker_ShamanCount_Object = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_ShamanCount", "OVERLAY", "GameFontNormalSmall" )
   RaidMaker_ShamanCount_Object:SetWidth(18);
   RaidMaker_ShamanCount_Object:SetHeight(18);
   RaidMaker_ShamanCount_Object:SetPoint("TOPLEFT", RaidMaker_HunterCount_Object, "BOTTOMLEFT", 0,-18);
   RaidMaker_ShamanCount_Object:SetText(" ");

   RaidMaker_PriestCount_Object = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_PriestCount", "OVERLAY", "GameFontNormalSmall" )
   RaidMaker_PriestCount_Object:SetWidth(18);
   RaidMaker_PriestCount_Object:SetHeight(18);
   RaidMaker_PriestCount_Object:SetPoint("TOPLEFT", RaidMaker_ShamanCount_Object, "BOTTOMLEFT", 0,-18);
   RaidMaker_PriestCount_Object:SetText(" ");

   RaidMaker_WarlockCount_Object = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_WarlockCount", "OVERLAY", "GameFontNormalSmall" )
   RaidMaker_WarlockCount_Object:SetWidth(18);
   RaidMaker_WarlockCount_Object:SetHeight(18);
   RaidMaker_WarlockCount_Object:SetPoint("TOPLEFT", RaidMaker_PriestCount_Object, "BOTTOMLEFT", 0,-18);
   RaidMaker_WarlockCount_Object:SetText(" ");

   RaidMaker_PaladinCount_Object = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_PaladinCount", "OVERLAY", "GameFontNormalSmall" )
   RaidMaker_PaladinCount_Object:SetWidth(18);
   RaidMaker_PaladinCount_Object:SetHeight(18);
   RaidMaker_PaladinCount_Object:SetPoint("TOPLEFT", RaidMaker_WarlockCount_Object, "BOTTOMLEFT", 0,-18);
   RaidMaker_PaladinCount_Object:SetText(" ");

   RaidMaker_DeathknightCount_Object = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_DeathknightCount", "OVERLAY", "GameFontNormalSmall" )
   RaidMaker_DeathknightCount_Object:SetWidth(18);
   RaidMaker_DeathknightCount_Object:SetHeight(18);
   RaidMaker_DeathknightCount_Object:SetPoint("TOPLEFT", RaidMaker_PaladinCount_Object, "BOTTOMLEFT", 0,-18);
   RaidMaker_DeathknightCount_Object:SetText(" ");

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
   -- Position the raid maker buttons.
   --
   local localButton = getglobal("RaidMaker_TabPage1_SampleTextTab1_GroupedStateHeaderButton");
   localButton:SetPoint("TOPRIGHT", "RaidMaker_TabPage1_SampleTextTab1_GroupedState_0", "TOPRIGHT", 0,3)

   local localButton = getglobal("RaidMaker_TabPage1_SampleTextTab1_OnlineStateHeaderButton");
   localButton:SetPoint("TOPRIGHT", "RaidMaker_TabPage1_SampleTextTab1_OnlineState_0", "TOPRIGHT", 0,3)

   local localButton = getglobal("RaidMaker_TabPage1_SampleTextTab1_InviteStatusHeaderButton");
   localButton:SetPoint("TOPRIGHT", "RaidMaker_TabPage1_SampleTextTab1_InviteStatus_0", "TOPRIGHT", 0,3)

   local localButton = getglobal("RaidMaker_TabPage1_SampleTextTab1_PlayerNameHeaderButton");
   localButton:SetPoint("TOPRIGHT", "RaidMaker_TabPage1_SampleTextTab1_PlayerName_0", "TOPRIGHT", 0,3)

   local localButton = getglobal("RaidMaker_TabPage1_SampleTextTab1_ClassHeaderButton");
   localButton:SetPoint("TOPRIGHT", "RaidMaker_TabPage1_SampleTextTab1_Class_0", "TOPRIGHT", 0,3)


   local localButton = getglobal("RaidMaker_FetchCalendarButton");
   localButton:SetPoint("TOPLEFT", "RaidMaker_TabPage1_SampleTextTab1_GroupedState_21", "BOTTOMLEFT", 0,-12)



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
                  GameTooltip:SetText("Forces refresh on player online status and last zone.  Throttled by server.");
                  GameTooltip:Show()
               end)
   RaidMaker_ButtonRefresh:SetScript("OnLeave", function() GameTooltip:Hide() end)


   --
   -- Set Up tooltips for roll tab buttons
   --

   RaidMaker_RollResetButton4:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Purge all roll entries that are older than 4 minutes in age.");
                  GameTooltip:Show()
               end)
   RaidMaker_RollResetButton4:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_RollResetButton3:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Purge all roll entries that are older than 3 minutes in age.");
                  GameTooltip:Show()
               end)
   RaidMaker_RollResetButton3:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_RollResetButton2:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Purge all roll entries that are older than 2 minutes in age.");
                  GameTooltip:Show()
               end)
   RaidMaker_RollResetButton2:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_RollResetButton1:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Purge all roll entries that are older than 1 minutes in age.");
                  GameTooltip:Show()
               end)
   RaidMaker_RollResetButton1:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_RollResetButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Purge all roll entries.");
                  GameTooltip:Show()
               end)
   RaidMaker_RollResetButton:SetScript("OnLeave", function() GameTooltip:Hide() end)


   --
   -- Set Up tooltips for column header buttons
   --
   RaidMaker_TabPage1_SampleTextTab1_GroupedStateHeaderButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Sort by Grouped status; Event Response status; Player Name.");
                  GameTooltip:Show()
               end)
   RaidMaker_TabPage1_SampleTextTab1_GroupedStateHeaderButton:SetScript("OnLeave", function() GameTooltip:Hide() end)


   RaidMaker_TabPage1_SampleTextTab1_OnlineStateHeaderButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Sort by Online status; Event Response status; Player Name.");
                  GameTooltip:Show()
               end)
   RaidMaker_TabPage1_SampleTextTab1_OnlineStateHeaderButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_TabPage1_SampleTextTab1_InviteStatusHeaderButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Sort by Event Response status; Response Time; Player Name.");
                  GameTooltip:Show()
               end)
   RaidMaker_TabPage1_SampleTextTab1_InviteStatusHeaderButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_TabPage1_SampleTextTab1_PlayerNameHeaderButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Sort by Player Name.");
                  GameTooltip:Show()
               end)
   RaidMaker_TabPage1_SampleTextTab1_PlayerNameHeaderButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_TabPage1_SampleTextTab1_ClassHeaderButton:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Sort by Class name; Player Name.");
                  GameTooltip:Show()
               end)
   RaidMaker_TabPage1_SampleTextTab1_ClassHeaderButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_TabPage1_SampleTextTab1_TankButton_0:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Sort by Tank status; Healer status; DPS status; Player Name.");
                  GameTooltip:Show()
               end)
   RaidMaker_TabPage1_SampleTextTab1_TankButton_0:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_TabPage1_SampleTextTab1_HealButton_0:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Sort by Healer status; Tank status; DPS status; Player Name.");
                  GameTooltip:Show()
               end)
   RaidMaker_TabPage1_SampleTextTab1_HealButton_0:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_TabPage1_SampleTextTab1_mDpsButton_0:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Sort by DPS status; Tank status; Healer status; Player Name.");
                  GameTooltip:Show()
               end)
   RaidMaker_RollResetButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

   RaidMaker_TabPage1_SampleTextTab1_rDpsButton_0:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Sort by DPS status; Tank status; Healer status; Player Name.");
                  GameTooltip:Show()
               end)
   RaidMaker_RollResetButton:SetScript("OnLeave", function() GameTooltip:Hide() end)


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
                     RaidMaker_HandleFetchCalButton()
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
                     RaidMaker_HandleFetchCalButton()
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
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Rolls_FieldNamesField"..index-1, "OVERLAY", "GameFontNormalSmall" )
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
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Rolls_RollValue"..index-1, "OVERLAY", "GameFontNormalSmall" )
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
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Rolls_RollAges"..index-1, "OVERLAY", "GameFontNormalSmall" )
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
   RaidMaker_LogTab_Loot_FieldItemLinkButton = {}
   for index=1,11 do
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Loot_FieldNamesField"..index-1, "OVERLAY", "GameFontNormalSmall" )
      item:SetWidth(100);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetPoint("TOPLEFT", RaidMaker_GroupLootFrame, "TOPLEFT", 5,-5);
         item:SetText("Player");
         local myButton = CreateFrame("Button", "RaidMaker_LogTab_Loot_PlayerNameButton", RaidMaker_GroupLootFrame )
         myButton:SetFontString( item )
         myButton:SetWidth(100);
         myButton:SetHeight(18);
         myButton:SetPoint("TOPLEFT", RaidMaker_GroupLootFrame, "TOPLEFT", 5,-5);
         myButton:SetScript("OnEnter",
                  function(this)
                     GameTooltip_SetDefaultAnchor(GameTooltip, this)
                     GameTooltip:SetText("Sort by player name.");
                     GameTooltip:Show()
                  end)
         myButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
         myButton:SetScript("OnClick", function(self,button)
            RaidMaker_LootLog_ClickHandler_PlayerName();
            end)
         RaidMaker_LogTab_Loot_PlayerNameButtonObject = myButton;
      else
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldNames[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_LogTab_Loot_FieldNames[index] = item;
   end




   for index=1,11 do
      local myFontString = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Loot_ItemLink"..index-1, "OVERLAY", "GameFontNormalSmall" )
      local myButton = CreateFrame("Button", "RaidMaker_LogTab_Loot_ItemLinkButton_"..index-1, RaidMaker_GroupRollFrame )
      myButton:SetFontString( myFontString )
      myButton:SetWidth(200);
      myButton:SetHeight(18);
      if ( index == 1 ) then
         myButton:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldNames[1], "TOPRIGHT", 0,0);
         myButton:SetText("Item Name");

         myButton:SetScript("OnEnter",
                  function(this)
                     GameTooltip_SetDefaultAnchor(GameTooltip, this)
                     GameTooltip:SetText("Sort by Item name.");
                     GameTooltip:Show()
                  end)
         myButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
         myButton:SetScript("OnClick", function(self,button)
            RaidMaker_LootLog_ClickHandler_ItemName();
            end)
      else
         myButton:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldItemLinkButton[index-1], "BOTTOMLEFT", 0,0);
         myButton:SetText(" ");
         myButton:SetScript("OnEnter",
                  function(this)
                     GameTooltip_SetDefaultAnchor(GameTooltip, this)
                     local myText = this:GetText();
                     local startIndex,endIndex,itemID = strfind(myText, "(%d+):")
                     if ( itemID ~= nil ) then
                        GameTooltip:SetHyperlink(myText);
                        GameTooltip:Show()
                     end
                  end)
         myButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
      end

      RaidMaker_LogTab_Loot_FieldItemLinkButton[index] = myButton;
      RaidMaker_LogTab_Loot_FieldItemLink[index] = myFontString;
   end

   for index=1,11 do
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Loot_RollValue"..index-1, "OVERLAY", "GameFontNormalSmall" )
      item:SetWidth(100);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetText("Roll Value");
         local myButton = CreateFrame("Button", "RaidMaker_LogTab_Loot_RollValueButton", RaidMaker_GroupLootFrame )
         myButton:SetFontString( item )
         myButton:SetWidth(100);
         myButton:SetHeight(18);

         myButton:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldItemLinkButton[1], "TOPRIGHT", 0,0);
         myButton:SetScript("OnEnter",
                  function(this)
                     GameTooltip_SetDefaultAnchor(GameTooltip, this)
                     GameTooltip:SetText("Sort by Roll Value name.");
                     GameTooltip:Show()
                  end)
         myButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
         myButton:SetScript("OnClick", function(self,button)
            RaidMaker_LootLog_ClickHandler_RollValue();
            end)
         RaidMaker_LogTab_Loot_RollValueButtonObject = myButton;
      else
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldRollValues[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_LogTab_Loot_FieldRollValues[index] = item;
   end
   
   for index=1,11 do
      local item = RaidMaker_GroupRollFrame:CreateFontString("RaidMaker_LogTab_Loot_RollAges"..index-1, "OVERLAY", "GameFontNormalSmall" )
      item:SetWidth(100);
      item:SetHeight(18);
      if ( index == 1 ) then
         item:SetText("Roll Age");
         local myButton = CreateFrame("Button", "RaidMaker_LogTab_Loot_RollAgeButton", RaidMaker_GroupLootFrame )
         myButton:SetFontString( item )
         myButton:SetWidth(100);
         myButton:SetHeight(18);

         myButton:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldRollValues[1], "TOPRIGHT", 0,0);
         myButton:SetScript("OnEnter",
                  function(this)
                     GameTooltip_SetDefaultAnchor(GameTooltip, this)
                     GameTooltip:SetText("Sort by Roll Age name.");
                     GameTooltip:Show()
                  end)
         myButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
         myButton:SetScript("OnClick", function(self,button)
            RaidMaker_LootLog_ClickHandler_RollAge();
            end)
         RaidMaker_LogTab_Loot_RollAgeButtonObject = myButton;
      else
         item:SetPoint("TOPLEFT", RaidMaker_LogTab_Loot_FieldRollAges[index-1], "BOTTOMLEFT", 0,0);
         item:SetText(" ");
      end
      RaidMaker_LogTab_Loot_FieldRollAges[index] = item;
   end


   --
   -- Set up the Lootlog slider
   --
   RaidMaker_LootLog_Slider:SetPoint("TOPLEFT", "RaidMaker_LogTab_Loot_RollAges1", "TOPRIGHT", 0,0);
   RaidMaker_LootLog_Slider:SetScript("OnValueChanged", RaidMaker_DisplayLootDatabase );

   if ( #RaidMaker_lootLogData <= 10 ) then
      RaidMaker_LootLog_Slider:SetMinMaxValues(#RaidMaker_lootLogData-9,#RaidMaker_lootLogData-9);
      RaidMaker_LootLog_Slider:SetValue(#RaidMaker_lootLogData-9);
   else
      RaidMaker_LootLog_Slider:SetMinMaxValues(1,#RaidMaker_lootLogData-9);
      RaidMaker_LootLog_Slider:SetValue(#RaidMaker_lootLogData-9);
   end


   --
   -- Set up the Rolllog slider
   --
   RaidMaker_RollLog_Slider:SetPoint("TOPLEFT", "RaidMaker_LogTab_Rolls_RollAges1", "TOPRIGHT", 0,0);
   RaidMaker_RollLog_Slider:SetScript("OnValueChanged", RaidMaker_DisplayRollsDatabase );


   --
   -- Set up the RaidMaker slider
   --
   RaidMaker_VSlider:SetPoint("TOPLEFT", "RaidMaker_TabPage1_SampleTextTab1_Class_1", "TOPRIGHT", 0,0);
   RaidMaker_VSlider:SetScript("OnValueChanged", RaidMaker_TextTableUpdate );

   --
   -- Set up the mouse wheel to scroll
   --
   RaidMaker_GroupRollFrame:EnableMouseWheel(true);
   RaidMaker_GroupRollFrame:SetScript("OnMouseWheel", function(self,delta) RaidMaker_OnMouseWheelRollLog(self, delta) end );
   RaidMaker_GroupLootFrame:EnableMouseWheel(true);
   RaidMaker_GroupLootFrame:SetScript("OnMouseWheel", function(self,delta) RaidMaker_OnMouseWheelLootLog(self, delta) end );
   RaidMaker_TabPage1:EnableMouseWheel(true);
   RaidMaker_TabPage1:SetScript("OnMouseWheel", function(self,delta) RaidMaker_OnMouseWheel(self, delta) end );

   RaidMaker_RollLog_Slider:SetMinMaxValues(1,1);
   RaidMaker_RollLog_Slider:SetValue(1);

   --
   -- Create sync checkbox
   --
   RaidMaker_sync_enabled = 0;
   local frame = CreateFrame("CheckButton", "RaidMaker_Sync_Checkbutton", RaidMaker_TabPage1_SampleTextTab1, "UICheckButtonTemplate")
   frame:ClearAllPoints();
   frame:SetPoint("TOPLEFT", RaidMaker_TabPage1_RaidIdText, "TOPLEFT", 480,12);
   _G[frame:GetName().."Text"]:SetText("Sync")
   frame:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Clicking checkbox will request raid configuration from other raid planners\nwho have sync enabled and will auto-sync further raid configuration edits.");
                  GameTooltip:Show()
                  RaidMaker_RaidPlannerListDisplayActive = 1;

                  if ( RaidMaker_sync_enabled == 1 ) then
                     if ( RaidMaker_RaidPlannerList ~= nil ) then
                        local charName,charFields;
                        for charName,charFields in pairs(RaidMaker_RaidPlannerList) do
                           RaidMaker_RaidPlannerList[charName].active = 0; -- clear out the database for a fresh ping result set
                        end
                        local selfName = GetUnitName("player",true);
                        RaidMaker_updateRaidPlannerList_active(selfName)
                     end
                     RaidMaker_generatePingRequest()

                     local tipText;
                     tipText = RaidMaker_buildRaidPlannerTooltipText()
                     GameTooltip:SetText(tipText);

                  end
               end)
   frame:SetChecked( RaidMaker_sync_enabled == 1 )
   frame:SetScript("OnLeave", function()
                                 GameTooltip:Hide()
                                 RaidMaker_RaidPlannerListDisplayActive = 0;
                              end)
   frame:SetScript("OnClick", function(self,button)
      if ( self:GetChecked() ) then
         RaidMaker_sync_enabled = 1
         if ( raidPlayerDatabase ~= nil ) and
            ( raidPlayerDatabase.textureIndex ~= nil ) then
            SendAddonMessage(RaidMaker_appSyncPrefix, RaidMaker_appInstanceId..":"..
                                                      RaidMaker_syncProtocolVersion..":"..
                                                      "SyncReq:"..
                                                      raidPlayerDatabase.textureIndex, "GUILD" );
--print("sending sync request.");               
         end
      else
         RaidMaker_sync_enabled = 0;
      end
   end)


   --
   -- Create Raid Group Number selection field
   --

   local menuTbl = {
      {
         text = "Group Selection",
         isTitle = true,
         notCheckable = true,
      },
      {
         text = "Group 1",
         isTitle = false,
         notCheckable = true,
         func = function(self)
            RaidMaker_SetGroupNumber(1);
            end,
      },
      {
         text = "Group 2",
         isTitle = flase,
         notCheckable = true,
         func = function(self)
            RaidMaker_SetGroupNumber(2);
            end,
      },
      {
         text = "Group 3",
         isTitle = false,
         notCheckable = true,
         func = function(self)
            RaidMaker_SetGroupNumber(3);
            end,
      },
      {
         text = "Group 4",
         isTitle = false,
         notCheckable = true,
         func = function(self)
            RaidMaker_SetGroupNumber(4);
            end,
      },
   }


   local item = RaidMaker_TabPage1_SampleTextTab1:CreateFontString("RaidMaker_GroupNumber_FontString", "OVERLAY", "GameFontNormalSmall" )
   item:ClearAllPoints();
   RaidMaker_GroupNumber_FontStringObject = item;

   local item = CreateFrame("Button", "RaidMaker_GroupNumber_Button", RaidMaker_TabPage1_SampleTextTab1 )
   item:SetFontString( RaidMaker_GroupNumber_FontStringObject )
   item:SetWidth(25);
   item:SetHeight(18);
   item:SetPoint("TOPLEFT", RaidMaker_TabPage1_RaidIdText, "TOPLEFT", 555,5);
   item:SetText("Group "..RaidMaker_currentGroupNumber);
   item:SetScript("OnClick", function(self,button)
--      print("Button pushed");
      EasyMenu(menuTbl, RaidMaker_TabPage1_SampleTextTab1, "RaidMaker_GroupNumber_Button" ,0,0, nil, 10)
      end)
--   item:SetScript("OnClick", function(self,button)
--      local myText = self:GetText();
--      local startIndex1,endIndex1,playerName = strfind(myText, "c%x%x%x%x%x%x%x%x(.*)");
--      if ( playerName ~= nil ) then
--         menuTbl[1].text = playerName;
--         RaidMaker_menu_playerName = playerName;
--         EasyMenu(menuTbl, RaidMaker_TabPage1_SampleTextTab1, "RaidMaker_PlayerName_Button_"..index-1 ,0,0, nil, 10)
--      end
--   end)
   item:SetScript("OnEnter",
               function(this)
                  GameTooltip_SetDefaultAnchor(GameTooltip, this)
                  GameTooltip:SetText("Shows currently selected group.\nClick this to bring up menu to allow group selection.\nThis is used when creating multiple groups.");
                  GameTooltip:Show()
               end)
   item:SetScript("OnLeave", function() GameTooltip:Hide() end)
   RaidMaker_GroupNumber_ButtonObject = item;

end


