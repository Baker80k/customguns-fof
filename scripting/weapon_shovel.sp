#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <customguns>

#define CLASSNAME "weapon_shovel"
#define REFIRE 1.5
#define RANGE 90.0
#define DAMAGE 50.0
#define PUSH_SCALE 600.0

float timeToNextAction[MAXPLAYERS+1];

public OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
		timeToNextAction[client] = 1.0;
	}
}

public void CG_OnHolster(int client, int weapon, int switchingTo){
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if(StrEqual(sWeapon, CLASSNAME)){
		timeToNextAction[client] = 0.1;
	}
}

public void PrimaryAttack(int client, int weapon){
	timeToNextAction[client] = REFIRE;
	CG_SetPlayerAnimation(client, PLAYER_ATTACK1);
	//CG_PlayActivity(weapon, ACT_VM_MISSCENTER); // ACT_VM_HITCENTER
	CG_PlayActivity(weapon, ACT_VM_PRIMARYATTACK);

	float pos[3], angles[3], endPos[3];
	CG_GetShootPosition(client, pos);
	GetClientEyeAngles(client, angles);
	
	GetAngleVectors(angles, endPos, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(endPos, RANGE);
	AddVectors(pos, endPos, endPos);
	
	TR_TraceHullFilter(pos, endPos, view_as<float>({-10.0, -10.0, -10.0}), view_as<float>({10.0, 10.0, 10.0}), MASK_SHOT_HULL, TraceEntityFilter, client);
	
	float punchAngle[3];
	punchAngle[0] = GetRandomFloat( 1.0, 2.0 );
	punchAngle[1] = GetRandomFloat( -2.0, -1.0 );
	Tools_ViewPunch(client, punchAngle);
	
	if(TR_DidHit())
	{
		EmitGameSoundToAll("Weapon_Crowbar.Melee_Hit", weapon);
		
		int entityHit = TR_GetEntityIndex();
		if(entityHit > 0 && (IsPlayer(entityHit) || GetClientTeam(entityHit) != GetClientTeam(client)) )
		{
			char classname[32];
			GetEntityClassname(entityHit, classname, sizeof(classname));
			float push[3], attacker_origin[3], victim_origin[3], victim_velocity[3];
			int victim = entityHit;
			// get original base velocity of vicitm
			GetEntPropVector(victim, Prop_Data, "m_vecBaseVelocity", victim_velocity);

			// build push vector
			GetClientAbsOrigin(client, attacker_origin);
			GetClientAbsOrigin(victim, victim_origin);
			MakeVectorFromPoints(attacker_origin, victim_origin, push);
			NormalizeVector(push, push);
			ScaleVector(push, PUSH_SCALE);

			AddVectors(push, victim_velocity, victim_velocity);

			// avoid friction
			victim_velocity[2] = 100.0;

			// set new base velocity of victim to send them flying
			SetEntPropVector(victim, Prop_Data, "m_vecBaseVelocity", victim_velocity);
			SDKHooks_TakeDamage(entityHit, client, client, DAMAGE, DMG_CLUB);
		}
		
		// Do additional trace for impact effects
		// if ( ImpactWater( pos, endPos ) ) return;
		float impactEndPos[3];
		GetAngleVectors(angles, impactEndPos, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(impactEndPos, RANGE);
		TR_GetEndPosition(endPos);
		AddVectors(impactEndPos, endPos, impactEndPos);

		TR_TraceRayFilter(endPos, impactEndPos, MASK_SHOT_HULL, RayType_EndPoint, TraceEntityFilter, client);
		if(TR_DidHit())
		{
			UTIL_ImpactTrace(pos, DMG_CLUB);
		}
	}
	else
	{
		EmitGameSoundToAll("Weapon_Crowbar.Single", weapon);
	}
}

public void CG_ItemPostFrame(int client, int weapon){
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if(StrEqual(sWeapon, CLASSNAME)){
		timeToNextAction[client] -= 0.025;
	}
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!IsFakeClient(client))
	{
		char sWeapon[32];
		GetClientWeapon(client, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, CLASSNAME)) {
			if (timeToNextAction[client] <= 0) {
				weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if (buttons & IN_ATTACK) {
					PrintToServer("Attempting Fire of Shovel!");
					PrimaryAttack(client, weapon);
				}
			}
		}
	}
}

public OnPostThinkPost(client) {
	if (!IsFakeClient(client) && IsPlayerAlive(client)){
		char sWeapon[32];
		GetClientWeapon(client, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, CLASSNAME)) {
			// Prevent client-side prediction
			float delayAttack = GetGameTime() + 999.0;
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", delayAttack);
			SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", delayAttack);
		}
	}
}

public void CG_OnPrimaryAttack(int client, int weapon){
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	if(StrEqual(sWeapon, CLASSNAME)){
        PrintToServer("ERROR! Regular attack got through!");
    }
}

public bool TraceEntityFilter(int entity, int mask, any data){
	if (entity == data)
		return false;
	return true;
}