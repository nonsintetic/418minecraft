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
                                - If you like to share my shaderpack, please share only the minecraftforum.net link!
                                - You are not allowed to publish the modification!
                                - You are not allowed to reupload it!
                                - You are not allowed to earn money with it!

                                For YouTube:
                                - You are allowed to earn money with my shaderpack in your YouTube Video.
                                - If you modified something in my shaderpack, please say that it in your YouTube Video or description.

*/











/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////GET MATERIAL////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

varying vec4 texcoord;
varying vec3 sunlight;

uniform sampler2D depthtex2;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform ivec2 eyeBrightness;
uniform int isEyeInWater;
uniform int worldTime;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform float centerDepthSmooth;
vec3 sunPos = sunPosition;
uniform int fogMode;

float ifRain = clamp(wetness, 0.0f, 1.0f)/1.0f;

float timefract = worldTime;
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);
float TimeDay = TimeSunrise+ TimeNoon + TimeSunset;

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;

float getDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}
		


float distratio(vec2 pos, vec2 pos2, float ratio) {
float xvect = pos.x*ratio-pos2.x*ratio;
float yvect = pos.y-pos2.y;
return sqrt(xvect*xvect + yvect*yvect);
}

//circle position pattern (vec2 coordinate, size)
const vec3 pattern[16] = vec3[16](	vec3(0.1,0.1,0.02),
								vec3(-0.12,0.07,0.02),
								vec3(-0.11,-0.13,0.02),
								vec3(0.1,-0.1,0.02),
								
								vec3(0.07,0.15,0.02),
								vec3(-0.08,0.17,0.02),
								vec3(-0.14,-0.07,0.02),
								vec3(0.15,-0.19,0.02),
								
								vec3(0.012,0.15,0.02),
								vec3(-0.08,0.17,0.02),
								vec3(-0.14,-0.07,0.02),
								vec3(0.02,-0.17,0.021),
								
								vec3(0.10,0.05,0.02),
								vec3(-0.13,0.09,0.02),
								vec3(-0.05,-0.1,0.02),
								vec3(0.1,0.01,0.02)
								);
								
float gen_circular_lens(vec2 center, float size) {
return 1.0-pow(min(distratio(texcoord.xy,center,aspectRatio),size)/size,10.0);
}

vec2 noisepattern(vec2 pos) {
return vec2(abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f)),abs(fract(sin(dot(pos.yx ,vec2(18.9898f,28.633f))) * 4378.5453f)));
} 



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main() {

	vec3 color = texture2D(gaux2, texcoord.st).rgb;
	
	
	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lightPos = tpos.xy/tpos.z;
		lightPos = (lightPos + 1.0f)/2.0f;
		
	// For lens flare
	vec4 tpos2 = vec4(sunPosition,1.0)*gbufferProjection;
		tpos2 = vec4(tpos2.xyz/tpos2.w,1.0);
	vec2 lightPos2 = tpos2.xy/-tpos2.z;
		lightPos2 = (lightPos2 + 1.0f)/2.0f;
		
	vec4 tpos3 = vec4(sunPosition,1.0)*gbufferProjection;
		tpos3 = vec4(tpos3.xyz/tpos3.w,1.0);
	vec2 lightPos3 = tpos3.xy/-tpos3.z*0.6;
		lightPos3 = (lightPos3 + 1.0f)/2.0f;
		
	vec4 tpos4 = vec4(sunPosition,1.0)*gbufferProjection;
		tpos4 = vec4(tpos4.xyz/tpos4.w,1.0);
	vec2 lightPos4 = tpos4.xy/-tpos4.z/10;
		lightPos4 = (lightPos4 + 1.0f)/2.0f;
		
	vec4 tpos5 = vec4(sunPosition,1.0)*gbufferProjection;
		tpos5 = vec4(tpos5.xyz/tpos5.w,1.0);
	vec2 lightPos5 = tpos5.xy/-tpos5.z*0.3;
		lightPos5 = (lightPos5 + 1.0f)/2.0f;
		
	vec4 tpos6 = vec4(sunPosition,1.0)*gbufferProjection;
		tpos6 = vec4(tpos6.xyz/tpos6.w,1.0);
	vec2 lightPos6 = tpos6.xy/-tpos6.z*0.5;
		lightPos6 = (lightPos6 + 1.0f)/2.0f;
		
// lens

    float xdist = abs(lightPos.x-texcoord.x);
    float ydist = abs(lightPos.y-texcoord.y);
    float xydist = distance(lightPos.xy,texcoord.xy);
    float xydistratio = distratio(lightPos.xy,texcoord.xy,aspectRatio);
    float xydistratio2 = distratio(lightPos2.xy,texcoord.xy,aspectRatio);
    float xydistratio3 = distratio(lightPos3.xy,texcoord.xy,aspectRatio);
    float xydistratio4 = distratio(lightPos4.xy,texcoord.xy,aspectRatio);
    float xydistratio5 = distratio(lightPos5.xy,texcoord.xy,aspectRatio);
    float xydistratio6 = distratio(lightPos6.xy,texcoord.xy,aspectRatio);

    float distof = min(min(1.0-lightPos.x,lightPos.x),min(1.0-lightPos.y,lightPos.y));
    float fading = clamp(1.0-step(distof,0.1)+pow(distof*10.0,5.0),0.0,1.0);

    float time = float(worldTime);
    float transition_fading = 1.0-(clamp((time-12000.0)/500.0,0.0,1.0)-clamp((time-13000.0)/500.0,0.0,1.0) + clamp((time-22800.0)/400.0,0.0,1.0)-clamp((time-23400.0)/600.0,0.0,1.0));

    float sunvisibility = min(texture2D(gaux2,vec2(0.0)).a*2.5,1.0) * fading * transition_fading;


    //float anamorphic_lens = clamp( 0.75-(pow(ydist,0.1)) - pow(xdist*2.0,2.0),0.0,1.0)*5.0;


    float centerdist = distance(lightPos.xy,vec2(0.5))/1.412;
    float sizemult = 1.0 + centerdist;
    float noise = fract(sin(dot(texcoord.st ,vec2(18.9898f,28.633f))) * 4378.5453f)*0.1 + 0.9;
							
    float circles_lens = 0.0;

if ((worldTime < 23000 || worldTime > 13000) && -sunPos.z < 0){
    if (sunvisibility > 0.01) {
        if (xydist < 0.35) {
            vec2 sun_to_center = lightPos-vec2(0.5);
            float dir = abs(sin(length(sun_to_center)))*0.25+0.75;

            for (int i = 0; i < 8; i++) {
                vec3 carac = pattern[i]*1.25;
                carac.z *= 1.0/1.25;
                carac.x /= aspectRatio;
                carac *= (1.0 + dir)/2.0;
                vec2 coord = carac.xy * sizemult+ lightPos.xy;
                float strength = sin(length(coord-vec2(0.5))*40.0)*0.5+0.5;
                circles_lens += gen_circular_lens(coord,carac.z*0.95)*strength*1.0;

                carac = pattern[i];
                carac.x /= aspectRatio;
                carac.yx *= (2.0 - dir)/2.5;

                coord = -carac.yx * sizemult + lightPos.xy;
                strength = sin(length(coord-vec2(0.5))*40.0)*0.5+0.5;
                circles_lens += gen_circular_lens(coord,carac.z*1.66)*strength*3.0;
            }
            if (isEyeInWater < 0.9){
                color += vec3(0.13, 0.59, 0.99)*0.2*TimeMidnight*1.5*vec3(circles_lens) * sunvisibility * noise * 0.25 * (1.0-ifRain*1.0);
            }
        }
    }
}

if ((worldTime < 13000 || worldTime > 23000) && sunPos.z < 0){
    if (sunvisibility > 0.01) {
        if (xydist < 0.35) {
            vec2 sun_to_center = lightPos-vec2(0.5);
            float dir = abs(sin(length(sun_to_center)))*0.25+0.75;

            for (int i = 0; i < 8; i++) {
                vec3 carac = pattern[i]*1.25;
                carac.z *= 1.0/1.25;
                carac.x /= aspectRatio;
                carac *= (1.0 + dir)/2.0;
                vec2 coord = carac.xy * sizemult+ lightPos.xy;
                float strength = sin(length(coord-vec2(0.5))*40.0)*0.5+0.5;
                circles_lens += gen_circular_lens(coord,carac.z*0.95)*strength*1.0;

                carac = pattern[i];
                carac.x /= aspectRatio;
                carac.yx *= (2.0 - dir)/2.5;

                coord = -carac.yx * sizemult + lightPos.xy;
                strength = sin(length(coord-vec2(0.5))*40.0)*0.5+0.5;
                circles_lens += gen_circular_lens(coord,carac.z*1.66)*strength*3.0;
            }
            if (isEyeInWater < 0.9){
                color += vec3(1.0, 0.629, 0.416)/2*(TimeSunrise+TimeNoon+TimeSunset)*vec3(circles_lens) * sunvisibility * noise * 0.25 * (1.0-ifRain*1.0);
            }
        }
    }
}

if ((worldTime < 13000 || worldTime > 23000) && sunPos.z < 0 && isEyeInWater < 0.9){

    // Little blue point
    if (xydistratio2 < 0.3 && sunvisibility > 0.1) {

	    vec3 lenscolor = vec3(0.0, 0.7, 1.5)*(TimeSunrise+TimeNoon+TimeSunset);
		
		float lens_strength = 0.7;
		lenscolor *= lens_strength;
	
        float lens_flare1 = max(pow(max(1.0 - xydistratio2/1.412,0.01),8.0)-0.2,0.0);
        color += lenscolor*lens_flare1*0.5*sunvisibility * (1.0-ifRain*1.0);
	
        float lens_flare2 = max(pow(max(1.0 - xydistratio2/1.512,0.1),8.0)-0.92,0.0);
        color += lenscolor*lens_flare2*3.0*sunvisibility * (1.0-ifRain*1.0);
    }

	// Big blue point
    if (xydistratio3 < 0.3 && sunvisibility > 0.1) {

	    vec3 lenscolor = vec3(0.0, 0.7, 1.5)*(TimeSunrise+TimeNoon+TimeSunset);
		
		float lens_strength = 0.7;
		lenscolor *= lens_strength;
	 
        float lens_flare3 = max(pow(max(1.0 - xydistratio3/1.512,0.1),8.0)-0.4,0.0);
        color += lenscolor*lens_flare3*0.3*sunvisibility * (1.0-ifRain*1.0);
	
        float lens_flare4 = max(pow(max(1.0 - xydistratio3/1.512,0.1),8.0)-0.7,0.0);
        color += lenscolor*lens_flare4*0.7*sunvisibility * (1.0-ifRain*1.0);
    }
	
	// Big green point
    if (xydistratio4 < 0.5 && sunvisibility > 0.1) {
	
		vec3 lenscolor = vec3(0.5, 1.0, 0.5)*(TimeSunrise+TimeNoon+TimeSunset);
		
		float lens_strength = 0.7;
		lenscolor *= lens_strength;

        float lens_flare5 = max(pow(max(1.0 - xydistratio4/1.712,0.1),8.0)-0.4,0.0);
        color += lenscolor*lens_flare5*0.5*sunvisibility * (1.0-ifRain*1.0);
		
        float lens_flare6 = max(pow(max(1.0 - xydistratio4/1.512,0.1),8.0)-0.9,0.0);
        color += lenscolor*lens_flare6*4.0*sunvisibility * (1.0-ifRain*1.0);

    }
	
	// Big red point
    if (xydistratio5 < 0.5 && sunvisibility > 0.1) {
	
		vec3 lenscolor = vec3(1.5, 0.8, 0.0)*(TimeSunrise+TimeNoon+TimeSunset);
		
		float lens_strength = 0.7;
		lenscolor *= lens_strength;
		
	    float lens_flare7 = max(pow(max(1.0 - xydistratio5/1.712,0.1),8.0)-0.6,0.0);
        color += lenscolor*lens_flare7*0.5*sunvisibility * (1.0-ifRain*1.0);
		
	    float lens_flare8 = max(pow(max(1.0 - xydistratio5/1.712,0.1),8.0)-0.3,0.0);
        color += lenscolor*lens_flare8*0.4*sunvisibility * (1.0-ifRain*1.0);

    }
	
	// Little red point
    if (xydistratio6 < 0.5 && sunvisibility > 0.1) {
	
		vec3 lenscolor = vec3(1.5, 0.8, 0.0)*(TimeSunrise+TimeNoon+TimeSunset);
		
		float lens_strength = 0.7;
		lenscolor *= lens_strength;
		
	    float lens_flare9 = max(pow(max(1.0 - xydistratio6/1.712,0.1),8.0)-0.93,0.0);
        color += lenscolor*lens_flare9*3.0*sunvisibility * (1.0-ifRain*1.0);

    }
}

//rain drops on screen
if (rainStrength > 0.01) {
    const float pi = 3.14159265359;
	float fake_refract = vec3(1.0-sin(worldTime/5.14159265359 + texcoord.x*30.0 + texcoord.y*30.0)) * pow(eyeBrightness.y/255.0, 6.0f);
	float fake_refract2 = vec3(sin(worldTime/7.14159265359 + texcoord.x*20.0 + texcoord.y*20.0)) * pow(eyeBrightness.y/255.0, 6.0f);
    vec3 watercolor = texture2D(gaux1, texcoord.st + fake_refract * 0.015).rgb;
    float raindrops = 0.0;
    float time2 = frameTimeCounter;

    float gen = cos(time2*pi)*0.5+0.5;
    vec2 pos = noisepattern(vec2(0.9347*floor(time2*0.5+0.5),-0.2533282*floor(time2*0.5+0.5)));
    raindrops += gen_circular_lens(pos,0.033)*gen*rainStrength;

    gen = cos(time2*pi)*0.5+0.5;
    pos = noisepattern(vec2(0.785282*floor(time2*0.5+0.5),-0.285282*floor(time2*0.5+0.5)));
    raindrops += gen_circular_lens(pos,0.033)*gen*rainStrength;

    gen = sin(time2*pi)*0.5+0.5;
    pos = noisepattern(vec2(-0.347*floor(time2*0.5+0.5),0.6847*floor(time2*0.5+0.5)));
    raindrops += gen_circular_lens(pos,0.033)*gen*rainStrength;

    gen = cos(time2*pi)*0.5+0.5;
    pos = noisepattern(vec2(0.3347*floor(time2*0.5+0.5),-0.2533282*floor(time2*0.5+0.5)));
    raindrops += gen_circular_lens(pos,0.033)*gen*rainStrength;

    gen = cos(time2*pi)*0.5+0.5;
    pos = noisepattern(vec2(0.385282*floor(time2*0.5+0.5),-0.285282*floor(time2*0.5+0.5)));
    raindrops += gen_circular_lens(pos,0.033)*gen*rainStrength;
     
	if (isEyeInWater < 0.9) {
        color = mix(color,watercolor,raindrops) + abs(fake_refract2)/25*raindrops;
	}
}


	
	

// vignette

    float dist = distance(texcoord.st, vec2(0.5, 0.5));
    dist = 0.8 - dist;
	
    color.r = color.r * dist;
    color.g = color.g * dist;
    color.b = color.b * dist;
	
	
	

	
// color filter
	
	color.r = pow(color.r, 0.8);
	color.g = pow(color.g, 0.8);
	color.b = pow(color.b, 0.8);
	
	color -= 0.01;
	
	color = color * 1.1;
	
    color.r = color.r * 1.81;
	color.g = color.g * 1.65;
	color.b = color.b * 1.44;


	
	
	

color = clamp(color,0.0,1.0);
float white = luma(color);
color = color*(1.0+pow(white,0.3))/(2.0-0.3);



// tonemap

    color = color / (color + 1.0) * (1.0+1.0);




	
    color = pow(color,vec3(2.2));
    color = pow(color,vec3(1.0/2.2));
	gl_FragColor = vec4(color,1.0);
	
}
