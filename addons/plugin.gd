@tool
extends EditorPlugin

var bt_info_panel: Control

func _enter_tree():
	# Register base classes
	add_custom_type("BehaviorTree", "Node", preload("res://addons/godot_bt/BehaviorTree.gd"), preload("res://addons/godot_bt/icons/bt.svg"))
	add_custom_type("BTNode", "Node", preload("res://addons/godot_bt/BTNode.gd"), preload("res://addons/godot_bt/icons/btnode.svg"))
	add_custom_type("BTComposite", "Node", preload("res://addons/godot_bt/BTComposite.gd"), preload("res://addons/godot_bt/icons/btcomposite.svg"))
	add_custom_type("BTTask", "Node", preload("res://addons/godot_bt/BTTask.gd"), preload("res://addons/godot_bt/icons/btleaf.svg"))

	# Register composite nodes
	add_custom_type("BTSelector", "Node", preload("res://addons/godot_bt/composite/BTSelector.gd"), preload("res://addons/godot_bt/icons/btselector.svg"))
	add_custom_type("BTSequence", "Node", preload("res://addons/godot_bt/composite/BTSequence.gd"), preload("res://addons/godot_bt/icons/btsequence.svg"))
	add_custom_type("BTParallel", "Node", preload("res://addons/godot_bt/composite/BTParallel.gd"), preload("res://addons/godot_bt/icons/btparallel.svg"))
	add_custom_type("BTRandomSelector", "Node", preload("res://addons/godot_bt/composite/BTRandomSelector.gd"), preload("res://addons/godot_bt/icons/btrndselector.svg"))
	add_custom_type("BTRandomSequence", "Node", preload("res://addons/godot_bt/composite/BTRandomSequence.gd"), preload("res://addons/godot_bt/icons/btrndsequence.svg"))

	# Register decorator resources
	add_custom_type("BTDecorator", "Resource", preload("res://addons/godot_bt/BTDecorator.gd"), preload("res://addons/godot_bt/icons/btdecorator.svg"))
	add_custom_type("BTInverter", "Resource", preload("res://addons/godot_bt/decorator/BTInverter.gd"), preload("res://addons/godot_bt/icons/btrevert.svg"))
	add_custom_type("BTRepeater", "Resource", preload("res://addons/godot_bt/decorator/BTRepeater.gd"), preload("res://addons/godot_bt/icons/btrepeat.svg"))
	add_custom_type("BTAlwaysReturn", "Resource", preload("res://addons/godot_bt/decorator/BTAlwaysReturn.gd"), preload("res://addons/godot_bt/icons/btalways.svg"))
	add_custom_type("BTRepeatUntil", "Resource", preload("res://addons/godot_bt/decorator/BTRepeatUntil.gd"), preload("res://addons/godot_bt/icons/btrepeatuntil.svg"))

	# Register condition resources
	add_custom_type("BTCondition", "Resource", preload("res://addons/godot_bt/BTCondition.gd"), preload("res://addons/godot_bt/icons/btconditional.png"))
	add_custom_type("BTReactiveCondition", "Resource", preload("res://addons/godot_bt/condition/BTReactiveCondition.gd"), preload("res://addons/godot_bt/icons/btconditional.png"))
	add_custom_type("BTBlackboardBasedCondition", "Resource", preload("res://addons/godot_bt/condition/BTBlackboardBasedCondition.gd"), preload("res://addons/godot_bt/icons/btconditional.png"))
	add_custom_type("BTCheckNonZeroBBEntry", "Resource", preload("res://addons/godot_bt/condition/BTCheckNonZeroBBEntry.gd"), preload("res://addons/godot_bt/icons/btconditional.png"))
	add_custom_type("BTCompareBBEntries", "Resource", preload("res://addons/godot_bt/condition/BTCompareBBEntries.gd"), preload("res://addons/godot_bt/icons/btconditional.png"))

	# Register service resources
	add_custom_type("BTService", "Resource", preload("res://addons/godot_bt/BTService.gd"), preload("res://addons/godot_bt/icons/btparallel.svg"))

	# Register task nodes
	add_custom_type("BTWait", "Node", preload("res://addons/godot_bt/task/BTWait.gd"), preload("res://addons/godot_bt/icons/btwait.svg"))

	# Register utility classes
	add_custom_type("BTTargetKey", "Resource", preload("res://addons/godot_bt/keys/BBTargetKey.gd"), null)

	# Register context and blackboard
	add_custom_type("BTContext", "RefCounted", preload("res://addons/godot_bt/BTContext.gd"), null)
	add_custom_type("Blackboard", "Resource", preload("res://addons/godot_bt/Blackboard.gd"), preload("res://addons/godot_bt/icons/blackboard.svg"))

# Plugin icon
func _get_plugin_icon():
	return preload("res://addons/godot_bt/icons/bt.svg")

# Plugin name
func _get_plugin_name():
	return "GodotBT"

func _exit_tree():
	# Remove base classes
	remove_custom_type("BehaviorTree")
	remove_custom_type("BTNode")
	remove_custom_type("BTComposite")
	remove_custom_type("BTTask")

	# Remove composite nodes
	remove_custom_type("BTSelector")
	remove_custom_type("BTSequence")
	remove_custom_type("BTParallel")
	remove_custom_type("BTRandomSelector")
	remove_custom_type("BTRandomSequence")

	# Remove decorator resources
	remove_custom_type("BTDecorator")
	remove_custom_type("BTInverter")
	remove_custom_type("BTRepeater")
	remove_custom_type("BTAlwaysReturn")
	remove_custom_type("BTRepeatUntil")

	# Remove condition resources
	remove_custom_type("BTCondition")
	remove_custom_type("BTReactiveCondition")
	remove_custom_type("BTBlackboardBasedCondition")
	remove_custom_type("BTCheckNonZeroBBEntry")
	remove_custom_type("BTCompareBBEntries")

	# Remove service resources
	remove_custom_type("BTService")

	# Remove task nodes
	remove_custom_type("BTWait")

	# Remove utility classes
	remove_custom_type("BTTargetKey")

	# Remove context and blackboard
	remove_custom_type("BTContext")
	remove_custom_type("Blackboard")
