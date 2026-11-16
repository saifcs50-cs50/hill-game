class_name Catalog
extends RefCounted
## Shared game data: vehicles, stages, upgrades and economy numbers.
## Every system (garage UI, vehicle physics, stages, save data) reads from here.

const COIN_VALUE := 5
const MAX_UPGRADE_LEVEL := 10
const UPGRADE_GROWTH := 1.32
const UPGRADE_KEYS: Array[String] = ["engine", "suspension", "tyres", "fuel"]
const UPGRADE_NAMES := {
	"engine": "Engine",
	"suspension": "Suspension",
	"tyres": "Tyres",
	"fuel": "Fuel tank",
}

## stats are 1-5 for the garage UI only; physics numbers live in each vehicle's spec.
const VEHICLES := {
	"hatchback": {
		"name": "Hatchback", "price": 0, "upgrade_base": 120,
		"blurb": "Light, cheap and cheerful. Flips easily.",
		"stats": {"speed": 2, "grip": 2, "stability": 2},
	},
	"pickup": {
		"name": "4x4 Pickup", "price": 2500, "upgrade_base": 180,
		"blurb": "All-wheel drive and a long wheelbase. Climbs anything.",
		"stats": {"speed": 3, "grip": 4, "stability": 4},
	},
	"monster": {
		"name": "Monster Truck", "price": 8000, "upgrade_base": 260,
		"blurb": "Huge wheels, soft springs, rolls over everything.",
		"stats": {"speed": 3, "grip": 4, "stability": 3},
	},
	"supercar": {
		"name": "Supercar", "price": 15000, "upgrade_base": 340,
		"blurb": "Blistering on smooth ground. Terrible on bumps.",
		"stats": {"speed": 5, "grip": 3, "stability": 2},
	},
}
const VEHICLE_ORDER: Array[String] = ["hatchback", "pickup", "monster", "supercar"]

## gravity in px/s^2 (100 px = 1 m); friction is the ground's surface friction.
const STAGES := {
	"meadow": {
		"name": "Meadow", "price": 0, "gravity": 820.0, "friction": 1.0,
		"blurb": "Rolling hills at sunset. Gentle to start, steep later.",
	},
	"desert": {
		"name": "Desert", "price": 1500, "gravity": 820.0, "friction": 0.85,
		"blurb": "Long dunes and big jumps. Fuel is scarce.",
	},
	"arctic": {
		"name": "Arctic", "price": 5000, "gravity": 820.0, "friction": 0.45,
		"blurb": "Icy slopes under the northern lights. Grip is everything.",
	},
	"moon": {
		"name": "Moon", "price": 12000, "gravity": 300.0, "friction": 0.9,
		"blurb": "Low gravity. Enormous air time, easy to over-rotate.",
	},
}
const STAGE_ORDER: Array[String] = ["meadow", "desert", "arctic", "moon"]


## Coins needed to go from `level` to `level + 1`.
static func upgrade_cost(vehicle_id: String, level: int) -> int:
	var base: int = VEHICLES[vehicle_id]["upgrade_base"]
	return int(roundf(base * pow(UPGRADE_GROWTH, level) / 10.0)) * 10


## Multiplier or 0..1 quality for an upgrade at a level (0 = stock).
## engine: drive torque and top speed multiplier; tyres: grip multiplier;
## fuel: tank size multiplier; suspension: 0..1 quality used to soften and stabilise.
static func upgrade_effect(key: String, level: int) -> float:
	match key:
		"engine":
			return 1.0 + 0.07 * level
		"tyres":
			return 1.0 + 0.05 * level
		"fuel":
			return 1.0 + 0.1 * level
		"suspension":
			return float(level) / MAX_UPGRADE_LEVEL
	push_error("Unknown upgrade key: %s" % key)
	return 1.0
