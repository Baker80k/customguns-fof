#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <customguns>

#define CLASSNAME "weapon_shovel"
#define RANGE 90.0
#define DAMAGE 35.0
#define PUSH_SCALE 600.0
#define PUSH_VERTICAL 600.0

#define COOLDOWN_TICK 0.025
#define COOLDOWN_DRAW 1.0
#define COOLDOWN_PRIMARY_FIRE 1.0

float timeToNextAction[MAXPLAYERS+1];
WeaponState weaponState[MAXPLAYERS+1];
// We're erasing the buttons pressed by the player to prevent the base weapon's from firing
// But we still need to use them later, so save them in here
bool commandAttack1[MAXPLAYERS+1];
bool commandDrop[MAXPLAYERS+1];

enum WeaponState{
	WEAPON_HOLSTERED,
	WEAPON_DRAWING,
    WEAPON_IDLE,
	WEAPON_CLICK_SWING,
	WEAPON_SWINGING, //  TODO: I want a lead up and followthrough
};

public OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		SDKHook(client, SDKHook_PostThinkPost, OnPreThink);
		Reset(client);
	}
}

public void CG_OnHolster(int client, int weapon, int switchingTo){
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if(StrEqual(sWeapon, CLASSNAME)){
		Reset(client);
	}
}

public void PrimaryAttack(int client, int weapon){
	CG_SetPlayerAnimation(client, PLAYER_ATTACK1);
	vmSeq(client, 2, COOLDOWN_PRIMARY_FIRE);
	PrimaryFire(client, weapon);
}

void PrimaryFire(client, weapon) {
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
		//if(entityHit > 0 && (IsPlayer(entityHit) || GetClientTeam(entityHit) != GetClientTeam(client)) )
		if (IsPlayer(entityHit))
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
			victim_velocity[2] = PUSH_VERTICAL;

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

/**
 * When the player runs the command, that is the earliest time we can possibly know
 */
public Action OnPlayerRunCmd(client, &iButtons, &Impulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{
	if (!IsFakeClient(client))
	{
		char sWeapon[32];
		GetClientWeapon(client, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, CLASSNAME)) {
			if (timeToNextAction[client] <= 0 && weaponState[client] == WEAPON_IDLE) {
				int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if (iButtons & IN_ATTACK) {
					iButtons &= ~IN_ATTACK;
					PrintToServer("%s Clicked primary fire at %f", CLASSNAME, GetGameTime());
					PrimaryAttack(client, weapon);
					weaponState[client] = WEAPON_CLICK_SWING;
				}
				else if (iButtons & IN_ZOOM) {
					//CG_DropWeapon(client, weapon); TODO: this dropping needs some work
					CG_ClearInventory(client);
					float pos[3];
					CG_GetShootPosition(client, pos);
					CG_SpawnGun("weapon_shovel", pos);
					RemovePlayerItem( client, weapon );
					AcceptEntityInput( weapon, "Kill" );
					FakeClientCommand(client, "use weapon_fists");

				}
			}
		} else {
			Reset(client);
		}
	}
}

public OnPreThink(client) {
	if (!IsFakeClient(client) && IsPlayerAlive(client)){
		char sWeapon[32];
		GetClientWeapon(client, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, CLASSNAME)) {
			// Prevent client-side prediction
			float delayAttack = GetGameTime() + 999.0;
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			int bullets = GetEntProp(weapon, Prop_Send, "m_iClip1");
			int vm = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", delayAttack);
			SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", delayAttack);

			// Advance weapon state and change cooldown time
			timeToNextAction[client] -= COOLDOWN_TICK;
            if (timeToNextAction[client] < 0 && weaponState[client] != WEAPON_IDLE) {
                PrintToServer("----------")
                PrintToServer("Time's Up!")
				switch (weaponState[client]) {
					case WEAPON_HOLSTERED: {
						timeToNextAction[client] = COOLDOWN_DRAW;
						weaponState[client] = WEAPON_DRAWING;
					}
					case WEAPON_DRAWING: {
						weaponState[client] = WEAPON_IDLE;
					}
					case WEAPON_CLICK_SWING: {
						timeToNextAction[client] = COOLDOWN_PRIMARY_FIRE;
						weaponState[client] = WEAPON_SWINGING;
					}
					case WEAPON_SWINGING: {
						weaponState[client] = WEAPON_IDLE;
					}
				}
                PrintToServer("----------")
			}
		}
	}
}

public void CG_OnPrimaryAttack(int client, int weapon){
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	if(StrEqual(sWeapon, CLASSNAME)){
        PrintToServer("ERROR! Regular %s attack got through!", CLASSNAME);
    }
}

public bool TraceEntityFilter(int entity, int mask, any data){
	if (entity == data)
		return false;
	return true;
}

public void Reset(int client) {
	commandAttack1[client] = false;
	commandDrop[client] = false;
	weaponState[client] = WEAPON_HOLSTERED;
	timeToNextAction[client] = 0;
}