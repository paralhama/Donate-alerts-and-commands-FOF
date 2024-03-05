#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define MAX_WEAPONS 26
#define TNT_BARREL_MODEL "models/elpaso/barrel2_explosive.mdl"
#define SOUND_ALERT "halloween/ragged_powerup.wav"

// new largeTntBarrel[MAXPLAYERS];

new String:weapon[32] = "";
new deadPlayers[MAXPLAYERS];
new numDeadPlayersGive1 = 0;
new numDeadPlayersGive2 = 0;
new numDeadPlayersGiveTnt = 0;
new iAmmoOffset = -1;

public Plugin:myinfo = {
    name = "Donation alert and commands [FOF]",
    author = "Paralhama",
    description = "Show a donation message from players and some other commands",
    version = "1.0",
    url = "https://farwest.com.br/comandos/"
};

new const String:g_weapons[MAX_WEAPONS][] = {
    "knife", "axe", "machete", "deringer", "hammerless", "volcanic", "coltnavy", "maresleg", "remington_army",
    "schofield", "peacemaker", "walker", "sawedoff_shotgun", "coachgun", "shotgun", "bow", "bow_black", "xbow",
    "carbine", "henryrifle", "spencer", "sharps", "dynamite", "dynamite_belt", "dynamite_black", "ghostgun"
};

public OnPluginStart()
{
	PrecacheSound(SOUND_ALERT, true); 
	// Comando abaixo temporariamente desativado, não consigo fazer o barril aparecer sempre na frente do jogador :/
	// RegAdminCmd("sm_barrel", SpawnLargeTntBarrelToAll, ADMFLAG_ROOT, "Give a large barrel TNT to all players");
	// Se for reativar lembrar de remover comentário "new largeTntBarrel[MAXPLAYERS];" No começo do código
	RegAdminCmd("sm_alert", Cmd_Alert, ADMFLAG_ROOT, "Prints something with formatting and colors");
	RegAdminCmd("sm_tnt", Give100tntAll, ADMFLAG_ROOT, "<tntname> - Gives 100 TNT to all players");
	RegAdminCmd("sm_give", Give1WeaponAll, ADMFLAG_ROOT, "<weaponname> - Gives a weapon to all players");
	RegAdminCmd("sm_give2", Give2WeaponAll, ADMFLAG_ROOT, "<weaponname> - Gives two weapons to all players");
	RegAdminCmd("sm_givelist", WeaponList, ADMFLAG_ROOT, "- List of the weapon names");
	RegAdminCmd("sm_infinite_peacemaker", InfinitePeacemaker, ADMFLAG_ROOT, "Gives two infinite peacemakers for 35 seconds");
	HookEvent("player_spawn", Event_PlayerSpawn);
	iAmmoOffset = FindSendPropInfo( "CFoF_Player", "m_iAmmo" );
}

public Action:Cmd_Alert(client, args){
	if(args<1){
		ReplyToCommand(client, "[SM] Usage: sm_alert <color> <text> \nExample: !print {red}Hello World! \nYou can use \\n to write in a new line");
		return Plugin_Handled;
	}
	decl String:str[512];
	GetCmdArgString(str, sizeof(str));

	// Substituir \n por uma quebra de linha real
	ReplaceString(str, sizeof(str), "\\n", "\n");

	EmitSoundToAll(SOUND_ALERT);
	CPrintToChatAll(str);
	return Plugin_Handled;
}

public Action:WeaponList(id, args)
{
	new i;
	for (i = 0; i < MAX_WEAPONS; ++i)
		ReplyToCommand(id, "%s", g_weapons[i]);

	ReplyToCommand(id, "");
	ReplyToCommand(id, "* Type sm_give <weaponname> or sm_give2 <weaponname>");

	return Plugin_Handled;
}

public Action:Give100tntAll(id, args)
{
	if (args < 1)
	{
		ReplyToCommand(id, "[SM] Usage: sm_tnt <tntname> (without 'weapon_')\nGives 100 TNT to all players\nType !givelist to see the dynamites list!");
		return Plugin_Handled;
	}

	decl String:WeaponName[32];
	GetCmdArgString(WeaponName, sizeof(WeaponName));

	// Construindo o nome da arma
	Format(weapon, sizeof(weapon), "weapon_%s", WeaponName);

	new i;

	// Itera sobre os jogadores para dar a arma
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
		{
			// Se o jogador estiver morto, registre-o para distribuição posterior
			deadPlayers[numDeadPlayersGiveTnt] = i;
			numDeadPlayersGiveTnt++;
			continue;
		}

		// Se o jogador estiver vivo, dê a arma imediatamente
		GivePlayerItem(i, weapon);
		FakeClientCommandEx(i, "use %s", weapon);
		new weaponindex = GetEntPropEnt(i, Prop_Data, "m_hActiveWeapon");
		SetAmmo(i, weaponindex, 100);
	}

	return Plugin_Handled;
}

stock SetAmmo( iClient, iWeapon, iAmmo )
{
    if( 0 < iClient <= MaxClients && IsClientInGame( iClient ) )
    {
        new Handle:hPack;
        CreateDataTimer( 0.1, Timer_SetAmmo, hPack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE );
        WritePackCell( hPack, GetClientUserId( iClient ) );
        WritePackCell( hPack, EntIndexToEntRef( iWeapon ) );
        WritePackCell( hPack, iAmmo );
    }
}
public Action:Timer_SetAmmo( Handle:hTimer, Handle:hPack )
{
    ResetPack( hPack );

    if( iAmmoOffset <= 0 )
        return Plugin_Stop;

    new iClient = GetClientOfUserId( ReadPackCell( hPack ) );
    if( !( 0 < iClient <= MaxClients && IsClientInGame( iClient ) && IsPlayerAlive( iClient ) ) )
        return Plugin_Stop;

    new iWeapon = EntRefToEntIndex( ReadPackCell( hPack ) );
    if( iWeapon <= MaxClients || !IsValidEdict( iWeapon ) )
        return Plugin_Stop;

    SetEntData( iClient, iAmmoOffset + GetEntProp( iWeapon, Prop_Send, "m_iPrimaryAmmoType" ) * 4, ReadPackCell( hPack ) );
    return Plugin_Stop;
}

public Action:Give100DeadPlayersTnt(Handle:timer)
{
	new i;
	for (i = 0; i < MAXPLAYERS; i++)
	{
		new playerID = deadPlayers[i];
		if (playerID == 0)
			continue;

		if (IsPlayerAlive(playerID))
		{
			// Se o jogador reviver, dê a arma
			GivePlayerItem(playerID, weapon);
			FakeClientCommandEx(playerID, "use %s", weapon);
			new weaponindex = GetEntPropEnt(playerID, Prop_Data, "m_hActiveWeapon");
			SetAmmo(playerID, weaponindex, 100);

			// Remova o jogador da lista de jogadores mortos
			deadPlayers[i] = 0;
		}
	}
	return Plugin_Handled;
}

public Action:Give1WeaponAll(id, args)
{
    if (args < 1)
    {
        ReplyToCommand(id, "[SM] Usage: sm_give <weaponname> (without 'weapon_')\nGives a specific weapon to all players\nType !givelist to see the weapons list!");
        return Plugin_Handled;
    }
    
    decl String:WeaponName[32];
    GetCmdArgString(WeaponName, sizeof(WeaponName));

    // Construindo o nome da arma
    Format(weapon, sizeof(weapon), "weapon_%s", WeaponName);

    new i;

    // Itera sobre os jogadores para dar a arma
    for (i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        if (!IsPlayerAlive(i))
        {
            // Se o jogador estiver morto, registre-o para distribuição posterior
            deadPlayers[numDeadPlayersGive1] = i;
            numDeadPlayersGive1++;
            continue;
        }

        // Se o jogador estiver vivo, dê a arma imediatamente
        GivePlayerItem(i, weapon);
        FakeClientCommandEx(i, "use %s", weapon);
    }

    return Plugin_Handled;
}

public Action:Give1DeadPlayersWeapon(Handle:timer)
{
    new i;
    for (i = 0; i < MAXPLAYERS; i++)
    {
        new playerID = deadPlayers[i];
        if (playerID == 0)
            continue;

        if (IsPlayerAlive(playerID))
        {
            // Se o jogador reviver, dê a arma
            GivePlayerItem(playerID, weapon);
            FakeClientCommandEx(playerID, "use %s", weapon);

            // Remova o jogador da lista de jogadores mortos
            deadPlayers[i] = 0;
        }
    }
    return Plugin_Handled;
}

public Action:Give2WeaponAll(id, args)
{
	if (args < 1)
	{
		ReplyToCommand(id, "[SM] Usage: sm_give2 <weaponname> (without 'weapon_')\nGives two specific weapons to all players\nType !givelist to see the weapons list!");
		return Plugin_Handled;
	}

	decl String:WeaponName2[32];
	GetCmdArgString(WeaponName2, sizeof(WeaponName2));

	// Construindo o nome da arma
	Format(weapon, sizeof(weapon), "weapon_%s", WeaponName2);

	// Adiciona o sufixo "2" ao nome da arma
	decl String:weapon2_suffixed[32];
	strcopy(weapon2_suffixed, sizeof(weapon2_suffixed), weapon);
	StrCat(weapon2_suffixed, sizeof(weapon2_suffixed), "2");

	new i;
	// Itera sobre os jogadores para dar a arma
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
		{
			// Se o jogador estiver morto, registre-o para distribuição posterior
			deadPlayers[numDeadPlayersGive2] = i;
			numDeadPlayersGive2++;
			continue;
		}

		GivePlayerItem(i, weapon);
		GivePlayerItem(i, weapon);
		FakeClientCommandEx(i, "use %s", weapon);		
		FakeClientCommandEx(i, "use %s", weapon2_suffixed);
	}
	return Plugin_Handled;
}

public Action:Give2DeadPlayersWeapon(Handle:timer)
{
	new i;
	for (i = 0; i < MAXPLAYERS; i++)
	{
		new playerID = deadPlayers[i];
		if (playerID == 0)
			continue;

		if (IsPlayerAlive(playerID))
		{
			// Adiciona o sufixo "2" ao nome da arma
			decl String:weapon2_suffixed[32];
			strcopy(weapon2_suffixed, sizeof(weapon2_suffixed), weapon);
			StrCat(weapon2_suffixed, sizeof(weapon2_suffixed), "2");

			// Se o jogador reviver, dê a arma
			GivePlayerItem(playerID, weapon);
			GivePlayerItem(playerID, weapon);
			FakeClientCommandEx(playerID, "use %s", weapon);
			FakeClientCommandEx(playerID, "use %s", weapon2_suffixed);

			// Remova o jogador da lista de jogadores mortos
			deadPlayers[i] = 0;
		}
	}
	return Plugin_Handled;
}

public Action:InfinitePeacemaker(id, args)
{
	decl String:ItemPotion[32] = "item_potion";

	new i;
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		SetEntProp(i, Prop_Send, "m_nPotionLevel", 100);
		GivePlayerItem(i, ItemPotion); 
	}

	return Plugin_Handled;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Agendar uma verificação para dar armas aos jogadores mortos assim que reviverem
	if (numDeadPlayersGive1 > 0)
	{
		CreateTimer(0.1, Give1DeadPlayersWeapon);
	}

	if (numDeadPlayersGive2 > 0)
	{
		CreateTimer(0.1, Give2DeadPlayersWeapon);
	}

	if (numDeadPlayersGiveTnt > 0)
	{
		CreateTimer(0.1, Give100DeadPlayersTnt);
	}
}

// Temporariamente desativado, não consigo fazer o barril aparecer sempre na frente do jogador :/
//public Action:SpawnLargeTntBarrelToAll(client, args)
//{
//	//[0] = Position on the X axis ( left and right )
//	//[1] = Position on the Y axis ( front and back )*
//	//[2] = Position on the Z axis ( up and down )
//
//	new i;
//	for (i = 1; i <= MaxClients; i++)
//	{
//		if (!IsClientInGame(i) || !IsPlayerAlive(i))
//			continue;
//
//		new Float:pos[3];
//		GetClientAbsOrigin(i, pos);
//		pos[1] -= 100.0;
//
//		new Float:ang[3];
//		GetClientEyeAngles(i, ang);
//		//ang[1] = ang[1] + 90.0;
//		
//		PrintToChatAll("\x04 Angle: %0.2f %0.2f %0.2f",pos[0],pos[1],pos[2]);
//		PrintToChatAll("\x04 Angle: %0.2f %0.2f %0.2f",ang[0],ang[1],ang[2]);
//
//		largeTntBarrel[i] = CreateEntityByName("prop_physics_multiplayer");
//
//		if (largeTntBarrel[i] == -1) { ReplyToCommand(i, "item failed to create."); return; }
//
//		DispatchKeyValue(largeTntBarrel[i], "model", TNT_BARREL_MODEL);
//		DispatchKeyValue(largeTntBarrel[i], "disableshadows", "1");
//		DispatchKeyValue(largeTntBarrel[i], "spawnflags", "256");
//		DispatchSpawn(largeTntBarrel[i]);
//		TeleportEntity(largeTntBarrel[i], pos, ang, NULL_VECTOR);
//	}
//}
