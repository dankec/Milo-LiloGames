extends RefCounted
## Five authored platformer layouts. Ground is continuous so younger children cannot softlock.

const TITLES := ["Sunčana livada", "Šuma skrivenih staza", "Špilja kristala", "Mjesečeva šuma", "Zaboravljeni svjetionik"]
const THEMES := ["meadow", "forest", "cave", "night", "lighthouse"]
const GOALS := ["Nauči promijeniti prijatelja i pronađi izlaz", "Pronađi ključ, riješi prolaz i osvoji prvi kristal", "Lilo mora otvoriti kamena vrata i pronaći kristal", "Skupi bobice prije isteka vremena i otkrij treći kristal", "Zajedno savladajte čuvara i upalite svjetionik"]

static func get_level(index: int) -> Dictionary:
	var platforms: Array = []
	var coins: Array = []
	var enemies: Array = []
	var gifts: Array = []
	var jumps := [320, 610, 880, 1190, 1480, 1760, 2080]
	var elevations := [515, 440, 510, 405, 500, 430, 520]
	for i in jumps.size():
		var y: float = elevations[i] - (30 if index == 2 else 0)
		platforms.append({"x": jumps[i], "y": y, "w": 165 + (i % 2) * 55, "h": 30})
		for c in 3:
			coins.append(Vector2(jumps[i] + 38 + 46 * c, y - 48))
	for x in [205, 545, 815, 1030, 1380, 1655, 1950, 2210]:
		coins.append(Vector2(x, 594))
	if index > 0:
		for j in range(2 + index):
			enemies.append({"x": 475.0 + 370.0 * j, "y": 606.0, "patrol": 95.0, "hp": 1 if index < 4 else 2})
	if index >= 1 and index <= 3:
		gifts.append({"x": 950.0, "y": 605.0, "ability": ["double_jump", "shield", "magnet"][index - 1]})
	var berries: Array = []
	if index == 3:
		for i in 6:
			berries.append(Vector2(1410 + i * 78, 592))
	return {
		"title": TITLES[index], "theme": THEMES[index], "goal": GOALS[index],
		"width": 2630.0, "platforms": platforms, "coins": coins,
		"enemies": enemies, "gifts": gifts, "gate_x": 1850.0,
		"key": Vector2(1330, 590) if index == 1 else Vector2(-900, -900),
		"map": Vector2(1090 + index * 75, 350) if index >= 1 and index <= 3 else Vector2(-900, -900),
		"crystal": Vector2(2170, 571) if index >= 1 and index <= 3 else Vector2(-900, -900),
		"chest": Vector2(2320, 594), "exit_x": 2485.0,
		"berries": berries
	}
