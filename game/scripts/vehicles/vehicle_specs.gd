class_name VehicleSpecs
extends RefCounted
## Looks up the spec for a Catalog vehicle id.


static func make(vehicle_id: String) -> VehicleSpec:
	match vehicle_id:
		"pickup":
			return PickupSpec.new()
		"monster":
			return MonsterSpec.new()
		"supercar":
			return SupercarSpec.new()
		"hatchback":
			return HatchbackSpec.new()
	push_error("Unknown vehicle id '%s', using the hatchback" % vehicle_id)
	return HatchbackSpec.new()
