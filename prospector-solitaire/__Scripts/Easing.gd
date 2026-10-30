class_name  Easing

const Linear : String = ",Linear|"
const In     : String = ",In|"
const Out    : String = ",Out|"
const InOut  : String = ",InOut|"
const Sin    : String = ",Sin|"
const SinIn  : String = ",SinIn|"
const SinOut : String = ",SinOut|"

static var cache : Dictionary = {}

static func Ease(u : float, ...varargs) -> float:
	var u2 : float = u
	
	if varargs.is_empty():
		return u2
	
	if varargs.size() == 2 && varargs[0] is String:
		return EasyP(u, varargs[0], varargs[1])
	
	var curveParams : Array = varargs[0] if (varargs.size() == 1 && varargs[0] is Array) else varargs
	
	for curve in curveParams:
		if not cache.has(curve):
			EasyParse(curve)
		
		u = EasyP(u2, cache[curve])
	
	return u2

static func EasyParse(curveIn : String) -> void:
	var ecc : EasingCachedCurve = EasingCachedCurve.new()
	var curves : PackedStringArray = curveIn.split(",")
	
	for curve in curves:
		if curve == "": 
			continue
		
		var curveA : PackedStringArray = curve.split("|")
		ecc.curves.append(curve[0])
		if curveA.size() == 1 or curveA[1] == "":
			ecc.mods.append(NAN)
		elif curveA[1].is_valid_float():
			ecc.mods.append(curveA[1].to_float())
		else:
			ecc.mods.append(NAN)
	
	cache[curveIn] = ecc

static func EasyP(u : float, arg1, arg2 = null) -> float:
	if arg1 is EasingCachedCurve:
		var ec : EasingCachedCurve = arg1
		var u2_ : float = u
		for i in ec.curves.size():
			u2_ = EasyP(u2_, ec.curves[i], ec.mods[i])
		return u2_
	var curve : String = arg1
	var mod : float = NAN if arg2 == null else arg2
	var u2 : float = u
	
	match curve:
		"In":
			if is_nan(mod): mod = 2.0
			u2 = pow(u, mod)
		"Out":
			if is_nan(mod): mod = 2.0
			u2 = 1.0 - pow(1.0 - u, mod)
		"InOut":
			if is_nan(mod): mod = 2.0
			if u <= 0.5:
				u2 = 0.5 * pow(u * 2.0, mod)
			else:
				u2 = 0.5 + 0.5 * (1.0 - pow(1.0 - (2.0 * (u - 0.5)), mod))
		"Sin":
			if is_nan(mod): mod = 0.15
			u2 = u + mod * sin(2.0 * PI * u)
		"SinIn":
			u2 = 1.0 - cos(u * PI * 0.5)
		"SinOut":
			u2 = sin(u * PI * 0.5)
		"Linear", _:
			pass
	
	return u2
