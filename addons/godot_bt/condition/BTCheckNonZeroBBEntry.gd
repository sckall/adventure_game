class_name BTCheckNonZeroBBEntry extends BTBlackboardBasedCondition

## Checks if a blackboard value is non-zero or non-empty
## Returns true if the value exists and is not zero/empty, false otherwise

func _tick(ctx: BTContext) -> bool:
	if not super (ctx):
		return false

	return not ctx.blackboard.is_zero_or_empty(_key)
