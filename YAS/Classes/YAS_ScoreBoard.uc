class YAS_ScoreBoard extends KFGUI_Page
	dependson(YAS_Types);

const LocalMessage = class'YAS_LocalMessage';

const HeaderWidthRatio         = 0.30f;
const PlayerListWidthRatio     = 0.6f;
const PlayerEntryHeightMod     = 1.05f;

const CompactModePlayers = 16;

const ListItemsCompact = 16;
const ListItemsDefault = 12;

const FontScalarModCompact = 1.0f;
const FontScalarModDefault = 1.25f;

const ShowDamage = true;

const IconRanked        = Texture2D'DailyObjective_UI.KF2_Dailies_Icon_PerkLvl'; // where the hell is the right icon?
//const IconCustom        = Texture2D'UI_Menus.ServerBrowserMenu_SWF_I26';
//const IconUnranked      = Texture2D'UI_Menus.ServerBrowserMenu_SWF_I28';
const IconUnrankedAlt   = Texture2D'UI_VoiceComms_TEX.UI_VoiceCommand_Icon_Negative';
const IconPassword      = Texture2D'UI_Menus.ServerBrowserMenu_SWF_I27';
//const IconDosh          = Texture2D'UI_HUD.InGameHUD_SWF_I13A';
const IconPlayer        = Texture2D'UI_HUD.InGameHUD_ZED_SWF_I1F5';
//const IconClock         = Texture2D'UI_HUD.InGameHUD_SWF_I17D';
const IconSkull         = Texture2D'UI_Shared.AssetLib_I32';
const IconSkullAlt      = Texture2D'UI_ZEDRadar_TEX.MapIcon_Patriarch';
const IconSkullAndBones = Texture2D'UI_ZEDRadar_TEX.MapIcon_FailedSpawn';
const IconHealth        = Texture2D'UI_VoiceComms_TEX.UI_VoiceCommand_Icon_Heal';
const IconHealthAlt     = Texture2D'UI_Objective_Tex.UI_Obj_Healing_Loc';
const IconHorzine       = Texture2D'UI_PerkIcons_TEX.UI_Horzine_H_Logo';
const IconGlobe         = Texture2D'DailyObjective_UI.KF2_Dailies_Icon_Map';

var public E_LogLevel LogLevel;

var transient float HealthXPos, RankXPos, PlayerXPos, LevelXPos, PerkXPos, DoshXPos, KillsXPos, AssistXPos, PingXPos, ScrollXPos;
var transient float HealthWBox, RankWBox, PlayerWBox, LevelWBox, PerkWBox, DoshWBox, KillsWBox, AssistWBox, PingWBox, ScrollWBox;
var transient float NextScoreboardRefresh;
var transient int   NumPlayer;

var int PlayerIndex;
var KFGUI_List PlayersList;
var Texture2D DefaultAvatar;

var KFGameReplicationInfo KFGRI;
var array<KFPlayerReplicationInfo> KFPRIArray;

var KFPlayerController OwnerPC;

var Color PingColor;
var float PingBars;

// Cache
var public Array<YAS_RepInfoPlayer> RepInfos;

var public YAS_Settings Settings;
var public String DynamicServerName, MessageOfTheDay;
var public bool UsesStats, Custom, PasswordRequired;

var public SystemRank RankPlayer;
var public SystemRank RankAdmin;

var private int   ListItems;
var private float FontScalarMod;

function YAS_RepInfoPlayer FindRepInfo(KFPlayerReplicationInfo KFPRI)
{
	local YAS_RepInfoPlayer RepInfo;

	foreach RepInfos(RepInfo)
	{
		if (RepInfo.UID.Uid == KFPRI.UniqueId.Uid)
		{
			if (RepInfo.bPendingDelete || RepInfo.bDeleteMe)
			{
				RepInfos.RemoveItem(RepInfo);
				break;
			}
			else return RepInfo;
		}
	}

	foreach KFPRI.DynamicActors(class'YAS_RepInfoPlayer', RepInfo)
	{
		if (RepInfo.UID.Uid == KFPRI.UniqueId.Uid)
		{
			if (RepInfo.bPendingDelete || RepInfo.bDeleteMe) continue;

			RepInfos.AddItem(RepInfo);
			return RepInfo;
		}
	}

	return None;
}

function Rank PlayerRank(YAS_RepInfoPlayer RepInfo, bool bAdmin)
{
	local Rank Rank;

	`Log_Trace();

	Rank = class'YAS_Types'.static.FromSystemRank(RankPlayer);

	if (RepInfo != None)
	{
		Rank = RepInfo.Rank;
	}

	if (bAdmin && !Rank.OverrideAdmin)
	{
		Rank = class'YAS_Types'.static.FromSystemRank(RankAdmin);
	}

	return Rank;
}

function float MinPerkBoxWidth(float FontScalar)
{
	local Array<String> PerkNames;
	local String PerkName;
	local float XL, YL, MaxWidth;

	PerkNames.AddItem(class'KFGFxMenu_Inventory'.default.PerkFilterString);
	PerkNames.AddItem(class'KFPerk_Berserker'.default.PerkName);
	PerkNames.AddItem(class'KFPerk_Commando'.default.PerkName);
	PerkNames.AddItem(class'KFPerk_Support'.default.PerkName);
	PerkNames.AddItem(class'KFPerk_FieldMedic'.default.PerkName);
	PerkNames.AddItem(class'KFPerk_Demolitionist'.default.PerkName);
	PerkNames.AddItem(class'KFPerk_Firebug'.default.PerkName);
	PerkNames.AddItem(class'KFPerk_Gunslinger'.default.PerkName);
	PerkNames.AddItem(class'KFPerk_Sharpshooter'.default.PerkName);
	PerkNames.AddItem(class'KFPerk_SWAT'.default.PerkName);
	PerkNames.AddItem(class'KFPerk_Survivalist'.default.PerkName);

	foreach PerkNames(PerkName)
	{
		Canvas.TextSize(PerkName $ "A", XL, YL, FontScalar * FontScalarMod, FontScalar * FontScalarMod);
		if (XL > MaxWidth) MaxWidth = XL;
	}

	return MaxWidth;
}

function InitMenu()
{
	Super.InitMenu();
	PlayersList = KFGUI_List(FindComponentID('PlayerList'));
	OwnerPC = KFPlayerController(GetPlayer());
	if (GetKFGRI() != None)
	{
		if (KFGRI.MaxHumanCount > CompactModePlayers)
		{
			ListItems     = ListItemsCompact;
			FontScalarMod = FontScalarModCompact;
		}
		else
		{
			ListItems     = ListItemsDefault;
			FontScalarMod = FontScalarModDefault;
		}
		PlayersList.ListItemsPerPage = ListItems;
	}
}

static function CheckAvatar(KFPlayerReplicationInfo KFPRI, KFPlayerController PC)
{
	local Texture2D Avatar;

	if (KFPRI.Avatar == None || KFPRI.Avatar == default.DefaultAvatar)
	{
		Avatar = FindAvatar(PC, KFPRI.UniqueId);
		if (Avatar == None)
			Avatar = default.DefaultAvatar;

		KFPRI.Avatar = Avatar;
	}
}

delegate bool InOrder(KFPlayerReplicationInfo P1, KFPlayerReplicationInfo P2)
{
	if (P1 == None || P2 == None)
		return true;

	if (P1.GetTeamNum() < P2.GetTeamNum())
		return false;

	if (P1.Kills == P2.Kills)
	{
		if (P1.Assists == P2.Assists)
			return true;

		return P1.Assists < P2.Assists;
	}

	return P1.Kills < P2.Kills;
}

function string WaveText()
{
	local int CurrentWaveNum;

	CurrentWaveNum = KFGRI.WaveNum;
	if (KFGRI.IsBossWave())
	{
		return class'KFGFxHUD_WaveInfo'.default.BossWaveString;
	}
	else if (KFGRI.IsFinalWave())
	{
		return class'KFGFxHUD_ScoreboardMapInfoContainer'.default.FinalString;
	}
	else
	{
		if (KFGRI.default.bEndlessMode)
		{
			return "" $ CurrentWaveNum;
		}
		else
		{
			return CurrentWaveNum $ " / " $ KFGRI.GetFinalWaveNum();
		}
	}
}

function KFGameReplicationInfo GetKFGRI()
{
	if (KFGRI == None)
	{
		KFGRI = KFGameReplicationInfo(GetPlayer().WorldInfo.GRI);
	}

	return KFGRI;
}

function DrawMenu()
{
	local string S;
	local PlayerController PC;
	local KFPlayerReplicationInfo KFPRI;
	local PlayerReplicationInfo PRI;
	local float XPos, YPos, YL, XL, FontScalar, XPosCenter, BoxW, BoxX, BoxH, MinBoxW, DoshSize, ScrollBarWidth;
	local int i, j, NumSpec, NumAlivePlayer, Width;
	local float BorderSize, EdgeSize, PlayerListSizeY;
	local Color ColorTMP;
	local Array<String> MessageOfTheDayLines;

	PC = GetPlayer();
	if (GetKFGRI() == None)
	{
		return;
	}
	else if (PlayersList != None)
	{
		if (KFGRI.MaxHumanCount > CompactModePlayers)
		{
			ListItems     = ListItemsCompact;
			FontScalarMod = FontScalarModCompact;
		}
		else
		{
			ListItems     = ListItemsDefault;
			FontScalarMod = FontScalarModDefault;
		}
		PlayersList.ListItemsPerPage = ListItems;
	}

	// Sort player list.
	if (NextScoreboardRefresh < PC.WorldInfo.TimeSeconds)
	{
		NextScoreboardRefresh = PC.WorldInfo.TimeSeconds + 0.1;

		for (i=(KFGRI.PRIArray.Length-1); i > 0; --i)
		{
			for (j=i-1; j >= 0; --j)
			{
				if (!InOrder(KFPlayerReplicationInfo(KFGRI.PRIArray[i]), KFPlayerReplicationInfo(KFGRI.PRIArray[j])))
				{
					PRI = KFGRI.PRIArray[i];
					KFGRI.PRIArray[i] = KFGRI.PRIArray[j];
					KFGRI.PRIArray[j] = PRI;
				}
			}
		}
	}

	// Check players.
	PlayerIndex = -1;
	NumPlayer = 0;
	for (i=(KFGRI.PRIArray.Length-1); i >= 0; --i)
	{
		KFPRI = KFPlayerReplicationInfo(KFGRI.PRIArray[i]);
		if (KFPRI == None)
			continue;
		if (KFPRI.bOnlySpectator)
		{
			++NumSpec;
			continue;
		}
		if (KFPRI.PlayerHealth > 0 && KFPRI.PlayerHealthPercent > 0 && KFPRI.GetTeamNum() == 0)
			++NumAlivePlayer;
		++NumPlayer;
	}

	KFPRIArray.Length = NumPlayer;
	j = KFPRIArray.Length;
	for (i=(KFGRI.PRIArray.Length-1); i >= 0; --i)
	{
		KFPRI = KFPlayerReplicationInfo(KFGRI.PRIArray[i]);
		if (KFPRI != None && !KFPRI.bOnlySpectator)
		{
			KFPRIArray[--j] = KFPRI;
			if (KFPRI == PC.PlayerReplicationInfo)
				PlayerIndex = j;
		}
	}

	Canvas.Font = Owner.CurrentStyle.PickFont(FontScalar);
	Canvas.TextSize("ABC", XL, YL, FontScalar, FontScalar);
	BorderSize = Owner.HUDOwner.ScaledBorderSize;
	EdgeSize = Owner.CurrentStyle.PickEdgeSize();

	// Server Info
	XPosCenter = Canvas.ClipX * 0.5;
	Width = Canvas.ClipX * HeaderWidthRatio; // Full Box Width
	XPos = XPosCenter - Width * 0.5;
	YPos = YL;

	BoxW = Width;
	BoxX = XPos;
	BoxH = YL + BorderSize;

	// Top Rect (Server name)
	Canvas.SetDrawColorStruct(Settings.Style.ServerNameBoxColor);
	Owner.CurrentStyle.DrawRectBox(BoxX, YPos, BoxW, BoxH, EdgeSize, Settings.Style.ShapeServerNameBox);

	Canvas.SetDrawColorStruct(Settings.Style.ServerNameTextColor);
	S = (DynamicServerName == "" ? KFGRI.ServerName : DynamicServerName);
	DrawTextShadowHVCenter(S, BoxX, YPos, BoxW, BoxH, FontScalar);

	// icons
	ColorTMP = Settings.Style.ServerNameTextColor;
	ColorTMP.A = 200;
	Canvas.SetDrawColorStruct(ColorTMP);

	if (PasswordRequired)
	{
		Owner.CurrentStyle.DrawTexture(
			IconPassword,
			BoxX + BorderSize*2,
			YPos + BorderSize*2,
			BoxH - BorderSize*4,
			BoxH - BorderSize*4);
	}

	if (UsesStats)
	{
		//if (Custom)
		//{
		//	Owner.CurrentStyle.DrawTexture(
		//	IconCustom,
		//	BoxX + BorderSize + (BoxW - SrvNameW) * 0.5f - BoxH,
		//	YPos + BorderSize,
		//	BoxH - BorderSize*2,
		//	BoxH - BorderSize*2);
		//}
		//else
		//{
		DrawRankedIcon(
			BoxX + BorderSize*2 + PasswordRequired ? BoxH - BorderSize*2 : 0.f,
			YPos + BorderSize*2,
			BoxH - BorderSize*4,
			BoxH - BorderSize*4);
		//}
	}
	//else
	//{
	//	Owner.CurrentStyle.DrawTexture(
	//		IconUnrankedAlt,
	//		BoxX + BorderSize*2 + PasswordRequired ? BoxH - BorderSize*2 : 0.f,
	//		YPos + BorderSize*2,
	//		BoxH - BorderSize*4,
	//		BoxH - BorderSize*4,
	//		256, 256);
	//}

	YPos += BoxH;

	// Mid Left Rect (Info)
	BoxW = Width * 0.7;
	BoxH = YL * 2 + BorderSize * 2;
	Canvas.SetDrawColorStruct(Settings.Style.GameInfoBoxColor);
	Owner.CurrentStyle.DrawRectBox(BoxX, YPos, BoxW, BoxH, EdgeSize, Settings.Style.ShapeGameInfoBox);

	Canvas.SetDrawColorStruct(Settings.Style.GameInfoTextColor);
	S = class'KFCommon_LocalizedStrings'.static.GetFriendlyMapName(PC.WorldInfo.GetMapName(true));
	DrawTextShadowHLeftVCenter(S, BoxX + EdgeSize, YPos, BoxH/2, FontScalar);

	S = KFGRI.GameClass.default.GameName $ " - " $ class'KFCommon_LocalizedStrings'.Static.GetDifficultyString(KFGRI.GameDifficulty);
	DrawTextShadowHLeftVCenter(S, BoxX + EdgeSize, YPos + BoxH/2, BoxH/2, FontScalar);

	// Mid Right Rect (Wave)
	BoxX = BoxX + BoxW;
	BoxW = Width - BoxW;
	Canvas.SetDrawColorStruct(Settings.Style.WaveBoxColor);
	Owner.CurrentStyle.DrawRectBox(BoxX, YPos, BoxW, BoxH, EdgeSize, Settings.Style.ShapeWaveInfoBox);

	Canvas.SetDrawColorStruct(Settings.Style.WaveTextColor);
	S = class'KFGFxHUD_ScoreboardMapInfoContainer'.default.WaveString;
	DrawTextShadowHVCenter(S, BoxX, YPos, BoxW, BoxH / 2, FontScalar);
	DrawTextShadowHVCenter(WaveText(), BoxX, YPos + BoxH / 2, BoxW, BoxH / 2, FontScalar);

	YPos += BoxH;

	// Bottom Rect (Players count)
	BoxX = XPos;
	BoxW = Width;
	BoxH = YL + BorderSize;
	Canvas.SetDrawColorStruct(Settings.Style.PlayerCountBoxColor);
	Owner.CurrentStyle.DrawRectBox(BoxX, YPos, BoxW, BoxH, EdgeSize, Settings.Style.ShapePlayersCountBox);

	/*
	Owner.CurrentStyle.DrawTexture(IconPlayer,
		BoxX + EdgeSize + IconIndent,
		YPos + IconIndent,
		BoxH - IconIndent*2,
		BoxH - IconIndent*2,
		MakeColor(250,250,250,250));
	*/

	Canvas.SetDrawColorStruct(Settings.Style.PlayerCountTextColor);
	S = LocalMessage.static.GetLocalizedString(YAS_Players) $ ":"
		@ NumPlayer @ "/" @ KFGRI.MaxHumanCount $ "    "
		$ LocalMessage.static.GetLocalizedString(YAS_Spectators) $ ": " $ NumSpec; ;
	Canvas.TextSize(S, XL, YL, FontScalar, FontScalar);
	DrawTextShadowHLeftVCenter(S, BoxX + EdgeSize, YPos, BoxH, FontScalar);

	S = Owner.CurrentStyle.GetTimeString(KFGRI.ElapsedTime);
	DrawTextShadowHVCenter(S, XPos + Width * 0.7, YPos, Width * 0.3, BoxH, FontScalar);

	YPos += BoxH;

	// Header
	Width = Canvas.ClipX * PlayerListWidthRatio;
	XPos = (Canvas.ClipX - Width) * 0.5;
	YPos += YL;
	BoxH = YL + BorderSize;
	Canvas.SetDrawColorStruct(Settings.Style.ListHeaderBoxColor);
	Owner.CurrentStyle.DrawRectBox(
		XPos - BorderSize * 2,
		YPos,
		Width + BorderSize * 4,
		BoxH,
		EdgeSize,
		Settings.Style.ShapeHeaderBox);

	// Calc X offsets
	MinBoxW = Width * 0.07; // minimum width for column

	// Health
	HealthXPos = 0;
	BoxW = 0;
	Canvas.TextSize("0000", BoxW, YL, FontScalar, FontScalar);
	HealthWBox = BoxW + BorderSize * 2;
	if (HealthWBox < PlayersList.GetItemHeight())
	{
		HealthWBox = PlayersList.GetItemHeight();
	}

	PlayerXPos = HealthXPos + HealthWBox + PlayersList.GetItemHeight() + EdgeSize;

	Canvas.TextSize(class'KFGFxHUD_ScoreboardWidget'.default.PingString$" ", XL, YL, FontScalar, FontScalar);
	PingWBox = XL < MinBoxW ? MinBoxW : XL;
	if (NumPlayer <= PlayersList.ListItemsPerPage)
		ScrollBarWidth = 0;
	else
		ScrollBarWidth = BorderSize * 8;
	PingXPos = Width - PingWBox - ScrollBarWidth;

	Canvas.TextSize(class'KFGFxHUD_ScoreboardWidget'.default.AssistsString$" ", XL, YL, FontScalar, FontScalar);
	AssistWBox = XL < MinBoxW ? MinBoxW : XL;
	AssistXPos = PingXPos - AssistWBox;

	Canvas.TextSize(class'KFGFxHUD_ScoreboardWidget'.default.KillsString$" ", XL, YL, FontScalar, FontScalar);
	KillsWBox = XL < MinBoxW ? MinBoxW : XL;
	KillsXPos = AssistXPos - KillsWBox;

	Canvas.TextSize(class'KFGFxHUD_ScoreboardWidget'.default.DoshString$" ", XL, YL, FontScalar, FontScalar);
	Canvas.TextSize("999999", DoshSize, YL, FontScalar, FontScalar);
	DoshWBox = XL < DoshSize ? DoshSize : XL;
	DoshXPos = KillsXPos - DoshWBox;

	BoxW = MinPerkBoxWidth(FontScalar);
	PerkWBox = BoxW < MinBoxW ? MinBoxW : BoxW;
	PerkXPos = DoshXPos - PerkWBox;

	Canvas.TextSize("000", XL, YL, FontScalar, FontScalar);
	LevelWBox = XL;
	LevelXPos = PerkXPos - LevelWBox;

	// Header texts
	Canvas.SetDrawColorStruct(Settings.Style.ListHeaderTextColor);
	DrawTextShadowHLeftVCenter(class'KFGFxHUD_ScoreboardWidget'.default.PlayerString, XPos + PlayerXPos, YPos, BoxH, FontScalar);
	DrawTextShadowHLeftVCenter(class'KFGFxMenu_Inventory'.default.PerkFilterString, XPos + PerkXPos, YPos, BoxH, FontScalar);
	DrawTextShadowHVCenter(class'KFGFxHUD_ScoreboardWidget'.default.KillsString, XPos + KillsXPos, YPos, KillsWBox, BoxH, FontScalar);
	if (ShowDamage)
	{
		DrawTextShadowHVCenter(class'KFGFxTraderContainer_ItemDetails'.default.DamageTitle, XPos + AssistXPos, YPos, AssistWBox, BoxH, FontScalar);
	}
	else
	{
		DrawTextShadowHVCenter(class'KFGFxHUD_ScoreboardWidget'.default.AssistsString, XPos + AssistXPos, YPos, AssistWBox, BoxH, FontScalar);
	}
	DrawTextShadowHVCenter(class'KFGFxHUD_ScoreboardWidget'.default.DoshString, XPos + DoshXPos, YPos, DoshWBox, BoxH, FontScalar);
	DrawTextShadowHVCenter(class'KFGFxHUD_ScoreboardWidget'.default.PingString, XPos + PingXPos, YPos, PingWBox, BoxH, FontScalar);

	ColorTMP = Settings.Style.ListHeaderTextColor;
	ColorTMP.A = 150;
	Canvas.SetDrawColorStruct(ColorTMP);
	Owner.CurrentStyle.DrawTexture(
		IconHealthAlt,
		XPos + HealthXPos + BoxH * 0.5f,
		YPos + BorderSize,
		BoxH - BorderSize * 2,
		BoxH - BorderSize * 2,
		256,
		256);

	PlayersList.XPosition = ((Canvas.ClipX - Width) * 0.5) / InputPos[2];
	PlayersList.YPosition = (YPos + YL + BorderSize * 4) / InputPos[3];
	PlayersList.YSize = (1.f - PlayersList.YPosition) - 0.15;

	PlayersList.ChangeListSize(KFPRIArray.Length);

	PlayerListSizeY = PlayersList.GetItemHeight() * PlayerEntryHeightMod * (NumPlayer <= PlayersList.ListItemsPerPage ? NumPlayer : PlayersList.ListItemsPerPage);

	PlayerListSizeY -= PlayersList.GetItemHeight() * PlayerEntryHeightMod - PlayersList.GetItemHeight();

	// Scroll bar (fake)
	// This is an imitation of a scroll bar
	// just to let people know that they can scroll the mouse wheel.
	// This interface already has a scroll bar,
	// but I haven't figured out how to use it yet.
	// I hope this can be replaced later
	if (NumPlayer > PlayersList.ListItemsPerPage)
	{
		Canvas.SetDrawColorStruct(Settings.Style.ListHeaderBoxColor);
		Owner.CurrentStyle.DrawRectBox(
			XPos + PlayersList.GetWidth() - ScrollBarWidth,
			YPos + YL + BorderSize * 4,
			ScrollBarWidth,
			PlayerListSizeY,
			EdgeSize,
			0);
	}

	// MessageOfTheDay
	MessageOfTheDayLines = SplitString(MessageOfTheDay, "\n");

	YPos += BoxH + BorderSize * 6 + PlayerListSizeY;
	Width = Canvas.ClipX * PlayerListWidthRatio;
	BoxH = YL + BorderSize;
	Canvas.SetDrawColorStruct(Settings.Style.ListHeaderBoxColor);
	Owner.CurrentStyle.DrawRectBox(
		XPos - BorderSize * 2,
		YPos,
		Width + BorderSize * 4,
		BoxH * (MessageOfTheDayLines.Length > 0 ? MessageOfTheDayLines.Length : 1),
		EdgeSize,
		152);

	if (MessageOfTheDay != "")
	{
		Canvas.SetDrawColorStruct(Settings.Style.ListHeaderTextColor);
		foreach MessageOfTheDayLines(S)
		{
			DrawTextShadowHVCenter(S, XPos - BorderSize * 2, YPos, Width + BorderSize * 4, BoxH, FontScalar);
			YPos += BoxH;
		}
	}
}

function DrawPlayerEntry(Canvas C, int Index, float YOffset, float Height, float Width, bool bFocus)
{
	local string S, StrValue;
	local float FontScalar, XL, YL, PerkIconPosX, PerkIconPosY, PerkIconSize, PrestigeIconScale;
	local float XPos, BoxWidth, RealPlayerWBox;
	local KFPlayerReplicationInfo KFPRI;
	local YAS_RepInfoPlayer RepInfo;
	local byte Level, PrestigeLevel;
	local Color ColorTMP;
	local bool bIsZED;
	local int Ping;
	local Rank Rank;

	local float BorderSize, EdgeSize;

	local int Shape, ShapeHealth;

	local Color HealthBoxColor;

	BorderSize = Owner.HUDOwner.ScaledBorderSize;
	EdgeSize = Owner.CurrentStyle.PickEdgeSize();

	YOffset *= PlayerEntryHeightMod;

	KFPRI = KFPRIArray[Index];

	RepInfo = FindRepInfo(KFPRI);
	Rank = PlayerRank(RepInfo, KFPRI.bAdmin);

	if (KFGRI.bVersusGame)
	{
		bIsZED = KFTeamInfo_Zeds(KFPRI.Team) != None;
	}

	XPos = 0.f;

	C.Font = Owner.CurrentStyle.PickFont(FontScalar);

	FontScalar *= FontScalarMod;
	Canvas.TextSize("ABC", XL, YL, FontScalar, FontScalar);

	ShapeHealth = Settings.Style.ShapeStateHealthBoxMidPlayer;

	if (!(KFGRI.bMatchHasBegun || KFGRI.bTraderIsOpen || KFGRI.bWaveIsActive))
	{
		HealthBoxColor = Settings.Style.StateBoxColorLobby;
	}
	else if (KFPRI.PlayerHealth <= 0 || KFPRI.PlayerHealthPercent <= 0)
	{
		HealthBoxColor = Settings.Style.StateBoxColorDead;
	}
	else
	{
		HealthBoxColor = HealthColorByPercent(ByteToFloat(KFPRI.PlayerHealthPercent));
	}

	// Health box
	C.SetDrawColorStruct(HealthBoxColor);
	Owner.CurrentStyle.DrawRectBox(
		XPos,
		YOffset,
		HealthWBox,
		Height,
		EdgeSize,
		ShapeHealth);

	if (!(KFGRI.bMatchHasBegun || KFGRI.bTraderIsOpen || KFGRI.bWaveIsActive))
	{
		ColorTMP = Settings.Style.ListHeaderTextColor;
		ColorTMP.A = 200;
		Canvas.SetDrawColorStruct(ColorTMP);
		Owner.CurrentStyle.DrawTexture(
			IconHorzine,
			XPos + (HealthWBox - Height) * 0.5f + BorderSize * 2,
			YOffset + BorderSize * 2,
			Height - BorderSize * 4,
			Height - BorderSize * 4);
	}
	else if (KFPRI.PlayerHealth <= 0 || KFPRI.PlayerHealthPercent <= 0)
	{
		ColorTMP = Settings.Style.ListHeaderTextColor;
		ColorTMP.A = 200;
		Canvas.SetDrawColorStruct(ColorTMP);
		Owner.CurrentStyle.DrawTexture(
			IconSkullAlt,
			XPos + BorderSize * 2,
			YOffset + BorderSize * 2,
			HealthWBox - BorderSize * 4,
			Height - BorderSize * 4);
	}
	else
	{
		C.SetDrawColorStruct(Settings.Style.StateTextColorHealthHigh);
		DrawTextShadowHVCenter(String(KFPRI.PlayerHealth), HealthXPos, YOffset, HealthWBox, Height, FontScalar);
	}

	XPos += HealthWBox;

	// PlayerBox
	if (PlayerIndex == Index)
		C.SetDrawColorStruct(Settings.Style.PlayerOwnerBoxColor);
	else
		C.SetDrawColorStruct(Settings.Style.PlayerBoxColor);

	Shape = Settings.Style.ShapePlayerBoxMidPlayer;

	BoxWidth = DoshXPos - HealthWBox - BorderSize * 2;
	Owner.CurrentStyle.DrawRectBox(XPos, YOffset, BoxWidth, Height, EdgeSize, Shape);

	XPos += BoxWidth;

	// Right stats box
	Shape = Settings.Style.ShapeStatsBoxMidPlayer;

	BoxWidth = Width - XPos;
	C.SetDrawColorStruct(Settings.Style.StatsBoxColor);
	Owner.CurrentStyle.DrawRectBox(
		XPos,
		YOffset,
		BoxWidth,
		Height,
		EdgeSize,
		Shape);

	// Perk
	RealPlayerWBox = PlayerWBox;
	if (bIsZED)
	{
		C.SetDrawColorStruct(Settings.Style.ZedTextColor);
		C.SetPos (PerkXPos, YOffset - ((Height-5) * 0.5f));
		C.DrawRect (Height-5, Height-5, Texture2D'UI_Widgets.MenuBarWidget_SWF_IF');

		S = class'KFCommon_LocalizedStrings'.default.ZedString;
		DrawTextShadowHLeftVCenter(S, PerkXPos + Height, YOffset, Height, FontScalar);
		RealPlayerWBox = PerkXPos + Height - PlayerXPos;
	}
	else
	{
		if (KFPRI.CurrentPerkclass != None)
		{
			PrestigeLevel = KFPRI.GetActivePerkPrestigeLevel();
			Level = KFPRI.GetActivePerkLevel();

			PerkIconPosY = YOffset + (BorderSize * 2);
			PerkIconSize = Height-(BorderSize * 4);
			PerkIconPosX = LevelXPos - PerkIconSize - (BorderSize*2);
			PrestigeIconScale = 0.6625f;

			RealPlayerWBox = PerkIconPosX - PlayerXPos;

			C.DrawColor = HUDOwner.WhiteColor;
			if (PrestigeLevel > 0)
			{
				C.SetPos(PerkIconPosX, PerkIconPosY);
				C.DrawTile(KFPRI.CurrentPerkClass.default.PrestigeIcons[PrestigeLevel - 1], PerkIconSize, PerkIconSize, 0, 0, 256, 256);

				C.SetPos(PerkIconPosX + ((PerkIconSize/2) - ((PerkIconSize*PrestigeIconScale)/2)), PerkIconPosY + ((PerkIconSize/2) - ((PerkIconSize*PrestigeIconScale)/1.75)));
				C.DrawTile(KFPRI.CurrentPerkClass.default.PerkIcon, PerkIconSize * PrestigeIconScale, PerkIconSize * PrestigeIconScale, 0, 0, 256, 256);
			}
			else
			{
				C.SetPos(PerkIconPosX, PerkIconPosY);
				C.DrawTile(KFPRI.CurrentPerkClass.default.PerkIcon, PerkIconSize, PerkIconSize, 0, 0, 256, 256);
			}


			if (Level < Settings.Level.Low[KFGRI.GameDifficulty])
				C.SetDrawColorStruct(Settings.Style.LevelTextColorLow);
			else if (Level < Settings.Level.High[KFGRI.GameDifficulty])
				C.SetDrawColorStruct(Settings.Style.LevelTextColorMid);
			else
				C.SetDrawColorStruct(Settings.Style.LevelTextColorHigh);

			S = String(Level);
			DrawTextShadowHLeftVCenter(S, LevelXPos, YOffset, Height, FontScalar);

			C.SetDrawColorStruct(Settings.Style.PerkNoneTextColor);
			S = KFPRI.CurrentPerkClass.default.PerkName;
			DrawTextShadowHLeftVCenter(S, PerkXPos, YOffset, Height, FontScalar);
		}
		else
		{
			C.SetDrawColorStruct(Settings.Style.PerkNoneTextColor);
			S = "";
			DrawTextShadowHLeftVCenter(S, PerkXPos, YOffset, Height, FontScalar);
			RealPlayerWBox = PerkXPos - PlayerXPos;
		}
	}

	// Rank
	if (Rank.RankName != "")
	{
		C.SetDrawColorStruct(Rank.RankColor);
		DrawTextShadowHRightVCenter(Rank.RankName, PlayerXPos, YOffset, PerkIconPosX - PlayerXPos - (BorderSize * 4), Height, FontScalar);
	}

	// Avatar
	if (KFPRI.Avatar == None || (!KFPRI.bBot && KFPRI.Avatar == default.DefaultAvatar))
	{
		CheckAvatar(KFPRI, OwnerPC);
	}

	if (KFPRI.Avatar != None)
	{
		C.SetDrawColor(255, 255, 255, 255);
		C.SetPos(PlayerXPos - (Height * 1.075), YOffset + (Height * 0.5f) - ((Height - 6) * 0.5f));
		C.DrawTile(KFPRI.Avatar, Height - 6, Height - 6, 0,0, KFPRI.Avatar.SizeX, KFPRI.Avatar.SizeY);
		Owner.CurrentStyle.DrawBoxHollow(PlayerXPos - (Height * 1.075), YOffset + (Height * 0.5f) - ((Height - 6) * 0.5f), Height - 6, Height - 6, 1);
	}

	// Player
	C.SetDrawColorStruct(Rank.PlayerColor);
	S = KFPRI.PlayerName;
	Canvas.TextSize(S, XL, YL, FontScalar, FontScalar);
	while (XL > RealPlayerWBox)
	{
		S = Left(S, Len(S)-1);
		Canvas.TextSize(S, XL, YL, FontScalar, FontScalar);
	}
	DrawTextShadowHLeftVCenter(S, PlayerXPos, YOffset, Height, FontScalar);

	// Kill
	C.SetDrawColorStruct(Settings.Style.KillsTextColorMid);
	DrawTextShadowHVCenter(GetNiceSize(KFPRI.Kills), KillsXPos, YOffset, KillsWBox, Height, FontScalar);

	// Assist
	C.SetDrawColorStruct(Settings.Style.AssistsTextColorMid);
	if (ShowDamage)
	{
		DrawTextShadowHVCenter((RepInfo == None ? "0" : GetNiceSize(RepInfo.DamageDealt)), AssistXPos, YOffset, AssistWBox, Height, FontScalar);
	}
	else
	{
		DrawTextShadowHVCenter(GetNiceSize(KFPRI.Assists), AssistXPos, YOffset, AssistWBox, Height, FontScalar);
	}

	// Dosh
	if (bIsZED)
	{
		C.SetDrawColorStruct(Settings.Style.ZedTextColor);
		StrValue = "-";
	}
	else
	{
		C.SetDrawColorStruct(Settings.Style.DoshTextColorMid);
		StrValue = GetNiceSize(int(KFPRI.Score));
	}
	DrawTextShadowHVCenter(StrValue, DoshXPos, YOffset, DoshWBox, Height, FontScalar);

	// Ping
	if (KFPRI.bBot)
	{
		C.SetDrawColorStruct(Settings.Style.PingTextColorNone);
		S = "-";
	}
	else
	{
		Ping = int(KFPRI.Ping * `PING_SCALE);
		C.SetDrawColorStruct(PingColorByPing(Ping));
		S = String(Ping);
	}

	C.TextSize(S, XL, YL, FontScalar, FontScalar);
	DrawTextShadowHVCenter(S, PingXPos, YOffset, PingWBox/2, Height, FontScalar);
	C.SetDrawColor(250, 250, 250, 255);
	DrawPingBars(C, YOffset + (Height/2) - ((Height*0.5)/2), Width - (Height*0.5) - (BorderSize*2), Height*0.5, Height*0.5, float(Ping));
}

final function DrawPingBars(Canvas C, float YOffset, float XOffset, float W, float H, float Ping)
{
	local float PingMul, BarW, BarH, BaseH, XPos, YPos;
	local byte i;

	PingMul = 1.f - FClamp(FMax(Ping - 30, 1.f) / 130, 0.f, 1.f);
	BarW = W / PingBars;
	BaseH = H / PingBars;

	for (i=1; i < PingBars; i++)
	{
		BarH = BaseH * i;
		XPos = XOffset + ((i - 1) * BarW);
		YPos = YOffset + (H - BarH);

		C.SetPos(XPos, YPos);
		C.SetDrawColor(20, 20, 20, 255);
		Owner.CurrentStyle.DrawWhiteBox(BarW, BarH);

		if (PingMul >= (i / PingBars))
		{
			C.SetPos(XPos, YPos);
			C.SetDrawColorStruct(PingColorByPing(Ping));
			Owner.CurrentStyle.DrawWhiteBox(BarW, BarH);
		}

		C.SetDrawColor(80, 80, 80, 255);
		Owner.CurrentStyle.DrawBoxHollow(XPos, YPos, BarW, BarH, 1);
	}
}

static final function Texture2D FindAvatar(KFPlayerController PC, UniqueNetId ClientID)
{
	local string S;

	S = PC.GetSteamAvatar(ClientID);
	if (S == "")
		return None;
	return Texture2D(PC.FindObject(S, class'Texture2D'));
}

final static function string GetNiceSize(int Num)
{
	if (Num < 10000 ) return string(Num);
	else if (Num < 1000000 ) return (Num / 1000) $ "K";
	else if (Num < 1000000000 ) return (Num / 1000000) $ "M";

	return (Num / 1000000000) $ "B";
}

function ScrollMouseWheel(bool bUp)
{
	PlayersList.ScrollMouseWheel(bUp);
}

function Color HealthColorByPercent(float FloatPercent)
{
	local Color CRED, CYLW, CGRN, RV;

	CRED = MakeColor(200, 0, 0, 150);
	CYLW = MakeColor(200, 200, 0, 150);
	CGRN = MakeColor(0, 200, 0, 150);

	if (FloatPercent >= 0.9f)
	{
		RV = CGRN;
	}
	else if (FloatPercent >= 0.5f)
	{
		RV = PickDynamicColor(CYLW, CGRN, (FloatPercent - 0.5f) / (0.9f - 0.5f));
	}
	else if (FloatPercent >= 0.1f)
	{
		RV = PickDynamicColor(CRED, CYLW, (FloatPercent - 0.1f) / (0.5f - 0.1f));
	}
	else
	{
		RV = CRED;
	}

	return RV;
}

function Color PingColorByPing(int Ping)
{
	local Color CRED, CYLW, CGRN, RV;

	CRED = MakeColor(200, 0, 0, 250);
	CYLW = MakeColor(200, 200, 0, 250);
	CGRN = MakeColor(0, 200, 0, 250);

	if (Ping < 30)
	{
		RV = CGRN;
	}
	else if (Ping < 70)
	{
		RV = PickDynamicColor(CGRN, CYLW, (Ping - 30) / (70 - 30));
	}
	else if (Ping < 110)
	{
		RV = PickDynamicColor(CYLW, CRED, (Ping - 70) / (110 - 70));
	}
	else
	{
		RV = CRED;
	}

	return RV;
}

function Color PickDynamicColor(Color LowerColor, Color UpperColor, float FloatPercent)
{
	// Color:     Lower                                Upper
	// Percent:    0.0f <------- FloatPercent -------> 1.0f
	return MakeColor((
		LowerColor.R < UpperColor.R ?
		LowerColor.R + ((UpperColor.R - LowerColor.R) * FloatPercent) :
		LowerColor.R - ((LowerColor.R - UpperColor.R) * FloatPercent)),
		(
		LowerColor.G < UpperColor.G ?
		LowerColor.G + ((UpperColor.G - LowerColor.G) * FloatPercent) :
		LowerColor.G - ((LowerColor.G - UpperColor.G) * FloatPercent)),
		(
		LowerColor.B < UpperColor.B ?
		LowerColor.B + ((UpperColor.B - LowerColor.B) * FloatPercent) :
		LowerColor.B - ((LowerColor.B - UpperColor.B) * FloatPercent)),
		(
		LowerColor.A < UpperColor.A ?
		LowerColor.A + ((UpperColor.A - LowerColor.A) * FloatPercent) :
		LowerColor.A - ((LowerColor.A - UpperColor.A) * FloatPercent)));
}

function DrawTextShadowHVCenter(string Str, float XPos, float YPos, float BoxWidth, float BoxHeight, float FontScalar)
{
	local float TextWidth;
	local float TextHeight;

	Canvas.TextSize(Str, TextWidth, TextHeight, FontScalar, FontScalar);

	Owner.CurrentStyle.DrawTextShadow(Str, XPos + (BoxWidth - TextWidth)/2 , YPos + (BoxHeight - TextHeight)/2, 1, FontScalar);
}

function DrawTextShadowHLeftVCenter(string Str, float XPos, float YPos, float BoxHeight, float FontScalar)
{
	local float TextWidth;
	local float TextHeight;

	Canvas.TextSize(Str, TextWidth, TextHeight, FontScalar, FontScalar);

	Owner.CurrentStyle.DrawTextShadow(Str, XPos, YPos + (BoxHeight - TextHeight)/2, 1, FontScalar);
}

function DrawTextShadowHRightVCenter(string Str, float XPos, float YPos, float BoxWidth, float BoxHeight, float FontScalar)
{
	local float TextWidth;
	local float TextHeight;

	Canvas.TextSize(Str, TextWidth, TextHeight, FontScalar, FontScalar);

	Owner.CurrentStyle.DrawTextShadow(Str, XPos + BoxWidth - TextWidth, YPos + (BoxHeight - TextHeight)/2, 1, FontScalar);
}

function DrawRankedIcon(float X, float Y, float W, float H)
{
	local int Position;
	local float XPos, YPos, Size, Block;

	Size =  Min(W, H);
	Block = Size * 0.25f;

	for (Position = 0; Position < 2; ++Position)
	{
		XPos = X + (W > Size ? (W - Size) * 0.5f : 0.f);
		YPos = Y + Position * Size * 0.5f;

		// 1
		Canvas.SetPos(XPos, YPos + Block);
		Owner.CurrentStyle.DrawCornerTex(Block, 0);

		// 2
		Canvas.SetPos(XPos + Block, YPos + Block);
		Owner.CurrentStyle.DrawCornerTex(Block, 3);

		// 3
		Canvas.SetPos(XPos + Block, YPos);
		Owner.CurrentStyle.DrawCornerTex(Block, 0);

		// 4
		Canvas.SetPos(XPos + Block * 2, YPos);
		Owner.CurrentStyle.DrawCornerTex(Block, 1);

		// 5
		Canvas.SetPos(XPos + Block * 2, YPos + Block);
		Owner.CurrentStyle.DrawCornerTex(Block, 2);

		// 6
		Canvas.SetPos(XPos + Block * 3, YPos + Block);
		Owner.CurrentStyle.DrawCornerTex(Block, 1);
	}
}

defaultproperties
{
	bEnableInputs=true

	PingColor=(R=255, G=255, B=60, A=255)
	PingBars=5.0

	Begin Object Class=KFGUI_List Name=PlayerList
		XSize=PlayerListWidthRatio
		OnDrawItem=DrawPlayerEntry
		ID="PlayerList"
		bClickable=false
		ListItemsPerPage=ListItemsDefault
	End Object
	Components.Add(PlayerList)

	DefaultAvatar=Texture2D'UI_HUD.ScoreBoard_Standard_SWF_I26'
}