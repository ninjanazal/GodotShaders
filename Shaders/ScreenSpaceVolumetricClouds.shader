shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform float depthNear = 0.05;
uniform float depthFar = 100.0;

// Help for disable/enable effect on editor
uniform int onEditor : hint_range(-1, 1, 1) = -1;
// Volume dimentions
uniform vec3 boundsMin;
uniform vec3 boundsMax;

varying vec3 cameraPositionW;		//World Camera position
varying vec3 cameraViewDir;	// World Camera fragment view direction

// Gets the distance to the volume and the distance to exit the volume from a defined 
vec2 rayVolumeDistance(vec3 minBounds, vec3 maxBounds, vec3 origin, vec3 direction){
	vec3 tBot = (minBounds - origin) / direction;
	vec3 tTop = (maxBounds - origin) / direction;
	
	vec3 tMin = min(tBot, tTop);
	vec3 tMax = max(tBot, tTop);
	
	float distA = max(max(tMin.x, tMin.y), tMin.z);
	float distB = min(tMax.x, min(tMax.y, tMax.z));
	
	float distanceToBound = max(0, distA);
	float distanceToExitBound = max(0, distB - distanceToBound);
	
	return vec2(distanceToBound, distanceToExitBound);
}



void vertex() {

	POSITION = vec4(VERTEX, float(onEditor));
	cameraPositionW = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
}
void fragment() {
	vec3 fragPosition = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 localFragPosition = (inverse(WORLD_MATRIX) * vec4(fragPosition, 1.0)).xyz;
	cameraViewDir = normalize(fragPosition - cameraPositionW);
	
	vec3 sampleCol = texture(SCREEN_TEXTURE, SCREEN_UV).xyz;
	
	// From godot docs
	// https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 depthView = INV_PROJECTION_MATRIX * vec4(ndc, 1.);
	depthView /= depthView.w;
	float scaledDepht = (depthFar * depthNear) / (depthFar + (depthView.z * (depthNear - depthFar)));

	ALBEDO =  vec3(scaledDepht) / sampleCol;
}