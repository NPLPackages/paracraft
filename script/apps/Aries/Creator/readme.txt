---++ Creator Game Design 
| Author	| LiXizhi		|
| Date		| 2012.10.18	|

---+++ Overview

---++ File Format

---+++ worldpath/GameLevel.xml
Stores all kinds of interactive game objects on the map. 

<GameLevel>
	<settings daylength="10">
		<!-- what kind of mobs can appear in the game world. Defaults to all -->
		<mobs>
		</mobs>
		<!-- what kind of resource can appear in the game world. Defaults to all -->
		<resource>
		</resource>
	</settings>

	<!-- all persistent objects are here. -->
	<persistent>
		<object type="artifact" pos="" model_id=""/>
	</persistent>
</GameLevel>


---+++ Animal spawning
Approximately one in ten newly generated chunks will contain mobs, usually in packs of up to four of the same species. 
They will always spawn on the highest available block in a column i.e. the one that can see the sky. 
For an animal to spawn on it, this block must be opaque and the two blocks above it must be non-opaque. 
The block does not need to be grass nor does it need to be illuminated (as it does with Mob Spawning).

---+++ Mob spawning

Mobs are broadly divided into three categories: hostile, friendly, and water (i.e. Squid). 
Hostile mobs have a spawning cycle once every game tick (1/20th of a second). 
Friendly and water mobs have only one spawning cycle every 400 ticks (20 seconds). 
Because of this, hostile mobs can spawn at any time, but animals spawn very rarely. 
Instead, most animals spawn within chunks when they are generated.

Mobs spawn naturally within a 15x15 chunk (240x240 block) area around the player. 
When there are multiple players, mobs can spawn within this distance of any of them. 
However, mobs that move farther than 128 blocks from any player will immediately despawn (see Despawning), 
so the mob spawning area is effectively limited to spheres with a radius of 128 blocks, centered at each player.

Mob caps are directly proportional to the total number of chunks eligible for spawning. To calculate the cap, 
the spawning area is expanded by one chunk in every direction, so that it is 17x17 chunks in size, and then the total number of chunks is plugged into the following formula:

 cap = constant * chunks / 256

Each mob category has a separate cap and a different constant in the formula:

 Hostile = 70
 Passive = 15
 Water = 5

The cap is checked once at the beginning of each spawning cycle. If the number of living mobs in a category is over its cap, the entire spawning cycle for that category is skipped.
Example of a mob pack spawning. The 41x1x41 spawning area is shaded blue (not to scale). The yellow figures represent the actual positions that mobs could spawn in after checking the environment. Note that the mobs can spawn inside torch and ladder blocks. But they can't spawn on top of glass because it's not opaque. The red cube is the center of the pack, which must be an air block, but the blocks above and below it can be anything.
Requirements for the spawning location of individual mobs

For each spawning cycle, one attempt is made to spawn a pack of mobs in each eligible chunk.
A random location in the chunk is chosen to be the center point of the pack. For the pack to spawn at all, 
the center block must be water for water mobs and air for all other mobs. Note that in the latter case, it must literally be an air block. 
Any other block, even a non-colliding one, will prevent the entire pack from spawning.

If the pack location is suitable, 12 attempts are made to spawn up to 4 mobs (8 for Wolves, 1 for Ghasts) 
within a 41x1x41 area centered at that block (that's a 41x41 square that is one block high). 
Mobs will spawn with the lowest part of their body inside this area. For each spawn attempt, a block location within the pack area is chosen at random. 
Though the pack area extends 21 blocks out from the center, the random location is heavily skewed toward the center of the pack. 
Approximately 85% of spawns will be within 5 blocks of the pack center, and 99% within 10 blocks of the center.

All mobs within a pack are the same species. The species for the entire pack is chosen randomly from those eligible to spawn at the location of the first spawn attempt in the pack:

