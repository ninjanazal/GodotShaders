shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform float depthNear = 0.05;
uniform float depthFar = 100.0;

// Volume dimentions
uniform vec3 boundsMin;
uniform vec3 boundsMax;

//  Noise textures
uniform sampler2D shapeNoiseTex;
uniform sampler2D detailNoiseTex;

// * * * * * * * * * * * * * * * * * * * *

varying vec3 cameraPositionW;		//World Camera position
varying vec3 cameraViewDir;	// World Camera fragment view direction

// * * * * * * * * * * * * * * * * * * * *

float map(float s, float a1, float a2, float b1, float b2)
{ return b1 + (s-a1)*(b2-b1)/(a2-a1); }

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

float calculateDeptDistance(float depthVal, vec2 ScreenUV, mat4 cam_innvProj_matrix, vec3 wCamPos){
	vec3 ndc = vec3(ScreenUV, depthVal) * 2.0 - 1.0;
	vec4 viewCamDist = cam_innvProj_matrix * vec4(ndc, 1.0);
	vec3 wPosition = viewCamDist.xyz /= viewCamDist.w;
	return distance(cameraPositionW, wPosition);
}

void vertex() {
	cameraPositionW = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
}
void fragment() {
	vec3 fragPosition = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 localFragPosition = (inverse(WORLD_MATRIX) * vec4(fragPosition, 1.0)).xyz;
	vec3 viewVector = fragPosition - cameraPositionW;
	cameraViewDir = normalize(viewVector);
	
	vec3 sampleCol = texture(SCREEN_TEXTURE, SCREEN_UV).xyz;
	vec3 sampleCol2 = texture(SCREEN_TEXTURE, SCREEN_UV - 0.002).xyz;
	
	// From godot docs
	// https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html
	float depthDistance = calculateDeptDistance(
									texture(DEPTH_TEXTURE, SCREEN_UV, 0.).x,
									SCREEN_UV, CAMERA_MATRIX * INV_PROJECTION_MATRIX,
									cameraPositionW);
	
	float normalDepthDst = map(depthDistance, depthNear, depthFar, 0., 1.);
	if(length(sampleCol - sampleCol2) > 0.1) { sampleCol = vec3(0.); }
	
	vec2 rayHitInfo = rayVolumeDistance(boundsMin, boundsMax, cameraPositionW, cameraViewDir);
	float distanceToVol = rayHitInfo.x;
	float distanceToExit = rayHitInfo.y;
	
	bool didHit = distanceToExit > 0.0;
	if(didHit && distanceToVol < depthDistance) { sampleCol /= vec3(normalDepthDst); }
	
	ALBEDO = sampleCol;
}