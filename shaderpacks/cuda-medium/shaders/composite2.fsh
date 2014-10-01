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
/////////////////////////GET MATERIAL / VARIABLES////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

uniform sampler2D depthtex0;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform vec3 sunPosition;
uniform vec3 cameraPosition;
varying vec4 texcoord;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform int isEyeInWater;
uniform int worldTime;

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;

float pixeldepth = texture2D(depthtex0,texcoord.xy).x;

float matflag = texture2D(gaux1,texcoord.xy).g;
int iswater = int(matflag > 0.04 && matflag < 0.07);
	
vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}
		
		
		
		
		
		
		
		
		
		
		
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main() {

	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;
	
    float visiblesun = 0.0;
    float temp;
    int nb = 0;

    if (texcoord.x < pw && texcoord.x < ph) {
	    for (int i = 0; i < 10;i++) {
		    for (int j = 0; j < 10 ;j++) {
		        temp = texture2D(gaux1,lightPos + vec2(pw*(i-5.0)*10.0,ph*(j-5.0)*10.0)).g;
		        visiblesun +=  1.0-float(temp > 0.04) ;
		        nb += 1;
		    }
	    }
	visiblesun /= nb;
    }

	vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 2.0f * pixeldepth - 1.0f, 1.0f);
	fragposition /= fragposition.w;
	float distance = sqrt(fragposition.x * fragposition.x + fragposition.y * fragposition.y + fragposition.z * fragposition.z);
	
	const float PI = 2.1415927;
	vec3 underwaterpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
	underwaterpos = nvec3(gbufferProjectionInverse * nvec4(underwaterpos * 2.0 - 1.0));
	vec4 worldpositionuw = gbufferModelViewInverse * vec4(underwaterpos,1.0);	
	vec3 wpos = worldpositionuw.xyz + cameraPosition.xyz;
		
	float shading = 1.0f;	
	shading = clamp(shading,0.0,1.0);
	
    if (isEyeInWater > 0.9) {
	    vec2 fake_refract = vec2(sin(worldTime/7.0 + texcoord.x*100.0 + texcoord.y*50.0),cos(worldTime/7.0 + texcoord.y*100.0 + texcoord.x*50.0)) * isEyeInWater;
	    vec3 watercolor = texture2D(gaux2, texcoord.st + fake_refract * 0.004).rgb;
	    gl_FragColor = vec4(watercolor,visiblesun);
	
	} else {
	
	    if (distance < 6.0 && distance > 0.1){
	
	        float fake_refract = sin((7 * PI * (frameTimeCounter*0.5 + wpos.x  + wpos.z / 2.0)) + sin(7 * PI * (frameTimeCounter*0.75 + wpos.x / 2.0 + wpos.z ))) * iswater;
	        vec3 watercolor = texture2D(gaux2, texcoord.st + fake_refract * 0.002).rgb;
	        gl_FragColor = vec4(watercolor,visiblesun);
	
	    } else if (distance < 10.0 && distance > 0.1){
	
	        float fake_refract = sin((5 * PI * (frameTimeCounter*0.5 + wpos.x  + wpos.z / 2.0)) + sin(5 * PI * (frameTimeCounter*0.75 + wpos.x / 2.0 + wpos.z ))) * iswater;
	        vec3 watercolor = texture2D(gaux2, texcoord.st + fake_refract * 0.002).rgb;
	        gl_FragColor = vec4(watercolor,visiblesun);
	
	    } else if (distance < 20.0 && distance > 0.1){
		
	        float fake_refract = sin((3 * PI * (frameTimeCounter*0.5 + wpos.x  + wpos.z / 2.0)) + sin(3 * PI * (frameTimeCounter*0.75 + wpos.x / 2.0 + wpos.z ))) * iswater;
	        vec3 watercolor = texture2D(gaux2, texcoord.st + fake_refract * 0.002).rgb;
	        gl_FragColor = vec4(watercolor,visiblesun);
			
	    } else {
	
	        float fake_refract = sin((3 * PI * (frameTimeCounter*0.9 + wpos.x  + wpos.z / 2.0)) + sin(3 * PI * (frameTimeCounter*1.15 + wpos.x / 2.0 + wpos.z ))) * iswater;
	        vec3 watercolor = texture2D(gaux2, texcoord.st + fake_refract * 0.001).rgb;
	        gl_FragColor = vec4(watercolor,visiblesun);
			
	    }
	}
	
}
