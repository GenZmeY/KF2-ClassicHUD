class YAS_LocalMessage extends Object
	abstract;

var const             String PlayersDefault;
var private localized String Players;

var const             String SpectatorsDefault;
var private localized String Spectators;

enum E_YAS_LocalMessageType
{
	YAS_Players,
	YAS_Spectators
};

public static function String GetLocalizedString(E_YAS_LocalMessageType LMT)
{
	switch (LMT)
	{
		case YAS_Players:
			return (default.Players != "" ? default.Players : default.PlayersDefault);

		case YAS_Spectators:
			return (default.Spectators != "" ? default.Spectators : default.SpectatorsDefault);
	}

	return "";
}

defaultproperties
{
	PlayersDefault    = "Players"
	SpectatorsDefault = "Spectators"
}
