shader_type spatial;
render_mode unshaded;

uniform bool enabled = false;
uniform int marchSteps : hint_range(0, 64, 1) = 5;
uniform float marchSize : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float radius = 6.0;

varying vec3 cameraPositionW;		//World Camera position
varying vec3 cameraViewDir;	// World Camera fragment view direction

varying vec3 objectCenterPosW;



bool sphereHit(vec3 point, vec3 center, float r){
	return (distance(point, center) < r);
}

vec3 MarchHit(vec3 startPos, vec3 objCenter, vec3 dir, mat4 WORLDMAT){
	for(int i = 0; i < marchSteps; i++){
		if(sphereHit(startPos, objCenter, radius)){
			return normalize((inverse(WORLDMAT) * vec4(startPos, 1.0)).xyz);
		}
		startPos += dir * marchSize;
	}
	return vec3(0.0);
}

void vertex() {
	// Gets the camera world position
	cameraPositionW = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	objectCenterPosW = (WORLD_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
}

void fragment() {
	// Fragment world position
	vec3 fragPosition = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 localFragPosition = (inverse(WORLD_MATRIX) * vec4(fragPosition, 1.0)).xyz;
	cameraViewDir = normalize(fragPosition - cameraPositionW);
	
	vec3 hitPixel = MarchHit(fragPosition, objectCenterPosW, cameraViewDir, WORLD_MATRIX);
			
	if(length(hitPixel) != 0.0){
		ALBEDO = vec3(hitPixel);
	}
	else{ discard; }
}