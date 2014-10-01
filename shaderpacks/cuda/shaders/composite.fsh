#version 120








/*

                                      █████████   ███████████   ████████████   ██████████   ██
									  █████████   ███████████   ████████████   ██████████   ██
                                      ██               ██       ██        ██   ██      ██   ██
                                      ██               ██       ██        ██   ██      ██   ██
                                      █████████        ██       ██        ██   ██████████   ██
									  █████████        ██       ██        ██   ██████████   ██
                                             ██        ██       ██        ██   ██           ██
	                                         ██        ██       ██        ██   ██           
                                      █████████        ██       ████████████   ██           ██
									  █████████        ██       ████████████   ██           ██

                                           Stop doing anything! Read first the agreement!
										   
                                                Please read this agreement carefully:

                                - You are allowed to make videos or pictures with my shaderpack.
                                - You are allowed to modify it ONLY for yourself!
								- If you donated me something, please DON'T share my MediaFire link!
                                - You are not allowed to claim my shaderpack as your own!
                                - You are not allowed to redistribute it!
                                - If you like to share my shaderpack, please share ONLY the minecraftforum.net link!
                                - You are not allowed to publish the modification!
                                - You are not allowed to reupload it!
                                - You are not allowed to earn money with it!

                                For YouTube:
                                - You are allowed to earn money with my shaderpack in your YouTube Video.
                                - If you modified something in my shaderpack, please say that it in your YouTube Video or description.

*/











/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////CONSTS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Don't touch these values, if you don't know, what you do!
const int       shadowMapResolution     = 512;
const int 		R8					    = 0;
const int 		gdepthFormat 			= R8;
const bool 		generateShadowMipmap 	= false;
const float 	centerDepthHalflife 	= 2.0f;
const float 	shadowIntervalSize 		= 4.0f;
const float     shadowDistance          = 80.0f;
const float	    sunPathRotation	        = -35.0f;
const float	    ambientOcclusionLevel   = 0.6f;
const float 	wetnessHalflife 		= 400.0f; //Nass zu trocken
const float 	drynessHalflife 		= 70.0f; //Trocken zu nass

#define SHADOW_MAP_BIAS 0.85

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////GET MATERIAL / VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

varying vec4 texcoord;
varying vec3 lightVector;
varying vec3 sunlight_color;
varying vec3 ambient_color;
varying float handItemLight;

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2D shadow;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float wetness;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform float centerDepthSmooth;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int worldTime;
uniform int fogMode;

float rainStrength = clamp(wetness, 0.0f, 1.0f)/1.0f;

float timefract = worldTime;
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset2  = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 13000.0, 13001.0) - 13000.0) / 1.0);
float TimeMidnight2 = ((clamp(timefract, 13000.0, 13001.0) - 13000.0) / 1.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);
float TimeMidnight3 = ((clamp(timefract, 12500.0, 13250.0) - 12500.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);
float TimeDay = TimeSunrise+ TimeNoon + TimeSunset;

float cdist(vec2 coord){
    return distance(coord,vec2(0.5))*2.0;
}

vec3 convertScreenSpaceToWorldSpace(vec2 co, float depth) {
    vec4 fragposition = gbufferProjectionInverse * vec4(vec3(co, depth) * 2.0 - 1.0, 1.0);
    fragposition /= fragposition.w;
    return fragposition.xyz;
}

vec3 convertCameraSpaceToScreenSpace(vec3 cameraSpace) {
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = 0.5 * NDCSpace + 0.5;
    return screenSpace;
}

float edepth(vec2 coord) {
	return texture2D(depthtex0,coord).z;
}

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}
vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

vec3 aux = texture2D(gaux1, texcoord.st).rgb;
vec3 sunPos = sunPosition;
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0f - 1.0f;

float pixeldepth = texture2D(depthtex0,texcoord.xy).x;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float shadowexit = 0.0;

float handlight = handItemLight;

float lightmap = pow(aux.r,3.0);
float torch_skylightmap = pow(aux.r,1.0);
float sky_lightmap = pow(aux.r,10.0);

// circle distribution for shadow filter
const vec2 circle_offsets[25] = vec2[25](vec2(-0.4894566f,-0.3586783f),
									vec2(-0.1717194f,0.6272162f),
									vec2(-0.4709477f,-0.01774091f),
									vec2(-0.9910634f,0.03831699f),
									vec2(-0.2101292f,0.2034733f),
									vec2(-0.7889516f,-0.5671548f),
									vec2(-0.1037751f,-0.1583221f),
									vec2(-0.5728408f,0.3416965f),
									vec2(-0.1863332f,0.5697952f),
									vec2(0.3561834f,0.007138769f),
									vec2(0.2868255f,-0.5463203f),
									vec2(-0.4640967f,-0.8804076f),
									vec2(0.1969438f,0.6236954f),
									vec2(0.6999109f,0.6357007f),
									vec2(-0.3462536f,0.8966291f),
									vec2(0.172607f,0.2832828f),
									vec2(0.4149241f,0.8816f),
									vec2(0.136898f,-0.9716249f),
									vec2(-0.6272043f,0.6721309f),
									vec2(-0.8974028f,0.4271871f),
									vec2(0.5551881f,0.324069f),
									vec2(0.9487136f,0.2605085f),
									vec2(0.7140148f,-0.312601f),
									vec2(0.0440252f,0.9363738f),
									vec2(0.620311f,-0.6673451f)
									);

									
// cel shading
/*

#define border 1.0

vec3 celshade(vec3 clrr) {
	//edge detect
	float d = edepth(texcoord.xy);
	float dtresh = 1/(far-near)/5000.0;	
	vec4 dc = vec4(d,d,d,d);
	vec4 sa;
	vec4 sb;
	sa.x = edepth(texcoord.xy + vec2(-pw,-ph)*border);
	sa.y = edepth(texcoord.xy + vec2(pw,-ph)*border);
	sa.z = edepth(texcoord.xy + vec2(-pw,0.0)*border);
	sa.w = edepth(texcoord.xy + vec2(0.0,ph)*border);
	
	//opposite side ssao_samples
	sb.x = edepth(texcoord.xy + vec2(pw,ph)*border);
	sb.y = edepth(texcoord.xy + vec2(-pw,ph)*border);
	sb.z = edepth(texcoord.xy + vec2(pw,0.0)*border);
	sb.w = edepth(texcoord.xy + vec2(0.0,-ph)*border);
	
	vec4 dd = abs(2.0* dc - sa - sb) - dtresh;
	dd = vec4(step(dd.x,0.0),step(dd.y,0.0),step(dd.z,0.0),step(dd.w,0.0));
	
	float e = clamp(dot(dd,vec4(0.5f,0.5f,0.5f,0.5f)),0.0,1.0);
	return clrr*e;
}

*/



float getnoise(vec2 pos) {
return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));

}











/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main() {
	
	//dynamic handlight
	//handlight = 0.0;

	float shadowexit = float(aux.g > 0.1 && aux.g < 0.3);
	float land = float(aux.g > 0.03);
	float iswater = float(aux.g > 0.04 && aux.g < 0.07);
	float translucent = float(aux.g > 0.3 && aux.g < 0.5);
	float hand = float(aux.g > 0.75 && aux.g < 0.85);
	
	vec3 color = texture2D(gcolor, texcoord.st).rgb;
	color = pow(color,vec3(2.2));
	vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 2.0f * pixeldepth - 1.0f, 1.0f);
	fragposition /= fragposition.w;
	float shading = 1.0f;
	float spec = 0.0;
	float time = float(worldTime);
	float transition_fading = 1.0-(clamp((time-12000.0)/500.0,0.0,1.0)-clamp((time-13000.0)/500.0,0.0,1.0) + clamp((time-22800.0)/400.0,0.0,1.0)-clamp((time-23400.0)/600.0,0.0,1.0));	//fading between sun/moon shadows
	
	if (land > 0.9 && isEyeInWater < 0.1) {
	
	float dist = length(fragposition.xyz);

	float shadingsharp = 0.0f;

	vec4 worldposition = vec4(0.0);
	vec4 worldpositionraw = vec4(0.0);
	worldposition = gbufferModelViewInverse * fragposition;	
	
	float xzDistanceSquared = worldposition.x * worldposition.x + worldposition.z * worldposition.z;
	float yDistanceSquared  = worldposition.y * worldposition.y;
	
	worldpositionraw = worldposition;
	worldposition = shadowModelView * worldposition;
	float comparedepth = -worldposition.z;
	worldposition = shadowProjection * worldposition;
	worldposition /= worldposition.w;
	
	float distb = sqrt(worldposition.x * worldposition.x + worldposition.y * worldposition.y);
	float distortFactor = (1.0f - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;
	worldposition.xy *= 1.0f / distortFactor;
	worldposition = worldposition * 0.5f + 0.5f;
	int vpsize = 0;
	float diffthresh = 1.0*distortFactor+iswater+translucent;
	float isshadow = 0.0;
	float ssample;

	float distof = clamp(1.0-dist/shadowDistance,0.0,1.0);
	float distof2 = clamp(1.0-dist/(shadowDistance*0.75),0.0,1.0);
	float shadow_fade = clamp(distof*12.0,0.0,1.0);
	float sss_fade = pow(distof2,0.2);
	float step = 1.0/shadowMapResolution;
	
		if (dist < shadowDistance) {

			if (shadowexit > 0.1) {
				shading = 1.0;
			} else {
			
			
			// shadow filter
				for(int i = 0; i < 25; i++){
				if (iswater > 0.9) {
					shadingsharp += (clamp(comparedepth - (0.05 + (texture2D(shadow, worldposition.st + circle_offsets[i]*step*10.0).z) * (256.0 - 0.05)), 0.0, diffthresh)/(diffthresh));				
				} else {
					shadingsharp += (clamp(comparedepth - (0.05 + (texture2D(shadow, worldposition.st + circle_offsets[i]*step).z) * (256.0 - 0.05)), 0.0, diffthresh)/(diffthresh));
				}
				}
				shadingsharp /= 25.0;
				shading = 1.0-shadingsharp;
				isshadow = 1.0;
			
			
			
			/*
				shading = (clamp(comparedepth - (0.05 + (texture2D(shadow, worldposition.st).z) * (256.0 - 0.05)), 0.0, diffthresh)/(diffthresh));
				shading = 1.0-shading;
			*/
			
			
			
			}
		}
		
	float ao = 1.0;
	
	
	
// ssao
/*

	const int ssao_samples = 6;
	const float ssao_sampledir = 6;	
	const float ssao_radius = 1.0;
	
	if (land > 0.9 && iswater < 0.9 && hand < 0.9) {
	
		vec3 norm = texture2D(gnormal,texcoord.xy).rgb*2.0-1.0;
		vec3 projpos = convertScreenSpaceToWorldSpace(texcoord.xy,pixeldepth); 
		
		float progress = 0.0;
		ao = 0.0;
		
		float projrad = clamp(distance(convertCameraSpaceToScreenSpace(projpos + vec3(ssao_radius,ssao_radius,ssao_radius)).xy,texcoord.xy),7.5*pw,60.0*pw);
		
		for (int i = 1; i < ssao_samples; i++) {
			for (int j = 1; j < ssao_sampledir; j++) {
				vec2 samplecoord = vec2(cos(progress),sin(progress))*(j/ssao_sampledir)*projrad + texcoord.xy;
				float sample = texture2D(depthtex0,samplecoord).x;
				vec3 sprojpos = convertScreenSpaceToWorldSpace(samplecoord,sample);
				float angle = pow(min(1.0-dot(norm,normalize(sprojpos-projpos)),1.0),2.0);
				float dist = pow(min(abs(ld(sample)-ld(pixeldepth)),0.015)/0.015,2.0);
				float temp = min(dist+angle,1.0);
				ao += pow(temp,3.0);
				//progress += (1.0-temp)/ssao_samples*3.14;
			}
			progress = i*10.256;
		}
		ao /= (ssao_samples-1)*(ssao_sampledir-1);
	}
	
*/



// Add custom sunlightcolor/shadowcolor
	
    vec3 sunlight_sunrise = vec3(0.51, 0.20, 0.05) * TimeSunrise;
    vec3 sunlight_noon = vec3(1.5, 1.45, 1.4) * TimeNoon;
    vec3 sunlight_sunset = vec3(0.51, 0.20, 0.05) * TimeSunset2;
    vec3 sunlight_midnight = vec3(0.03, 0.19, 0.99) * 0.03 * (TimeMidnight2);
	vec3 sunlight_color = sunlight_sunrise + sunlight_noon + sunlight_sunset + (sunlight_midnight);

	vec3 shadowcolor_day = vec3(0.0, 2.55, 2.55) * (TimeSunrise+TimeNoon+TimeSunset);
	vec3 shadowcolor_night = vec3(0.55, 1.55, 2.55) * TimeMidnight;
	vec3 shadowcolor_rain = vec3(0.25, 1.59, 2.55)*3.0;
	vec3 shadowcolor = shadowcolor_day + shadowcolor_night + shadowcolor_rain;
	
	vec3 sunlight_water_day = vec3(1.0, 1.0, 1.0)*0.1*iswater * (TimeSunrise+TimeNoon+TimeSunset);
	vec3 sunlight_water_night = vec3(1.0, 1.0, 1.0)*0.0*iswater * TimeMidnight;
	vec3 water_sunlight_color = sunlight_water_day + sunlight_water_night;
		
	
	float sss_transparency = mix(0.0,1.0,translucent);		//subsurface scattering amount
	float sunlight_direct = 1.0;
	float direct = 1.0;
	float sss = 0.0;
	vec3 npos = normalize(fragposition.xyz);
	float NdotL = 1.0;
	NdotL = dot(normal, lightVector);
	direct = NdotL;
		
	sunlight_direct = max(direct,0.0);
	sunlight_direct = mix(sunlight_direct,0.75,translucent*min(sss_fade+0.4,1.0));
	
	sss += pow(max(dot(npos, lightVector),0.0),20.0)*sss_transparency*clamp(-NdotL,0.0,1.0)*translucent*4.0*(1.0 - rainStrength*1.0);
	sss = mix(0.0,sss,sss_fade);
	
	shading = clamp(shading,0.0,1.0);
	
		
		
// Apply different lightmaps to image
	
	#define shadow_brightmult 1000.0
	#define sunlight_amount 0.2

	vec3 Sunlight_lightmap = sunlight_color*mix(max(lightmap-rainStrength*0.95,0.0),shading,shadow_fade)*sunlight_amount*sky_lightmap*(1.0-rainStrength*1.0) *sunlight_direct*transition_fading ;
	vec3 water_sunlight_lightmap = water_sunlight_color*mix(max(lightmap-rainStrength*0.95,0.0),shading,shadow_fade)*sunlight_amount*sky_lightmap*(1.0-rainStrength*1.0) *sunlight_direct*transition_fading ;
		
	// Desaturate ambient color at night
    vec3 nolight_day;
        nolight_day = color * 1.0;
		
    vec3 nolight_night;
	    nolight_night.r = (color.r)*((-0.3) + 1.0f) + (color.g + color.b)*(-(-0.3))*TimeMidnight3;
	    nolight_night.g = (color.g)*((-0.3) + 1.0f) + (color.r + color.b)*(-(-0.3))*TimeMidnight3;
	    nolight_night.b = (color.b)*((-0.3) + 1.0f) + (color.r + color.g)*(-(-0.3))*TimeMidnight3;
	
	vec3 nolight = nolight_day + nolight_night;
	
	
	float min_light = 0.00005;
	
	
	float sky_inc = sqrt(direct*0.5+0.51);
	vec3 amb = (sky_inc*ambient_color+(1.0-sky_inc)*(sunlight_color+ambient_color*2.0)*vec3(0.2,0.24,0.27))*vec3(0.8,0.8,1.0);
	
	float torchlightBrightnessDay     = 1.0*TimeDay*torch_skylightmap;
	float torchlightRangeDay          = 30.0*TimeDay*torch_skylightmap;
	
	float torchlightBrightnessNight   = 1.0*TimeMidnight*torch_skylightmap;
	float torchlightRangeNight        = 15.0*TimeMidnight*torch_skylightmap;
	
	float torchlightBrightness_shadow = 0.05/torch_skylightmap;
	float torchlightRange_shadow      = 0.5/torch_skylightmap;
	
	float torchlightHandlightDay      = 20.0*TimeDay*torch_skylightmap;
	float torchlightHandlightNight    = 1.0*TimeMidnight*torch_skylightmap;
	float torchlightHandlight_shadow  = 0.05/torch_skylightmap;

	
	
	
	float torchlight_brightness = torchlightBrightnessDay + torchlightBrightness_shadow + torchlightBrightnessNight;
	float torchlight_range = torchlightRangeDay + torchlightRange_shadow + torchlightRangeNight;
	float torchlight_handlight = torchlightHandlightDay + torchlightHandlight_shadow + torchlightHandlightNight;
	
    float torch_lightmap = pow(aux.b,torchlight_range)*torchlight_brightness;
	
	vec3 torchcolor = vec3(2.55,0.38,0.11);
	
	vec3 Torchlight_lightmap = (torch_lightmap+handlight*pow(max(5.0-length(fragposition.xyz),0.0)/5.0,5.0)*max(dot(-fragposition.xyz,normal),0.0)/torchlight_handlight) *  torchcolor ;
		
	vec3 color_sunlight = Sunlight_lightmap;
	vec3 color_water_sunlight = water_sunlight_lightmap;
	vec3 color_torchlight = Torchlight_lightmap;
	
		
		
// Apply all light elements 

	if (iswater > 0.9) {
		color = (amb/shadow_brightmult*shadowcolor*lightmap*ao + color_water_sunlight + sss * water_sunlight_color * shading * transition_fading)*nolight + shadowcolor*min_light*color + (color_torchlight*0.2*ao)*color;
		//color = (amb/shadow_brightmult*shadowcolor*lightmap*ao + sss * water_sunlight_color * shading * transition_fading)*nolight + shadowcolor*min_light*color + (color_torchlight*0.2*ao)*color;
	} else {
		color = (amb/shadow_brightmult*shadowcolor*lightmap*ao + color_sunlight + sss * sunlight_color * shading * transition_fading)*nolight + shadowcolor*min_light*color + (color_torchlight*ao)*color;
    }
	} else if (isEyeInWater < 0.1){
	
	    vec3 skycolor_day = vec3(0.3, 0.9, 1.0) * (1.0-rainStrength*1.0) * TimeDay;
		vec3 skycolor_night = vec3(0.13, 1.0, 1.5) * (1.0-rainStrength*1.0) * TimeMidnight;
		vec3 skycolor_rain = vec3(0.1, 0.1, 0.1)*(TimeDay);
		color *= skycolor_day + skycolor_night + skycolor_rain;
		
	    float HDR = pow(eyeBrightnessSmooth.y / 255.0, 6.0f) * 1.0 + 0.25;
		color = color * 0.3 / HDR;
	}

/* DRAWBUFFERS:31 */



// cel shading
	//if (land > 0.9 && iswater < 0.9) color = celshade(color);



// godrays
	
	const float gr_density = 0.55;			
	const int gr_ssao_samples = 5;
	const float gr_noise = 0.0;
	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;
	
	float gr = 0.0;
	
	float truepos = pow(clamp(dot(-lightVector,tpos.xyz)/length(tpos.xyz),0.0,1.0),0.5);		//temporary fix that check if the sun/moon position is correct
	
	if (truepos > 0.05) {	
		vec2 deltaTextCoord = vec2( texcoord.st - lightPos.xy );
		vec2 textCoord = texcoord.st;
		deltaTextCoord *= 1.0 /  float(gr_ssao_samples) * gr_density;
	
			float avgdecay = 0.0;
			float distx = abs(texcoord.x*aspectRatio-lightPos.x*aspectRatio);
			float disty = abs(texcoord.y-lightPos.y);
			vec2 noise = vec2(getnoise(textCoord),getnoise(-textCoord.yx+0.05));
			
			for(int i=0; i < gr_ssao_samples ; i++) {			
				textCoord -= deltaTextCoord;
				float sample = step(texture2D(gaux1, textCoord+ textCoord*noise*gr_noise).g,0.01);
				gr += sample;
		}
	}
	
    color.r = color.r * 1.81*2;
	color.g = color.g * 1.65*2;
	color.b = color.b * 1.44*2;
	
	color = pow(color,vec3(1.0/2.2));
	color = clamp(color,0.0,1.0);
	gl_FragData[0] = vec4(color, 0.0);
	gl_FragData[1] = vec4(vec3((gr/gr_ssao_samples)),1.0);
	
}
