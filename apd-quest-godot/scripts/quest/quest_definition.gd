extends RefCounted
class_name QuestDefinition
## Szablon questu (template) z data/quests.json — wieczny; runy są osobne.

var id: String = ""
var title: String = ""
var npc_id: String = ""
var exercise_type: String = ""
var dialog_offer: PackedStringArray = PackedStringArray()
var dialog_offer_again: PackedStringArray = PackedStringArray()
var dialog_done: PackedStringArray = PackedStringArray()
var noise_optional: bool = true
var reward_points: int = 10
var reward_points_repeat: int = 10
## "infinite" | "daily_pool" — oba odnawialne; daily_pool respektuje soft cap.
var renewal: String = "infinite"
var daily_soft_cap: int = 6


static func from_dict(d: Dictionary) -> QuestDefinition:
	var q := new()
	q.id = str(d.get("id", ""))
	q.title = str(d.get("title", ""))
	q.npc_id = str(d.get("npc_id", ""))
	q.exercise_type = str(d.get("exercise_type", ""))
	q.noise_optional = bool(d.get("noise_optional", true))
	q.reward_points = int(d.get("reward_points", 10))
	q.reward_points_repeat = int(d.get("reward_points_repeat", q.reward_points))
	q.renewal = str(d.get("renewal", "infinite"))
	q.daily_soft_cap = int(d.get("daily_soft_cap", 6))
	for line in d.get("dialog_offer", []):
		q.dialog_offer.append(str(line))
	for line in d.get("dialog_offer_again", []):
		q.dialog_offer_again.append(str(line))
	for line in d.get("dialog_done", []):
		q.dialog_done.append(str(line))
	return q
