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
/////////////////////////ADJUSTABLE FUNCTIONS////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    #define WAVING_LEAVES
    #define WAVING_ACIALEAVES
    #define WAVING_SAPLINGS
    #define WAVING_LARGETALLGRASS
    #define WAVING_VINES
    #define WAVING_GRASS
    #define WAVING_WHEAT
    #define WAVING_CARROTS
    #define WAVING_POTATOES
    #define WAVING_FLOWERS
    #define WAVING_FIRE
    #define WAVING_LAVA
    #define WAVING_LILYPAD











/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////GET MATERIAL / VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

varying vec4 color;
varying vec3 normal;
varying vec2 texcoord;
varying vec2 lmcoord;
varying float translucent;

attribute vec4 mc_Entity;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float frameTimeCounter;
uniform float rainStrength;

const float PI = 3.1415927;

float pi2wt = PI*2*(frameTimeCounter*24);

vec3 calcWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5) {
    vec3 ret;
    float magnitude,d0,d1,d2,d3;
    magnitude = sin(pi2wt*fm + pos.x*0.5 + pos.z*0.5 + pos.y*0.5) * mm + ma;
    d0 = sin(pi2wt*f0);
    d1 = sin(pi2wt*f1);
    d2 = sin(pi2wt*f2);
    ret.x = sin(pi2wt*f3 + d0 + d1 - pos.x + pos.z + pos.y) * magnitude;
    ret.z = sin(pi2wt*f4 + d1 + d2 + pos.x - pos.z + pos.y) * magnitude;
	ret.y = sin(pi2wt*f5 + d2 + d0 + pos.z + pos.y - pos.y) * magnitude;
    return ret;
}

vec3 calcMove(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5, in vec3 amp1, in vec3 amp2) {
    vec3 move1 = calcWave(pos      , 0.0027, 0.0400, 0.0400, 0.0127, 0.0089, 0.0114, 0.0063, 0.0224, 0.0015) * amp1;
	vec3 move2 = calcWave(pos+move1, 0.0348, 0.0400, 0.0400, f0, f1, f2, f3, f4, f5) * amp2;
    return move1+move2;
}

vec3 calcWaterMove(in vec3 pos) {
	float fy = fract(pos.y + 0.001);
	
	if (fy > 0.002) {
		float wave = 0.05 * sin(2 * PI * (worldTime / 86.0 + pos.x /  7.0 + pos.z / 13.0))
					+ 0.05 * sin(2 * PI * (worldTime / 60.0 + pos.x / 11.0 + pos.z /  5.0));
		return vec3(0, clamp(wave, -fy, 1.0-fy), 0);
	} else {
		return vec3(0);
	}
}











/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main() {
	
	texcoord = (gl_MultiTexCoord0).xy;
	
	translucent = 0.0f;

	bool istopv = gl_MultiTexCoord0.t < gl_MultiTexCoord3.t;

	/* un-rotate */
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec3 worldpos = position.xyz + cameraPosition;
	
	//initialize per-entity waving parameters
	float parm0,parm1,parm2,parm3,parm4,parm5 = 0.0;
	vec3 ampl1,ampl2;
	ampl1 = vec3(0.0);
	ampl2 = vec3(0.0);
	
	
	
#ifdef WAVING_LEAVES

	if ( mc_Entity.x == 18.0 ) {
	    color.rgb += vec3(2.55, 1.0, 0.5);
		parm0 = 0.0040;
		parm1 = 0.0064;
		parm2 = 0.0043;
		parm3 = 0.0035;
		parm4 = 0.0037;
		parm5 = 0.0041;
		ampl1 = vec3(0.5,0.2,0.5);
		ampl2 = vec3(0.25,0.1,0.25);
	}
	
#endif



#ifdef WAVING_ACIALEAVES

	if ( mc_Entity.x == 161.0 ) {
		parm0 = 0.0040;
		parm1 = 0.0064;
		parm2 = 0.0043;
		parm3 = 0.0035;
		parm4 = 0.0037;
		parm5 = 0.0041;
		ampl1 = vec3(0.5,0.2,0.5);
		ampl2 = vec3(0.25,0.1,0.25);
	}
	
#endif



#ifdef WAVING_SAPLINGS

	if (mc_Entity.x == 6.0 && istopv ) {
		parm0 = 0.0041;
		parm1 = 0.005;
		parm2 = 0.0044;
		parm3 = 0.0038;
		parm4 = 0.0240;
		parm5 = 0.0;
		ampl1 = vec3(1.0,0.0,1.0);
		ampl2 = vec3(0.6,0.0,0.6);
	}
			
#endif
	
	
	
#ifdef WAVING_VINES

	if ( mc_Entity.x == 106.0 ) {
		parm0 = 0.0040;
		parm1 = 0.0064;
		parm2 = 0.0043;
		parm3 = 0.0035;
		parm4 = 0.0037;
		parm5 = 0.0041;
		ampl1 = vec3(0.5,0.2,0.5);
		ampl2 = vec3(0.2,0.1,0.2);
	}
			
#endif
	
	
	
#ifdef WAVING_GRASS

	if ( mc_Entity.x == 31.0 && istopv ) {
		parm0 = 0.0041;
		parm1 = 0.0070;
		parm2 = 0.0044;
		parm3 = 0.0038;
		parm4 = 0.0063;
		parm5 = 0.038;
		ampl1 = vec3(2.8,0.0,2.8);
		ampl2 = vec3(1.0,1.0,1.0);
	}
			
#endif



#ifdef WAVING_LARGETALLGRASS

	if ( mc_Entity.x == 175.0 ) {
		parm0 = 0.0040;
		parm1 = 0.0064;
		parm2 = 0.0043;
		parm3 = 0.0035;
		parm4 = 0.0037;
		parm5 = 0.0041;
		ampl1 = vec3(0.4,0.2,0.4);
		ampl2 = vec3(0.25,0.1,0.25);
	}
			
#endif
	
	
	
#ifdef WAVING_FLOWERS

	if ((mc_Entity.x == 37.0 || mc_Entity.x == 38.0) && istopv ) {
		parm0 = 0.0041;
		parm1 = 0.005;
		parm2 = 0.0044;
		parm3 = 0.0038;
		parm4 = 0.0240;
		parm5 = 0.0;
		ampl1 = vec3(1.0,0.0,1.0);
		ampl2 = vec3(0.6,0.0,0.6);
	}
	
#endif
	
	
	
#ifdef WAVING_WHEAT

	if ( mc_Entity.x == 59.0 && istopv ) {
		parm0 = 0.0041;
		parm1 = 0.0070;
		parm2 = 0.0044;
		parm3 = 0.0240;
		parm4 = 0.0063;
		parm5 = 0.0;
		ampl1 = vec3(1.0,0.0,1.0);
		ampl2 = vec3(0.5,0.5,0.5);
	}
			
#endif



#ifdef WAVING_CARROTS

	if ( mc_Entity.x == 141.0 && istopv ) {
		parm0 = 0.0041;
		parm1 = 0.0070;
		parm2 = 0.0044;
		parm3 = 0.0240;
		parm4 = 0.0063;
		parm5 = 0.0;
		ampl1 = vec3(1.0,0.0,1.0);
		ampl2 = vec3(0.5,0.5,0.5);
	}
	
#endif



#ifdef WAVING_POTATOES

	if ( mc_Entity.x == 142.0 && istopv ) {
		parm0 = 0.0041;
		parm1 = 0.0070;
		parm2 = 0.0044;
		parm3 = 0.0240;
		parm4 = 0.0063;
		parm5 = 0.0;
		ampl1 = vec3(1.0,0.0,1.0);
		ampl2 = vec3(0.5,0.5,0.5);
	}
			
#endif
	
	
	
#ifdef WAVING_FIRE

	if ( mc_Entity.x == 51.0 && istopv ) {
		parm0 = 0.0205;
		parm1 = 0.0296;
		parm2 = 0.0287;
		parm3 = 0.0263;
		parm4 = 0.0297;
		parm5 = 0.0256;
		ampl1 = vec3(2.0,2.0,2.0);
		ampl2 = vec3(2.0,2.0,2.0);
	}	
			
#endif



	float movemult = 0.0;
	
#ifdef WAVING_LAVA

	if ( mc_Entity.x == 10.0 || mc_Entity.x == 11.0 ) movemult = 0.5;

#endif
	
	
	
#ifdef WAVING_LILYPAD

	if ( mc_Entity.x == 111.0 ){
		parm0 = 0.0041;
		parm1 = 0.0070;
		parm2 = 0.0044;
		parm3 = 0.0240;
		parm4 = 0.0063;
		parm5 = 0.0;
		ampl1 = vec3(1.0,0.0,1.0);
		ampl2 = vec3(0.5,0.5,0.5);
	}
	
#endif

	position.xyz += calcWaterMove(worldpos.xyz) * movemult;
	position.xyz += calcMove(worldpos.xyz, parm0, parm1, parm2, parm3, parm4, parm5, ampl1, ampl2);
	
	if (mc_Entity.x == 18.0 || 
	mc_Entity.x == 106.0 || 
	mc_Entity.x == 31.0 || 
	mc_Entity.x == 37.0 || 
	mc_Entity.x == 38.0 || 
	mc_Entity.x == 59.0 ||
	mc_Entity.x == 75.0 || 	
	mc_Entity.x == 30.0 || 
	mc_Entity.x == 115.0 || 
	mc_Entity.x == 32.0 || 
	mc_Entity.x == 161.0 || 
	mc_Entity.x == 6.0 || 
	mc_Entity.x == 141.0 || 
	mc_Entity.x == 142.0 || 
	mc_Entity.x == 175.0 || 
	mc_Entity.x == 83.0 || 
	mc_Entity.x == 115.0 || 
	mc_Entity.x == 104.0 || 
	mc_Entity.x == 105.0 || 
	mc_Entity.x == 39.0 || 
	mc_Entity.x == 40.0) translucent = 1.0;

	/* re-rotate */
	
	/* projectify */
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	
	color = gl_Color;
	
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	
	normal = normalize(gl_NormalMatrix * gl_Normal);
	
}