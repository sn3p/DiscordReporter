class DiscordReporterMutator_1on1 extends Mutator;

var DiscordReporterLink Link;
var DiscordReporterStats_1on1 Stats;
var DiscordReporterConfig conf;

function bool HandlePickupQuery(Pawn Other, Inventory item, out byte bAllowPickup)
{
	local PlayerReplicationInfo PRI;

	PRI = Other.PlayerReplicationInfo;

	if (Item.IsA('ThighPads'))
		Stats.SendMessage(PRI.PlayerName @ "has picked up" @ "ThighPads.");
	else if (Item.IsA('Armor2'))
		Stats.SendMessage(PRI.PlayerName @ "has picked up an" @ "Armor.");
	else if (Item.IsA('UT_Jumpboots'))
		Stats.SendMessage(PRI.PlayerName @ "has picked up" @ "Jumpboots.");
	else if (Item.IsA('UT_Shieldbelt'))
		Stats.SendMessage(PRI.PlayerName @ "has picked up a" @ "Shieldbelt.");
	else if (Item.IsA('HealthPack'))
		Stats.SendMessage(PRI.PlayerName @ "has picked up a" @ "HealthPack.");

	if (NextMutator != None)
		return NextMutator.HandlePickupQuery(Other, item, bAllowPickup);
}

defaultproperties
{
}
