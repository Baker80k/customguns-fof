#if defined _CustomGuns_Globals_included
	#endinput
#endif
#define _CustomGuns_Globals_included

// CVARS
Handle customguns_default;
Handle customguns_global_switcher;
Handle customguns_autogive;
Handle customguns_order_alphabetically;
Handle customguns_static_wheel;
Handle customguns_allow_menu;

// COOKIES
Handle cookie_menu_style;

// Config
// All
Handle gunClassNames;
Handle gunNames;
Handle gunAnimPrefix;
Handle gunType;
Handle fofBase;
Handle useDynamic;
Handle gunModels;
Handle gunViewmodels;
Handle gunModelIndexes;
Handle gunSkin;
Handle gunAdminLevel;
Handle gunPersistent;
Handle gunGive;
Handle gunGiveMasterWeapon;
Handle gunBind;
Handle gunStuck;

Handle gunDownloads;

Handle gunScopeFov;
Handle gunScopeOverlay;
Handle gunScopeSoundOn;
Handle gunScopeSoundOff;

// Custom
Handle gunCustomKeepAmmo;

// Bulllet
Handle gunDmg;
Handle gunSpread;
Handle gunRof;
Handle gunDelay;
Handle gunDelaySequence;
Handle gunDelayFireCooldown;
Handle gunViewKickScale;
Handle gunViewKickAngle;
Handle gunViewKickTime;
Handle gunFireLoopFix;
Handle gunFireLoopLength;
Handle gunFireVisible;
Handle gunReloadsSingly;
Handle gunFireType;

int CLIENT_BEING_EQUIPPED = -1;

bool open[MAXPLAYERS + 1];
float firstOpen[MAXPLAYERS + 1];
float nextDrawText[MAXPLAYERS + 1];
float startEyeAngles[MAXPLAYERS + 1][3];

int gunEnt[MAXPLAYERS + 1] = { -1, ... };
int selectedGunIndex[MAXPLAYERS + 1] = { -1, ... };
int preferedGunIndex[MAXPLAYERS + 1] = { -1, ... };
int dynamicProps[MAXPLAYERS + 1] = { -1, ... };
int stuckWeapon[MAXPLAYERS + 1] = { -1, ... }; 

Handle inventory[MAXPLAYERS + 1];
Handle inventoryWheel[MAXPLAYERS + 1];
Handle inventoryAnimScale[MAXPLAYERS + 1];
Handle inventoryAmmo[MAXPLAYERS + 1];
Handle inventoryAmmoType[MAXPLAYERS + 1];

bool firing[MAXPLAYERS + 1];
float nextFireSound[MAXPLAYERS + 1];
float lastFired[MAXPLAYERS + 1];

int menuStyle[MAXPLAYERS + 1];

Handle DHOOK_FireBullets;
Handle DHOOK_TranslateActivity;
Handle DHOOK_Operator_HandleAnimEvent;
Handle DHOOK_GetFireRate;
Handle DHOOK_ReloadOrSwitchWeapons;
Handle DHOOK_AddViewKick;
Handle DHOOK_BumpWeapon;
Handle DHOOK_Reload;
Handle DHOOK_ItemPostFrame;
Handle DHOOK_ItemPostFramePost;
Handle DHOOK_PrimaryAttack;
Handle DHOOK_SecondaryAttack;
Handle DHOOK_Holster;
Handle DHOOK_WeaponSound;
Handle DHOOK_Drop;
Handle DHOOK_GetDefaultClip1;
Handle DHOOK_Explode;
Handle DHOOK_RadiusDamage;

Handle CALL_HasPrimaryAmmo;
Handle CALL_HasSecondaryAmmo;
Handle CALL_WeaponSound;
Handle CALL_StopWeaponSound;
Handle CALL_Weapon_Switch;
Handle CALL_SendWeaponAnim;
Handle CALL_SendViewModelAnim;
Handle CALL_CheckRespawn;
Handle CALL_UsesClipsForAmmo1;
Handle CALL_GiveAmmo;
Handle CALL_GetAmmoCount;
Handle CALL_RemoveAmmo;
Handle CALL_SetAnimation;
Handle CALL_ShootPosition;

Handle PrimaryAttackForward;
Handle SecondaryAttackForward;
Handle ItemPostFrameForward;
Handle HolsterForward;