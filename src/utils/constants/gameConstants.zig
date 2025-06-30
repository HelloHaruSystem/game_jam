const rl = @cImport({
    @cInclude("raylib.h");
});

// windows consts
pub const WINDOW_WIDTH = 1280;
pub const WINDOW_HEIGHT = 720;

// sprite constants
pub const PLAYER_SPRITE_SIZE = 32;
pub const PLAYER_SPRITE_HALF_SIZE = PLAYER_SPRITE_SIZE / 2;
pub const ENEMY_SPRITE_SIZE = 32;
pub const PROJECTILE_SPRITE_SIZE = 16;

// animation constants
pub const PLAYER_IDLE_FRAME_COUNT = 6;
pub const PLAYER_WALK_FRAME_COUNT = 8;
pub const PLAYER_ATTACK_FRAME_COUNT = 8;
pub const ENEMY_FRAME_COUNT = 6;
pub const PROJECTILE_FRAME_COUNT = 5;

// animations rows (0-indexed)
pub const PLAYER_IDLE_ROW = 4;
pub const PLAYER_WALK_ROW = 3;
pub const PLAYER_ATTACK_ROW = 8;
pub const ENEMY_WALK_ROW = 3;
pub const PROJECTILE_ROW = 16;

// game balance constants
pub const DEFAULT_PLAYER_SPEED = 200.0;
pub const DEFAULT_PLAYER_FIRE_SPEED = 300.0;
pub const DEFAULT_PLAYER_FIRE_RATE = 1.5; // shots per second
pub const DEFAULT_PLAYER_MAX_HEALTH = 3;
pub const DEFAULT_PLAYER_DAMAGE_COOLDOWN = 1.0; // seconds
pub const DEFAULT_PLAYER_KNOCKBACK_FRICTION = 8.0;

pub const DEFAULT_PROJECTILE_SPEED = 300.0;
pub const DEFAULT_PROJECTILE_LIFETIME = 3.0; // seconds
pub const DEFAULT_PROJECTILE_DAMAGE = 1;
pub const DEFAULT_PROJECTILE_SCALE = 2.0;

pub const DEFAULT_ENEMY_SPAWN_RATE = 2.0; // seconds between spawns
pub const DEFAULT_ENEMY_SPAWN_OFFSET = 50; // pixels outside screen

// Enemy type constants
pub const SMALL_ENEMY_HEALTH = 2;
pub const SMALL_ENEMY_SPEED = 220.0;
pub const SMALL_ENEMY_SCALE = 1.3;
pub const SMALL_ENEMY_SCORE: u32 = 10;

pub const MEDIUM_ENEMY_HEALTH = 3;
pub const MEDIUM_ENEMY_SPEED = 80.0;
pub const MEDIUM_ENEMY_SCALE = 1.0;
pub const MEDIUM_ENEMY_SCORE: u32 = 25;

pub const LARGE_ENEMY_HEALTH = 5;
pub const LARGE_ENEMY_SPEED = 50.0;
pub const LARGE_ENEMY_SCALE = 1.5;
pub const LARGE_ENEMY_SCORE: u32 = 50;

pub const BOSS_ENEMY_HEALTH = 20;
pub const BOSS_ENEMY_SPEED = 30.0;
pub const BOSS_ENEMY_SCALE = 2.0;
pub const BOSS_ENEMY_SCORE: u32 = 200;

// Combat constants
pub const DEFAULT_ENEMY_DAMAGE = 1;
pub const DEFAULT_KNOCKBACK_STRENGTH = 2000.0;
pub const HIT_FLASH_DURATION = 0.2; // seconds

// Animation timing constants
pub const PLAYER_ANIMATION_SPEED = 0.15; // seconds per frame
pub const PLAYER_ATTACK_ANIMATION_SPEED = 0.04; // faster attack animation
pub const ENEMY_ANIMATION_SPEED = 0.15;
pub const PROJECTILE_ANIMATION_SPEED = 0.08;

// gameplay UI constants
pub const PLAYER_FLASH_SPEED = 10.0; // flashes per second when invincible
// UI
pub const UI_TOP_LINE_Y = 20;
pub const UI_TOP_LINE_X = 20;
pub const UI_TEXT_COLOR = rl.WHITE;
pub const UI_FONT_SIZE = 24;
pub const UI_SMALL_FONT_SIZE = 20;

pub const HEART_SIZE = 30;
pub const HEART_SPACING = 40;

// Sprite file names
pub const PLAYER_SPRITE_SHEET = "player_spritesheet.png";
pub const PROJECTILE_SPRITE_SHEET = "projectile_spritesheet.png";
pub const ENEMY_SPRITE_SHEET = "enemy_spritesheet.png";

// Rounds values
pub const DEFAULT_ROUND_DURATION = 30.0; // each round is 30 seconds
pub const DEFAULT_BREAK_DURATION = 5.0;  // 5 second break between rounds
pub const BASE_SPAWN_RATE = 2.0;         // spawns every 2 second
pub const MIN_SPAWN_RATE = 0.3;          // spawn rate can't go below 0.3 seconds