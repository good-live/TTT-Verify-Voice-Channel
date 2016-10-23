#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <ttt>
#include <verify>
#include <multicolors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "TTT Verify Warmup",
	author = PLUGIN_AUTHOR,
	description = "Allows the admins to create a verify voice channel in the warmup time.",
	version = PLUGIN_VERSION,
	url = "painlessgaming.eu"
};

bool g_bVerifyVoice = false;
bool g_bJoinedChannel[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegAdminCmd("sm_voice", Command_Voice, ADMFLAG_GENERIC);
	RegAdminCmd("sm_leave", Command_Leave, ADMFLAG_GENERIC);
	RegAdminCmd("sm_join", Command_Join, ADMFLAG_GENERIC);
	
	LoadTranslations("ttt_verify_warmup.phrases");
}

public Action Command_Voice(int client, int args)
{
	if(TTT_IsRoundActive())
	{
		CReplyToCommand(client, "%t %t", "Tag", "Not allowed during the round");
		return Plugin_Handled;
	}
	
	if(!g_bVerifyVoice)
	{
		EnableVerifyChannel();
		AddClientToChannel(client);
	} else {
		DisableVerifyChannel();
	}
	return Plugin_Handled;
}

public Action Command_Join(int client, int args)
{
	AddClientToChannel(client);
	return Plugin_Handled;
}

public Action Command_Leave(int client, int args)
{
	RemoveClientFromChannel(client);
	return Plugin_Handled;
}

void EnableVerifyChannel()
{
	g_bVerifyVoice = true;
	CPrintToChatAll("%t %t", "Tag", "The verify channel has been enabled");
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && !VF_IsClientVerified(i))
			AddClientToChannel(i);
	}
}

void AddClientToChannel(int client)
{
	if(g_bVerifyVoice)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				if(g_bJoinedChannel[i])
				{
					SetListenOverride(client, i, Listen_Yes);
					SetListenOverride(i, client, Listen_Yes);
					CPrintToChat(i, "%t %t", "Tag", "A client joined the channel", client);
				}else{
					SetListenOverride(client, i, Listen_No);
					SetListenOverride(i, client, Listen_No);
				}
			}
		}
		g_bJoinedChannel[client] = true;
		CPrintToChat(client, "%t %t", "Tag", "You joined the channel");
	}else{
		CPrintToChat(client, "%t %t", "Tag", "The channel is not active");
	}
}

void RemoveClientFromChannel(int client)
{
	if(g_bJoinedChannel[client])
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				if(g_bJoinedChannel[i])
				{
					SetListenOverride(client, i, Listen_No);
					SetListenOverride(i, client, Listen_No);
					CPrintToChat(i, "%t %t", "Tag", "A client left the channel", client);
				}else{
					SetListenOverride(client, i, Listen_Yes);
					SetListenOverride(i, client, Listen_Yes);
				}
			}
		}
		CPrintToChat(client, "%t %t", "Tag", "You left the channel");
		g_bJoinedChannel[client] = false;
	}else{
		CPrintToChat(client, "%t %t", "Tag", "You are not in the channel");
	}
}

void DisableVerifyChannel()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && g_bJoinedChannel[i])
			RemoveClientFromChannel(i);
	}
	g_bVerifyVoice = false;
}

public void VF_OnClientVerified(int client)
{
	if(g_bVerifyVoice)
		RemoveClientFromChannel(client);
}

public void TTT_OnRoundStart(int is, int t, int d)
{
	g_bVerifyVoice = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && g_bJoinedChannel[i]){
	
			CPrintToChat(i, "%t %t", "Tag", "The channel has been disabled");
			g_bJoinedChannel[i] = false;
			
			if(!IsPlayerAlive(i))
			{
				for (int j = 1; j <= MaxClients; j++)
				{
					if(IsClientValid(j))
					{
						if(IsPlayerAlive(j))
						{
							SetListenOverride(j, i, Listen_No);
							SetListenOverride(i, j, Listen_Yes);
						}else{
							SetListenOverride(j, i, Listen_Yes);
							SetListenOverride(i, j, Listen_Yes);
						}
					}
				}
			}
			else
			{
				for (int j = 1; j <= MaxClients; j++)
				{
					if(IsClientValid(j))
					{
						SetListenOverride(i, j, Listen_Yes);
						SetListenOverride(j, i, Listen_Yes);
					}
				}
			}
		}	
	}
}

stock bool IsClientValid(int client)
{
	if (0 < client <= MaxClients && IsClientInGame(client) && IsClientConnected(client))
		return true;
	return false;
}