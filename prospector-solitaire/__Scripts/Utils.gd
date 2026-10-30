class_name Utils extends Node

enum BoundsTest {
	CENTER = 1,
	ON_SCREEN = 2,
	OFF_SCREEN =3
}

static var _easing_cashe : Dictionary = {}
static var _cam_bounds : AABB = AABB()

# # # # # # # Bounds Function # # # # # # # #

static func BoundsUnion(b0 : AABB, b1 : AABB) -> AABB:
	if b0.size.is_zero_approx() && !b1.size.is_zero_approx():
		return b1
	elif !b0.size.is_zero_approx() && b1.size.is_zero_approx():
		return b0
	elif b0.size.is_zero_approx() && b1.size.is_zero_approx():
		return b0
	
	b0 = b0.expand(b1.position)
	b0 = b0.expand(b1.position + b1.size)
	return b0

static func CombineBoundsOfChildren(node : Node3D) -> AABB:
	var b : AABB = AABB()
	
	if node is Sprite3D:
		var sprite_aabb : AABB = node.get_aabb()
		b = BoundsUnion(b, sprite_aabb)
	
	var collision_shape = node.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape && collision_shape.shape:
		var shape_aabb_local : AABB = collision_shape.shape.get_aabb()
		var world_aabb = _aabb_from_local_to_world(collision_shape, shape_aabb_local)
		b = BoundsUnion(b, world_aabb)
	
	for child in node.get_children():
		if child is Node3D:
			b = BoundsUnion(b, CombineBoundsOfChildren(child))
	
	return b

static func _aabb_from_local_to_world(node : Node3D, local_aabb : AABB) -> AABB:
	var min_world = node.to_global(local_aabb.position)
	var max_world = node.to_global(local_aabb.position + local_aabb.size)
	return AABB(min_world, max_world - min_world)

static func camBounds() -> AABB:
	#if _cam_bounds.size.is_zero_approx():
	#	SetCamBounds()
	return _cam_bounds

static func SetCamBounds(camera : Camera3D, viewport : Viewport) -> void:
	var screen_w : float = viewport.size.x
	var screen_h : float = viewport.size.y
	
	var top_left_screen : Vector3 = Vector3(0, screen_h, 0)
	var bottom_right_screen : Vector3 = Vector3(screen_w, 0, 0)
	
	var un_pr : Vector2 = camera.unproject_position(top_left_screen)
	var world_tl : Vector3 = Vector3(un_pr.x, un_pr.y, camera.near)
	
	un_pr = camera.unproject_position(bottom_right_screen)
	var world_br : Vector3 = Vector3(un_pr.x, un_pr.y, camera.far)
	
	var center : Vector3 = (world_tl + world_br) * 0.5
	_cam_bounds = AABB(center, Vector3.ZERO)
	_cam_bounds = _cam_bounds.expand(world_tl)
	_cam_bounds = _cam_bounds.expand(world_br)

static func ScreenBoundsCheck(bnd : AABB, test : BoundsTest = BoundsTest.CENTER) -> Vector3:
	var cam_aab : AABB = camBounds()
	return BoundsInBoundsCheck(cam_aab, bnd, test)

static func is_point_in_aabb(p : Vector3, aabb_min : Vector3, aabb_max : Vector3) -> bool:
	return (p.x >= aabb_min.x && p.x <= aabb_max.x) && (p.y >= aabb_min.y && p.y <= aabb_max.y) && (p.z >= aabb_min.z && p.z <= aabb_max.z)

static func BoundsInBoundsCheck(big_b : AABB, lil_b : AABB, test : BoundsTest = BoundsTest.ON_SCREEN) -> Vector3:
	var lil_center : Vector3 = lil_b.position + lil_b.size * 0.5
	var big_min : Vector3 = big_b.position
	var big_max : Vector3 = big_b.position + big_b.size
	var lil_min : Vector3 = lil_b.position
	var lil_max : Vector3 = lil_b.position + lil_b.size
	
	var off : Vector3 = Vector3.ZERO
	
	match test:
		BoundsTest.CENTER:
			if is_point_in_aabb(lil_center, big_min, big_max):
				return Vector3.ZERO
				
			if lil_center.x > big_max.x:
				off.x = lil_center.x - big_max.x
			elif lil_center.x < big_min.x:
				off.x = lil_center.x - big_min.x
			
			if lil_center.y > big_max.y:
				off.y = lil_center.y - big_max.y
			elif lil_center.y < big_min.y:
				off.y = lil_center.y - big_min.y
			
			if lil_center.z > big_max.z:
				off.z = lil_center.z - big_max.z
			elif lil_center.z < big_min.z:
				off.z = lil_center.z - big_min.z
			
			return off
		BoundsTest.ON_SCREEN:
			var min_inside : bool = is_point_in_aabb(lil_min, big_min, big_max)
			var max_inside : bool = is_point_in_aabb(lil_max, big_min, big_max)
			if min_inside && max_inside:
				return Vector3.ZERO
			
			if lil_max.x > big_max.x:
				off.x = lil_max.x - big_max.x
			elif lil_min.x < big_min.x:
				off.x = lil_min.x - big_min.x
			
			if lil_max.y > big_max.y:
				off.y = lil_max.y - big_max.y
			elif lil_min.y < big_min.y:
				off.y = lil_min.y - big_min.y
			
			if lil_max.z > big_max.z:
				off.z = lil_max.z - big_max.z
			elif lil_min.z < big_min.z:
				off.z = lil_min.z - big_min.z
			
			return off
		BoundsTest.OFF_SCREEN:
			var min_inside : bool = is_point_in_aabb(lil_min, big_min, big_max)
			var max_inside : bool = is_point_in_aabb(lil_max, big_min, big_max)
			
			if min_inside || max_inside:
				return Vector3.ZERO
			
			if lil_min.x > big_max.x:
				off.x = lil_min.x - big_max.x
			elif lil_max.x < big_min.x:
				off.x = lil_max.x - big_min.x
			
			if lil_min.y > big_max.y:
				off.y = lil_min.y - big_max.y
			elif lil_max.y < big_min.y:
				off.y = lil_max.y - big_max.y
			
			if lil_min.z > big_max.z:
				off.z = lil_min.z - big_max.z
			elif lil_max.z < big_min.z:
				off.z = lil_max.z - big_min.z
			
			return off
	
	return Vector3.ZERO

# # # # # # # Tramform function # # # # # # # #

static func FindTaggedParent(node : Node, group_name : String) -> Node:
	if node.is_in_group(group_name):
		return node
	if node.get_parent() == null:
		return null
	return FindTaggedParent(node.get_parent(), group_name)

# # # # # # # Material Function # # # # # # # #

static func GetAllMaterials(go : Node) -> Array:
	var mats : Array = []
	collect_materials(go, mats)
	return mats

static func collect_materials(node : Node, mats : Array) -> void:
	if node is MeshInstance3D:
		#if node.material_override:
			#mats.append(node.material_override)
		for i in range(node.get_surface_override_material_count()):
			var m : StandardMaterial3D = node.get_active_material(i)
			if m:
				m = m.duplicate()
				mats.append(m)
				node.set_surface_override_material(i, m)
				mats.append(m)
	elif node is Sprite3D:
		var mat = node.material_overlay
		if mat:
			mats.append(mat)
	
	for child in node.get_children():
		collect_materials(child, mats)

# # # # # # # Bezier Curves # # # # # # # #

static func BezierImpl(u : float, vList : Array[Vector3], i0 : int = 0, i1 : int = -1) -> Vector3:
	if i1 == -1:
		i1 = vList.size() - 1
	if i0 == i1:
		return vList[i0]
	
	var left : Vector3 = Bezier(u, vList, i0, i1 - 1)
	var right : Vector3 = Bezier(u, vList,i0 + 1, i1)
	
	return left.lerp(right, u)

static func Bezier(u : float, ...varargs) -> Vector3:
	for v in varargs:
		if !(v is Vector3):
			push_error("Bezier_2: argument not Vector3")
			return Vector3.ZERO
	return BezierImpl(u, varargs)

static func Bezier_v2(u : float, arV2 : Array[Vector2]) -> Vector2:
	#for v in varargs:
		#if not (v is Array[Vector2]):
			#push_error("Bezier_v2: arguments not Vector2")
			#return Vector2.ZERO
	return BezierImpl_v2(u, arV2)

static func BezierImpl_v2(u : float, vList : Array[Vector2], i0 : int = 0, i1 : int = -1) -> Vector2:
	if vList.is_empty():
		push_error("BezierImpl_v2: vList is empty")
		return Vector2.ZERO
	if i1 == -1:
		i1 = vList.size() - 1
	
	if i0 == i1:
		return vList[i0]
	
	var left : Vector2 = BezierImpl_v2(u, vList, i0, i1 - 1)
	var right : Vector2 = BezierImpl_v2(u, vList, i0 + 1, i1)
	
	return left.lerp(right, u) 

static func Bezier_f(u : float, ...varargs) -> float:
	for v in varargs:
		if typeof(v) != TYPE_FLOAT && typeof(v) != TYPE_INT:
			push_error("Bezier_f: arguments not float")
			return 0.0
	return BezierImpl_f(u, varargs)

static func BezierImpl_f(u : float, vList : Array, i0 : int = 0, i1 : int = -1) -> float:
	if i1 == -1:
		i1 = vList.size() - 1
	if i0 == i1:
		return float(vList[i0])
	
	var left : float = BezierImpl_f(u, vList, i0, i1 - 1)
	var right : float = BezierImpl_f(u, vList, i0 + 1, i1)
	
	return lerpf(left, right, u)

static func  _slerp_unclamped(a : Quaternion, b : Quaternion, t : float) -> Quaternion:
	var dot : float = a.dot(b)
	
	if dot < 0.0:
		b = -b
		dot = -dot
	
	dot = clamp(dot, -1.0, 1.0)
	var theta : float = acos(dot)
	
	if theta < 0.0001:
		return (a + (b - a) * t).normalized()
	
	var sin_theta : float = sin(theta)
	var inv_sin_theta = 1.0 / sin_theta
	
	var k0 : float = sin((1.0 - t) * theta) * inv_sin_theta
	var k1 : float = sin(t * theta) * inv_sin_theta
	
	return (a * k0 + b * k1).normalized()

static func BezierImpl_q(u : float, points : Array[Quaternion], i0 : int = 0, i1 : int = -1) -> Quaternion:
	if i1 == -1:
		i1 = points.size() - 1
	if i0 == i1:
		return points[i0]
	if points.size() == 0:
		return Quaternion.IDENTITY
	var left : Quaternion = BezierImpl_q(u, points, i0, i1 - 1)
	var right : Quaternion = BezierImpl_q(u, points, i0 + 1, i1)
	return _slerp_unclamped(left, right, u)

static func Bezier_q(u : float, ...varargs) -> Quaternion:
	for v in varargs:
		if !(v is Quaternion):
			push_error("Bezier_q: argumints not Quaternion")
			return Quaternion.IDENTITY
	
	return BezierImpl_q(u, varargs)

# # # # # # # Trace & Logging Functions # # # # # # # #

static func debug_tr(...varargs) -> void:
	if varargs.size() == 0:
		print ("Utils.debug_tr: NULL")
		return
	
	print ("Utils.debug_tr: \t")
	for v in varargs:
		print (str(varargs[v]) + "\t")
	

# # # # # # # Math Functions # # # # # # #

static func RoundToPlaces(f : float, places : int =2) -> float:
	if places < 0:
		places = 0
	
	var mult : float = pow(10.0, places)
	f *= mult
	f = round(f)
	f /= mult
	return f

static func AddCommasToNumber(f : float, places : int = 2) -> String:
	var n : int = roundi(f)
	f -= n
	f = RoundToPlaces(f, places)
	var s : String = AddCommasToNumberInt(n)
	s += "." + str(f * pow(10.0, places))
	return s

static func AddCommasToNumberInt(n : int) -> String:
	var rem : int
	var div : int
	var res : String = ""
	var rems : String
	while n > 0:
		rem = n % 1000
		div = n / 1000
		rems = str(rem)
		
		while div > 0 && rems.length() < 3:
			rems = "0" + rems
		if res == "":
			res = rems
		else:
			res = rems + "," + res
		n = div
	if res == "":
		res = "0"
	return res

# # # # # # # Easing Classes # # # # # # # #
