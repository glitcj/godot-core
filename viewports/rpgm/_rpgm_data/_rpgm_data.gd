extends _Core_Data
class_name _RPGM_Data


# CLAUDE: save/load P1 — the single source of truth for global game state is
# now this dictionary (serialized as-is by _RPGM.collect_state). The old
# static ints survive as property wrappers so every existing call site
# (get_variables().l2_enemies_count etc.) keeps working unchanged.
static var rpgm_state_variables : Dictionary = {
	"l1_enemies_count": 0,
	"l2_enemies_count": 0,
	"l3_enemies_count": 0,
	"l4_enemies_count": 0,
}

static var l1_enemies_count : int:
	get: return rpgm_state_variables.get("l1_enemies_count", 0)
	set(v): rpgm_state_variables["l1_enemies_count"] = v
static var l2_enemies_count : int:
	get: return rpgm_state_variables.get("l2_enemies_count", 0)
	set(v): rpgm_state_variables["l2_enemies_count"] = v
static var l3_enemies_count : int:
	get: return rpgm_state_variables.get("l3_enemies_count", 0)
	set(v): rpgm_state_variables["l3_enemies_count"] = v
static var l4_enemies_count : int:
	get: return rpgm_state_variables.get("l4_enemies_count", 0)
	set(v): rpgm_state_variables["l4_enemies_count"] = v
