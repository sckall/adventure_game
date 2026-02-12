class_name BTCompareBBEntries extends BTBlackboardBasedCondition

## Compares two blackboard entries
## Returns true if the comparison is met, false otherwise

enum Comparison {
	IS_EQUAL, # Check if values are equal
	IS_NOT_EQUAL # Check if values are not equal
}

## The type of comparison to perform
@export var _comparison: Comparison = Comparison.IS_EQUAL
## The key to compare against
@export var _other_key: StringName

func _tick(ctx: BTContext) -> bool:
	if not super (ctx):
		return false

	var is_equal: bool = ctx.blackboard.compare_values(_key, _other_key)

	if _comparison == Comparison.IS_EQUAL:
		return is_equal
	else:
		return not is_equal
