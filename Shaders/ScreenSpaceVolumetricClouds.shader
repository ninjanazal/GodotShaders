shader_type spatial;
render_mode unshaded, shadows_disabled;

uniform float depthNear = 0.05;
uniform float depthFar = 100.0;

// Volume dimentions
uniform vec3 boundsMin;
uniform vec3 boundsMax;

//  Noise textures
uniform int oct : hint_range(1, 100, 1) = 1;
uniform float pers = 1.0;
uniform float frequency = 1.0;

uniform float containerEdgeFadeDst = 50.0;

uniform float gMin = 0.2;
uniform float gMax = 0.7;

// Detail Noise textures
uniform int DetailOct : hint_range(1, 100, 1) = 1;
uniform float DetailPers = 1.0;
uniform float DetailFrequency = 1.0;
uniform float detailNoiseScale = 2.0;
uniform vec3 detailOffset = vec3(0.0);
uniform vec3 detailWeights = vec3(1.0);
uniform float detailNoiseWeight;


uniform vec3 cloudOffset;
uniform float cloudScale;
uniform float densityMultiplier : hint_range(0.0, 50.0, 0.01) = 0.1;
uniform int stepCounter : hint_range(2, 256, 1);

uniform float timeScale : hint_range(0.0, 100.0, 0.01) = 0.5;
uniform float baseSpeed : hint_range(0.0, 10.0, 0.01) = 2.0;
uniform float detailSpeed = 1.5;

uniform vec4 shapeNoiseWeights = vec4(1.0);
uniform float densityOffset = 0.0;

// * * * * * * * * * * * * * * * * * * * *

varying vec3 cameraPositionW;		//World Camera position
varying vec3 cameraViewDir;	// World Camera fragment view direction

// * * * * * * * * * * * * * * * * * * * *

float map(float s, float a1, float a2, float b1, float b2)
{ return b1 + (s-a1)*(b2-b1)/(a2-a1); }

float saturate(float x) { return max(0.0, min(1.0, x)); }

// * * * * * * * * * * * * * * * * * * * *
// NOISE 3D
// Based on https://www.shadertoy.com/view/4dBcWy


vec3 mod289V3(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289V4(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }

vec4 permute(vec4 x) { return mod289V4(((x*34.0)+1.0)*x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) { 
	const vec2  C = vec2(0.1666666666666667, 0.3333333333333333) ; // 1.0/6.0, 1.0/3.0
	const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);
	vec3 i  = floor(v + dot(v, C.yyy) );
	vec3 x0 =   v - i + dot(i, C.xxx) ;

	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min( g.xyz, l.zxy );
	vec3 i2 = max( g.xyz, l.zxy );

	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
	vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

	i = mod289V3(i);
	vec4 p = permute( permute( permute( 
			i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
			+ i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
			 + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

	float n_ = 0.142857142857; // 1.0/7.0
	vec3  ns = n_ * D.wyz - D.xzx;

	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

	vec4 x = x_ *ns.x + ns.yyyy;
	vec4 y = y_ *ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);

	vec4 b0 = vec4( x.xy, y.xy );
	vec4 b1 = vec4( x.zw, y.zw );

	vec4 s0 = floor(b0)*2.0 + 1.0;
	vec4 s1 = floor(b1)*2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));

	vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
	vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

	vec3 p0 = vec3(a0.xy,h.x);
	vec3 p1 = vec3(a0.zw,h.y);
	vec3 p2 = vec3(a1.xy,h.z);
	vec3 p3 = vec3(a1.zw,h.w);

	vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;

	vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
	m = m * m;
	return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
						dot(p2,x2), dot(p3,x3) ) );
}


float getnoise(int octaves, float persistence, float freq, vec3 coords) {
	float amp= 1.; 
	float maxamp = 0.;
	float sum = 0.;

	for (int i=0; i < octaves; ++i) {
		sum += amp * snoise(coords*freq); 
		freq *= 2.;
		maxamp += amp;
		amp *= persistence;
	}
	return (sum / maxamp) * .5 + .5;
}

// * * * * * * * * * * * * * * * * * * * *


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

float sampleDensityVal(vec3 pos) {
	float baseScane = 1.0 / 1000.0;
	float offsetSpeed = 1.0 / 100.0;
	
	float time = TIME * timeScale;
	vec3 size = boundsMax - boundsMin;
	vec3 boundCenter = (boundsMin + boundsMax) * 0.5;
	
	vec3 uvw = (size * 0.5 + pos) * baseScane * cloudScale;
	vec3 shapeSmaplePos = uvw + cloudOffset * offsetSpeed + vec3(time, time * 0.1, time * 0.2) * baseSpeed;
	
	// Falloff calculation along edges
	float dstFromEdgeX = min(containerEdgeFadeDst, min(pos.x - boundsMin.x, boundsMax.x - pos.x));
	float dstFromEdgeZ = min(containerEdgeFadeDst, min(pos.z - boundsMin.z, boundsMax.z - pos.z));
	float edgeWeight = min(dstFromEdgeZ, dstFromEdgeX) / containerEdgeFadeDst;
	
	// Height gradient
	float heightPercent = (pos.y - boundsMin.y) / size.y;
	float heightGradient = gMin *
		saturate(map(heightPercent, 1.0, gMax, 0.0, 1.0));
	heightGradient *= edgeWeight;
	
	// base shape density
	vec4 shapeNoise = vec4(getnoise(oct, pers, frequency, shapeSmaplePos));
	vec4 normalizedShapeWeights = shapeNoiseWeights / dot(shapeNoiseWeights, vec4(1.0));
	float shapeFBM = dot(shapeNoise, normalizedShapeWeights) * heightGradient;
	float baseShapeDensity = shapeFBM + densityOffset * 0.1;
	
	 // Save sampling from detail tex if shape density <= 0
	if(baseShapeDensity > 0.0) {
		// sample detail noise
		vec3 detailSamplePos = uvw * detailNoiseScale + detailOffset * offsetSpeed + vec3(time * 0.4, -time, time * 0.1) * detailSpeed;
		vec4 detailNoise = vec4(getnoise(DetailOct, DetailPers, DetailFrequency, detailSamplePos));
		vec3 normalizedDetailWeights = detailWeights / dot(detailWeights, vec3(1.0));
		float detailFBM = dot(detailNoise.xyz, normalizedDetailWeights);
		
		float oneMinusShape = 1.0 - shapeFBM;
		float detailErodeWeight = pow(oneMinusShape, 3);
		float cloudDensity = baseShapeDensity - (1.0 - detailFBM) * detailErodeWeight * detailNoiseWeight;
		
		return cloudDensity * densityMultiplier * 0.1;
	}
	return 0.0;
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
	//vec3 sampleCol2 = texture(SCREEN_TEXTURE, SCREEN_UV - 0.002).xyz;
	
	// From godot docs
	// https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html
	float depthDistance = calculateDeptDistance(
									texture(DEPTH_TEXTURE, SCREEN_UV, 0.).x,
									SCREEN_UV, CAMERA_MATRIX * INV_PROJECTION_MATRIX,
									cameraPositionW);
	
	float normalDepthDst = map(depthDistance, depthNear, depthFar, 0., 1.);
	//if(length(sampleCol - sampleCol2) > 0.1) { sampleCol = vec3(0.); }
	
	vec2 rayHitInfo = rayVolumeDistance(boundsMin, boundsMax, cameraPositionW, cameraViewDir);
	float distanceToVol = rayHitInfo.x;
	float distanceToExit = rayHitInfo.y;
	
	bool didHit = distanceToExit > 0.0;
	//if(didHit && distanceToVol < depthDistance) { sampleCol /= vec3(normalDepthDst); }
	
	
	float dstTravelled = 0.;
	float stepSize = distanceToExit / float(stepCounter);
	float dstLimit = min(depthDistance - distanceToVol, distanceToExit);
	float totalDensity = 0.;
	while (dstTravelled < dstLimit) {
		vec3 rayPos = cameraPositionW + cameraViewDir * (distanceToVol + dstTravelled);
		totalDensity += sampleDensityVal(rayPos) * stepSize;
		dstTravelled += stepSize;
	}
	float transmittance = exp(-totalDensity);
	ALBEDO = sampleCol * transmittance;

}