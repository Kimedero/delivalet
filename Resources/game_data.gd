extends Resource

var active_camera: Camera3D = null

#signal car_selected


func flatten_vec3(vec3: Vector3) -> Vector3:
	return Vector3(vec3.x, 0, vec3.z)
