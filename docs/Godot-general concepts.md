# general file concepts

# prompt
Can you give me a breakdown of what all the Godot file extensions are and what they do for a game?

# response
Absolutely. In a Godot project, the extensions mostly tell you what kind of game asset or Godot resource a file represents. The most important ones are .gd, .tscn, .tres, .res, .godot, and .import.

Here’s a practical breakdown, assuming Godot 4.x.

Extension	What it is	What it does in your game
.gd	GDScript	Contains your game code: movement, combat, UI logic, AI, inventory systems, etc.
.tscn	Text Scene	Stores a scene/node hierarchy in human-readable text. Used for levels, players, enemies, menus, weapons, etc.
.scn	Binary Scene	Same general purpose as .tscn, but stored in a binary format.
.tres	Text Resource	Stores a reusable Godot Resource in human-readable text: materials, stats, custom data, themes, etc.
.res	Binary Resource	Binary equivalent of .tres.
.godot	Godot project/config file	project.godot contains project-wide settings such as resolution, input actions, rendering options, and startup scene.
.gdshader	Godot Shader	Shader code controlling how graphics are rendered: water, outlines, glow, distortion, grass effects, etc.
.gdextension	GDExtension config	Connects compiled native libraries, typically C/C++, to Godot.
.uid	Resource UID metadata	Helps Godot track resources by unique ID rather than relying entirely on file paths.
.import	Import metadata	Information Godot uses when importing external assets. Much of this is managed automatically.

The big three: .gd, .tscn, and .tres

These are the ones you’ll probably interact with constantly.

Imagine you’re making a sword.

You might have:

sword/
├── sword.gd
├── sword.tscn
├── sword_stats.tres
├── sword.png
└── sword_swing.wav

sword.gd — behavior

This is the programming:

extends Area2D
@export var damage := 10
func attack():
    print("Sword attacked for ", damage)

It answers:

“What does the sword DO?”

⸻

sword.tscn — the actual scene/object

This describes the nodes making up the sword:

Sword
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
└── AudioStreamPlayer2D

It can reference the script, sprite, collision shape, animations, etc.

It answers:

“What IS the sword made of?”

A .tscn can represent almost anything:

player.tscn
enemy.tscn
bullet.tscn
main_menu.tscn
level_01.tscn
health_bar.tscn
treasure_chest.tscn

Godot’s scene system is broader than “level.” A Player can be a scene, and so can a Level.

⸻

sword_stats.tres — reusable data/resource

A .tres commonly stores data separate from the scene and code.

For example:

damage = 25
attack_speed = 1.2
knockback = 10
rarity = "Rare"

It answers:

“What DATA/configuration does this sword use?”

This becomes especially powerful with custom Resources.

For example:

class_name WeaponData
extends Resource
@export var weapon_name: String
@export var damage: int
@export var attack_speed: float
@export var icon: Texture2D

Then you could create:

weapons/
├── sword.tres
├── axe.tres
├── bow.tres
└── dagger.tres

All four use the same WeaponData structure but contain different values.

.tscn vs .scn

Both represent scenes.

player.tscn

is a text scene, while:

player.scn

is a binary scene.

.tscn is usually nicer during development because you can open it in a text editor and Git can track changes to it much more effectively.

For example, a .tscn internally looks roughly like:

[gd_scene load_steps=2 format=3]
[ext_resource path="res://player.gd" type="Script" id="1"]
[node name="Player" type="CharacterBody2D"]
script = ExtResource("1")
[node name="Sprite2D" type="Sprite2D" parent="."]

You normally don’t need to manually edit this.

.tres vs .res

Same idea.

weapon.tres

is a text resource.

weapon.res

is a binary resource.

For normal development, .tres is often more convenient because it’s human-readable and works nicely with version control.

project.godot

Every Godot project has one of these at its root:

MyGame/
├── project.godot
├── main.tscn
├── player/
├── enemies/
└── assets/

It’s essentially the project’s master configuration.

It contains things such as:

Game Name
Main Scene
Window Size
Physics Settings
Rendering Settings
Input Map
Layer Names
Localization
Audio

For example, when you create an input action called:

jump

and bind it to Space, that configuration is stored in project.godot.

You generally edit these settings through Project → Project Settings rather than manually modifying the file.

.gdshader

This contains Godot’s shader language.

For example:

shader_type canvas_item;
void fragment() {
    COLOR = texture(TEXTURE, UV);
}

Shaders run primarily on the GPU and can create effects such as:

Water
Fire
Outlines
Hit flashes
Dissolves
Pixelation
CRT effects
Fog
Grass movement
Screen distortion
Lighting effects

You may also encounter older .shader files in projects made with older Godot versions; .gdshader is the Godot 4 convention.

.gdextension

This is mainly relevant if you’re using GDExtension, which lets Godot load native compiled code.

For example:

my_library.gdextension

might point to:

Windows → my_library.dll
Linux   → my_library.so
macOS   → my_library.dylib

You probably won’t touch these when you’re starting with GDScript.

They’re more relevant for engine extensions, performance-intensive systems, C++ libraries, third-party plugins, and native integrations.

.uid

Modern Godot versions increasingly use UIDs — unique identifiers — to track resources.

The basic problem is that your game might reference:

res://characters/player.gd

and then you move it to:

res://actors/player.gd

Path-only references can potentially break when assets move. UIDs give Godot another way of identifying the underlying resource.

You’ll sometimes see files like:

player.gd
player.gd.uid

These are Godot-managed metadata. Usually don’t manually modify or delete them.

Imported assets

You’ll also use plenty of files that aren’t Godot-specific:

.png
.jpg
.webp
.svg
.wav
.ogg
.mp3
.glb
.gltf
.fbx
.obj
.ttf
.otf

Godot imports these and converts/processes them into formats it can efficiently use.

For example:

player.png
     ↓
Godot importer
     ↓
Texture2D resource
     ↓
Sprite2D displays it

Import settings determine things like texture filtering, compression, mipmaps, audio looping, 3D mesh processing, and animation import.

Godot keeps generated import/cache information inside the project’s hidden:

.godot/

directory.

You generally shouldn’t manually modify anything inside .godot/. It is generated project data and can normally be regenerated from your source assets.

A realistic Godot project

Once you understand the extensions, a project might make more sense:

my_game/
│
├── project.godot
│
├── main.tscn
│
├── main.gd
│
├── icon.svg
│
├── player/
│   ├── player.tscn
│   ├── player.gd
│   └── player_stats.tres
│
├── enemies/
│   ├── slime.tscn
│   ├── slime.gd
│   └── slime_stats.tres
│
├── weapons/
│   ├── weapon_data.gd
│   ├── sword.tres
│   ├── bow.tres
│   └── axe.tres
│
├── shaders/
│   └── hit_flash.gdshader
│
├── sprites/
│   ├── player.png
│   └── slime.png
│
└── audio/
    ├── sword_hit.wav
    └── battle_music.ogg

Conceptually, you can remember it as:

.gd = behavior/code → .tscn = objects/scenes → .tres = reusable data → external assets = graphics/audio/models → project.godot = whole-game configuration.

That mental model covers a surprisingly large portion of how a Godot project is organized.
