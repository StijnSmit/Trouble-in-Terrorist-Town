#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <ttt>

new g_iTotalItems[33], g_iPlayerItems[33][TTT_TOTAL_BACKPACK], g_iItemData[33][TTT_TOTAL_BACKPACK][TTT_ITEMNAME];
new g_iItemForward;

public plugin_init()
{
	register_plugin("[TTT] Backpack base", TTT_VERSION, TTT_AUTHOR);
	RegisterHam(Ham_Player_ImpulseCommands, "player", "Ham_Impulse_pre", 0, true);
	g_iItemForward = CreateMultiForward("ttt_item_backpack", ET_CONTINUE, FP_CELL, FP_CELL, FP_STRING);
}

public plugin_natives()
{
	register_library("ttt");
	register_native("ttt_backpack_add", "_backpack_add");
	register_native("ttt_backpack_remove", "_backpack_remove");
	register_native("ttt_backpack_show", "_backpack_show");
}

public client_disconnect(id)
{
	new i;
	g_iTotalItems[id] = 0;
	for(i = 0; i < charsmax(g_iPlayerItems[]); i++)
	{
		g_iPlayerItems[id][i] = -1;
		g_iItemData[id][i][0] = EOS;
	}
}

public Ham_Impulse_pre(id)
{
	if(is_user_alive(id) && entity_get_int(id, EV_INT_impulse) == 100)
	{
		ttt_backpack_showup(id);
		entity_set_int(id, EV_INT_impulse, 0);
		return HAM_HANDLED;
	}

	return HAM_IGNORED;
}

public ttt_gamemode(gamemode)
{
	if(gamemode == PREPARING || gamemode == RESTARTING)
	{
		new num, id, i;
		static players[32];
		get_players(players, num);
		for(--num; num >= 0; num--)
		{
			id = players[num];
			g_iTotalItems[id] = 0;
			for(i = 0; i < sizeof(g_iPlayerItems[]); i++)
			{
				g_iPlayerItems[id][i] = -1;
				g_iItemData[id][i][0] = EOS;
			}
		}
	}
}

public ttt_backpack_showup(id)
{
	if(ttt_return_check(id) || !is_user_alive(id))
		return PLUGIN_HANDLED;

	if(!g_iTotalItems[id])
	{
		client_print_color(id, print_team_default, "%s %L", TTT_TAG, id, "TTT_BACKPACK_NONE");
		return PLUGIN_HANDLED;
	}

	new i, set;
	static item[128], num[3];
	new iMenu = menu_create("\rBackpack", "ttt_backpack_handle");

	for(i = 0; i < charsmax(g_iPlayerItems[]); i++)
    {
		if(g_iPlayerItems[id][i] == -1) continue;
		formatex(item, charsmax(item), "%s\R\y                                                    ", g_iItemData[id][i]);

		num_to_str(set, num, charsmax(num));
		menu_additem(iMenu, item, num);
		set++;
    }

	menu_display(id, iMenu, 0);
	return PLUGIN_HANDLED;
}

public ttt_backpack_handle(id, menu, item)
{
	if(ttt_return_check(id) || !is_user_alive(id))
		return PLUGIN_HANDLED;

	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new access, callback, num[3];
	menu_item_getinfo(menu, item, access, num, charsmax(num), _, _, callback);
	menu_destroy(menu);

	static name[32];
	new itemid = str_to_num(num);
	if(g_iPlayerItems[id][itemid] != -1)
	{
		new ret;
		ExecuteForward(g_iItemForward, ret, id, itemid, g_iItemData[id][itemid]);
		formatex(name, charsmax(name), "%L", LANG_PLAYER, "TTT_ITEM_ID7");
		if(!equal(name, g_iItemData[id][itemid]) && ret == PLUGIN_HANDLED)
		{
			static msg[128], name[32];
			get_user_name(id, name, charsmax(name));
			formatex(msg, charsmax(msg), "Player %s used item %s from backpack with ID %d", name, g_iItemData[id][itemid], itemid);
			ttt_log_to_file(LOG_ITEM, msg);

			g_iPlayerItems[id][itemid] = -1;
			g_iItemData[id][itemid][0] = EOS;
			g_iTotalItems[id]--;
		}
	}

	return PLUGIN_HANDLED;
}

public _backpack_add(plugin, param)
{
	new id = get_param(1), index, i;
	if(is_user_alive(id))
	{
		for(i = 0; i <= g_iTotalItems[id]; i++)
		{
			if(g_iPlayerItems[id][i] == -1)
			{
				index = i;
				break;
			}
		}

		g_iTotalItems[id]++;
		g_iPlayerItems[id][index] = index;
		get_string(2, g_iItemData[id][index], charsmax(g_iItemData[][]));

		return index;
	}

	return -1;
}

public _backpack_remove(plugin, param)
{
	new id = get_param(1), index = get_param(2);
	if(index > -1)
	{
		if(is_user_connected(id))
		{
			g_iTotalItems[id]--;
			g_iPlayerItems[id][index] = -1;
			g_iItemData[id][index][0] = EOS;

			return -1;
		}
	}

	return -2;
}

public _backpack_show(plugin, param)
{
	new id = get_param(1);
	if(is_user_alive(id))
		ttt_backpack_showup(id);
}