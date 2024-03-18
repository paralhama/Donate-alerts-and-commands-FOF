#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define MAX_WEAPONS 26
#define SOUND_ALERT "halloween/ragged_powerup.wav"

new String:WeaponGive1[32] = "";   
new deadPlayersGive1[MAXPLAYERS+1];
new numDeadPlayersGive1 = 0;

new String:WeaponGive2[32] = "";
new deadPlayersGive2[MAXPLAYERS+1];
new numDeadPlayersGive2 = 0;

new String:ItemPotion[32] = "item_potion";
new deadPlayersInfinitePeacemaker[MAXPLAYERS+1];
new numDeadInfinitePeacemaker = 0;

new String:WeaponTnt[32] = "";   
new deadPlayers100Tnt[MAXPLAYERS+1];
new numDeadPlayers100Tnt = 0;
new iAmmoOffset = -1;

new String:MeleeWeapon[32] = "";   
new deadPlayersMeleeWeapon[MAXPLAYERS+1];
new numDeadPlayersMeleeWeapon = 0;

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
	RegAdminCmd("sm_alert", Cmd_Alert, ADMFLAG_ROOT, "Prints something with formatting and colors");
	RegAdminCmd("sm_gunslist", GunsList, ADMFLAG_ROOT, "- List of the weapon names");
	RegAdminCmd("sm_givecw", GiveMeleeWeaponAll, ADMFLAG_ROOT, "<melee weapon name> - Gives 20 melee weapon to all players");
	RegAdminCmd("sm_give", Give1WeaponAll, ADMFLAG_ROOT, "<weapon name> - Gives a weapon to all players");
	RegAdminCmd("sm_give2", Give2WeaponAll, ADMFLAG_ROOT, "<weapon name> - Gives two weapons to all players");
	RegAdminCmd("sm_infpm", InfinitePeacemaker, ADMFLAG_ROOT, "Gives two infinite peacemakers for 35 seconds");
	RegAdminCmd("sm_tnt", Give100tntAll, ADMFLAG_ROOT, "<tnt name> - Gives 100 dynamite to all players");
	HookEvent("player_spawn", Event_PlayerSpawn);
	iAmmoOffset = FindSendPropInfo( "CFoF_Player", "m_iAmmo" );
}




// ############################## Donate Alert ##################################
// Exibe o alerta de donate na tela de todos os jogadores
public Action:Cmd_Alert(client, args) {
    if(args < 1) {
        ReplyToCommand(client, "[SM] Usage: sm_alert <color> <text> \nExample: !print {red}Hello World! \nYou can use \\n to write in a new line");
        return Plugin_Handled;
    }

    decl String:str[512];
    GetCmdArgString(str, sizeof(str));

    // Substituir \n por uma quebra de linha real
    ReplaceString(str, sizeof(str), "\\n", "\n");

    // Salvar a mensagem no arquivo de log
    SaveMessageToLog(str);

    EmitSoundToAll(SOUND_ALERT);
    CPrintToChatAll(str);
    return Plugin_Handled;
}

//Remove as TAGs de cor do alerta de donate para depois salvar no log de donates
public void RemoveColorTags(const String:message[], String:filteredMessage[], maxlen) {
    new i = 0, j = 0;
    while (message[i] != '\0' && j < maxlen - 1) {
        if (message[i] == '{') {
            // Ignora todas as tags de cor até encontrar o final da tag
            while (message[i] != '}' && message[i] != '\0') {
                i++;
            }
            // Verifica se a tag de cor foi fechada
            if (message[i] == '}')
                i++; // Avança para o próximo caractere após a tag de cor
        } else {
            filteredMessage[j] = message[i];
            i++;
            j++;
        }
    }
    filteredMessage[j] = '\0'; // Adiciona o caractere nulo no final da string filtrada
}

// Salve o alerta de donate no log
public SaveMessageToLog(const String:message[]) {
	decl String:logPath[PLATFORM_MAX_PATH];
	decl Handle:logFile;
	decl String:FormatedDate[100];
	decl String:FormatedTime[100];
	decl String:filteredMessage[512]; // Define um tamanho máximo para a mensagem filtrada

	new CurrentTime = GetTime();

	FormatTime(FormatedDate, 100, "%d/%m/%Y", CurrentTime);
	FormatTime(FormatedTime, 100, "%X", CurrentTime);

	// Defina o caminho do arquivo de log
	BuildPath(Path_SM, logPath, sizeof(logPath), "logs/donates.log");

	// Abra o arquivo de log para adicionar a mensagem
	logFile = OpenFile(logPath, "a+");

	// Se o arquivo de log foi aberto com sucesso, escreva a mensagem nele
	if(logFile != INVALID_HANDLE) {
		// Filtra as tags de cor da mensagem antes de escrevê-la no arquivo de log
		RemoveColorTags(message, filteredMessage, sizeof(filteredMessage));
		ReplaceString(filteredMessage, sizeof(filteredMessage), "ENVIE SEU DONATE NO SITE:", "");
		ReplaceString(filteredMessage, sizeof(filteredMessage), "FARWEST.COM.BR/COMANDOS", "");
		ReplaceString(filteredMessage, sizeof(filteredMessage), "PARA ATIVAR COMANDOS NO SERVIDOR!\n ", "");
		ReplaceString(filteredMessage, sizeof(filteredMessage), "\n", " ");
		ReplaceString(filteredMessage, sizeof(filteredMessage), "   ", "");

		WriteFileLine(logFile, "======================================== %s - %s ========================================", FormatedDate, FormatedTime);
		WriteFileLine(logFile, filteredMessage);
		WriteFileLine(logFile, "=======================================================================================================");
		WriteFileLine(logFile, "");
		WriteFileLine(logFile, "");
		CloseHandle(logFile);
	}
}

// ###########################################################################




// ############################## Weapon list ##################################
public Action:GunsList(id, args)
{
	new i;
	for (i = 0; i < MAX_WEAPONS; ++i)
		ReplyToCommand(id, "%s", g_weapons[i]);

	ReplyToCommand(id, "----------------");
	ReplyToCommand(id, "!give <weaponname> To give one weapon to all players\n!give2 <weaponname> To give two weapons to all players");

	return Plugin_Handled;
}
// ###########################################################################




// ############################## Give 1 weapon ################################
public Action:Give1WeaponAll(id, args)
{
	if (args < 1)
	{
		ReplyToCommand(id, "[SM] Usage: !give <weapon name> Gives a weapon to all players\nType !gunslist to see the weapons list!");
		return Plugin_Handled;
	}

	decl String:WeaponName[32];
	GetCmdArgString(WeaponName, sizeof(WeaponName));

	// Construindo o nome da arma
	Format(WeaponGive1, sizeof(WeaponGive1), "weapon_%s", WeaponName);

	new i;
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
		{
			// Se o jogador estiver morto, registre-o para distribuição posterior
			numDeadPlayersGive1++;
			deadPlayersGive1[numDeadPlayersGive1] = i;
			continue;
		}

		GivePlayerItem(i, WeaponGive1);
		FakeClientCommandEx(i, "use weapon_fists");
		FakeClientCommandEx(i, "use %s", WeaponGive1);
	}

	return Plugin_Handled;
}

public Action:Give1DeadPlayersWeapon(Handle:timer)
{
	new i;
	for (i = 1; i < MaxClients; i++)
	{
		new playerID = deadPlayersGive1[i];
		if (playerID == 0)
			continue;

		if (IsPlayerAlive(playerID))
		{
			// Se o jogador reviver, dê a arma
			GivePlayerItem(playerID, WeaponGive1);
			FakeClientCommandEx(playerID, "use weapon_fists");
			FakeClientCommandEx(playerID, "use %s", WeaponGive1);

			// Remova o jogador da lista de jogadores mortos
			deadPlayersGive1[i] = 0;
			numDeadPlayersGive1--;
		}
	}
	return Plugin_Handled;
}
// #############################################################################




// ############################## Give 2 weapon ################################
public Action:Give2WeaponAll(id, args)
{
	if (args < 1)
	{
		ReplyToCommand(id, "[SM] Usage: !give2 <weapo nname> Gives two weapons to all players\nType !gunslist to see the weapons list!");
		return Plugin_Handled;
	}

	decl String:WeaponName[32];
	GetCmdArgString(WeaponName, sizeof(WeaponName));

	// Construindo o nome da arma
	Format(WeaponGive2, sizeof(WeaponGive2), "weapon_%s", WeaponName);

	new i;
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
		{
			// Se o jogador estiver morto, registre-o para distribuição posterior
			numDeadPlayersGive2++;
			deadPlayersGive2[numDeadPlayersGive2] = i;
			continue;
		}

		decl String:WeaponGive2_2[32];
		strcopy(WeaponGive2_2, sizeof(WeaponGive2_2), WeaponGive2);
		StrCat(WeaponGive2_2, sizeof(WeaponGive2_2), "2");

		GivePlayerItem(i, WeaponGive2);
		GivePlayerItem(i, WeaponGive2);
		FakeClientCommandEx(i, "use weapon_fists");
		FakeClientCommandEx(i, "use %s", WeaponGive2);
		FakeClientCommandEx(i, "use %s", WeaponGive2_2);
	}

	return Plugin_Handled;
}

public Action:Give2DeadPlayersWeapon(Handle:timer)
{
	new i;
	for (i = 1; i < MaxClients; i++)
	{
		new playerID = deadPlayersGive2[i];
		if (playerID == 0)
			continue;

		if (IsPlayerAlive(playerID))
		{
			decl String:WeaponGive2_2[32];
			strcopy(WeaponGive2_2, sizeof(WeaponGive2_2), WeaponGive2);
			StrCat(WeaponGive2_2, sizeof(WeaponGive2_2), "2");
			
			// Se o jogador reviver, dê a arma
			GivePlayerItem(playerID, WeaponGive2);
			GivePlayerItem(playerID, WeaponGive2);
			FakeClientCommandEx(playerID, "use weapon_fists");
			FakeClientCommandEx(playerID, "use %s", WeaponGive2);
			FakeClientCommandEx(playerID, "use %s", WeaponGive2_2);

			// Remova o jogador da lista de jogadores mortos
			deadPlayersGive2[i] = 0;
			numDeadPlayersGive2--;
		}
	}
	return Plugin_Handled;
}
// #############################################################################




// ########################## Infinite Peacemaker ################################
public Action:InfinitePeacemaker(id, args)
{
	new i;
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
		{
			// Se o jogador estiver morto, registre-o para distribuição posterior
			numDeadInfinitePeacemaker++;
			deadPlayersInfinitePeacemaker[numDeadInfinitePeacemaker] = i;
			continue;
		}

		SetEntProp(i, Prop_Send, "m_nPotionLevel", 100);
		GivePlayerItem(i, ItemPotion); 
	}

	return Plugin_Handled;
}

public Action:InfinitePeacemakerDeadPlayers(Handle:timer)
{
	new i;
	for (i = 1; i < MaxClients; i++)
	{
		new playerID = deadPlayersInfinitePeacemaker[i];
		if (playerID == 0)
			continue;

		if (IsPlayerAlive(playerID))
		{
			// Se o jogador reviver, dê duas peacemaker infinitas
			SetEntProp(playerID, Prop_Send, "m_nPotionLevel", 100);
			GivePlayerItem(playerID, ItemPotion); 

			// Remova o jogador da lista de jogadores mortos
			deadPlayersInfinitePeacemaker[i] = 0;
			numDeadInfinitePeacemaker--;
		}
	}
	return Plugin_Handled;
}
// #############################################################################


// ########################## Give 100 Dynamite ################################
public Action:Give100tntAll(id, args)
{
	if (args < 1)
	{
		ReplyToCommand(id, "[SM] Usage: !tnt <tnt name>\nGives 100 dynamite to all players\nType !givelist to see the dynamites list!");
		return Plugin_Handled;
	}

	decl String:WeaponName[32];
	GetCmdArgString(WeaponName, sizeof(WeaponName));

	// Construindo o nome da arma
	Format(WeaponTnt, sizeof(WeaponTnt), "weapon_%s", WeaponName);

	new i;

	// Itera sobre os jogadores para dar a arma
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
		{
			// Se o jogador estiver morto, registre-o para distribuição posterior
			numDeadPlayers100Tnt++;
			deadPlayers100Tnt[numDeadPlayers100Tnt] = i;
			continue;
		}

		// Se o jogador estiver vivo, dê a arma imediatamente
		GivePlayerItem(i, WeaponTnt);
		FakeClientCommandEx(i, "use weapon_fists");
		FakeClientCommandEx(i, "use %s", WeaponTnt);
		new weaponindex = GetEntPropEnt(i, Prop_Data, "m_hActiveWeapon");
		SetAmmo(i, weaponindex, 100);
	}

	return Plugin_Handled;
}

public Action:Give100TntDeadPlayers(Handle:timer)
{
	new i;
	for (i = 1; i < MaxClients; i++)
	{
		new playerID = deadPlayers100Tnt[i];
		if (playerID == 0)
			continue;

		if (IsPlayerAlive(playerID))
		{
			// Se o jogador reviver, dê 100 dinamites
			GivePlayerItem(playerID, WeaponTnt);
			FakeClientCommandEx(playerID, "use weapon_fists");
			FakeClientCommandEx(playerID, "use %s", WeaponTnt);
			new weaponindex = GetEntPropEnt(playerID, Prop_Data, "m_hActiveWeapon");
			SetAmmo(playerID, weaponindex, 100);

			// Remova o jogador da lista de jogadores mortos
			deadPlayers100Tnt[i] = 0;
			numDeadPlayers100Tnt--;
		}
	}
	return Plugin_Handled;
}
// #############################################################################




// ################################## Give melee weapon ################################
public Action:GiveMeleeWeaponAll(id, args)
{
	if (args < 1)
	{
		ReplyToCommand(id, "[SM] Usage: !givecw <melee weapon name> Gives 20 melee weapon to all players\nType !gunslist to see the weapons list!");
		return Plugin_Handled;
	}

	decl String:WeaponName[32];
	GetCmdArgString(WeaponName, sizeof(WeaponName));

	// Construindo o nome da arma
	Format(MeleeWeapon, sizeof(MeleeWeapon), "weapon_%s", WeaponName);

	new i;
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
		{
			// Se o jogador estiver morto, registre-o para distribuição posterior
			numDeadPlayersMeleeWeapon++;
			deadPlayersMeleeWeapon[numDeadPlayersMeleeWeapon] = i;
			continue;
		}

		new j;
		for (j = 0; j < 20; j++)
		{
			GivePlayerItem(i, MeleeWeapon);
		}		
		FakeClientCommandEx(i, "use weapon_fists");
		FakeClientCommandEx(i, "use %s", MeleeWeapon);
	}

	return Plugin_Handled;
}

public Action:GiveMeleeWeaponDeadPlayers(Handle:timer)
{
	new i;
	for (i = 1; i < MaxClients; i++)
	{
		new playerID = deadPlayersMeleeWeapon[i];
		if (playerID == 0)
			continue;

		if (IsPlayerAlive(playerID))
		{
			// Se o jogador reviver, dê a arma
			new j;
			for (j = 0; j < 20; j++)
			{
				GivePlayerItem(playerID, MeleeWeapon);
			}	
			FakeClientCommandEx(playerID, "use weapon_fists");
			FakeClientCommandEx(playerID, "use %s", MeleeWeapon);

			// Remova o jogador da lista de jogadores mortos
			deadPlayersMeleeWeapon[i] = 0;
			numDeadPlayersMeleeWeapon--;
		}
	}
	return Plugin_Handled;
}
// #############################################################################




// ################################## Set Ammo ################################
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
// #############################################################################




public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (numDeadPlayersGive1 > 0)
	{
		CreateTimer(0.1, Give1DeadPlayersWeapon);
	}

	if (numDeadPlayersGive2 > 0)
	{
		CreateTimer(0.1, Give2DeadPlayersWeapon);
	}

	if (numDeadInfinitePeacemaker > 0)
	{
		CreateTimer(0.1, InfinitePeacemakerDeadPlayers);
	}

	if (numDeadPlayers100Tnt > 0)
	{
		CreateTimer(0.1, Give100TntDeadPlayers);
	}

	if (numDeadPlayersMeleeWeapon > 0)
	{
		CreateTimer(0.1, GiveMeleeWeaponDeadPlayers);
	}
}