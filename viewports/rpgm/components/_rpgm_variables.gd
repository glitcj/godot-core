@tool # This allows the static logic to run safely in the editor
extends _RPGM_Node
class_name _RPGM_Variables


# CLAUDE: save/load P1 — the single source of truth for global game state is
# now this dictionary (serialized as-is by _RPGM.collect_state). The old
# static ints survive as property wrappers so every existing call site
# (get_variables().l2_enemies_count etc.) keeps working unchanged.
static var variables : Dictionary = {
	"l1_enemies_count": 0,
	"l2_enemies_count": 0,
	"l3_enemies_count": 0,
	"l4_enemies_count": 0,
}

static var l1_enemies_count : int:
	get: return variables.get("l1_enemies_count", 0)
	set(v): variables["l1_enemies_count"] = v
static var l2_enemies_count : int:
	get: return variables.get("l2_enemies_count", 0)
	set(v): variables["l2_enemies_count"] = v
static var l3_enemies_count : int:
	get: return variables.get("l3_enemies_count", 0)
	set(v): variables["l3_enemies_count"] = v
static var l4_enemies_count : int:
	get: return variables.get("l4_enemies_count", 0)
	set(v): variables["l4_enemies_count"] = v
