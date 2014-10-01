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

/* DRAWBUFFERS:024 */

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 normal;
varying vec4 color;
varying float translucent;

uniform sampler2D texture;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int fogMode;
uniform int worldTime;











/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main() {	
	
	vec2 adjustedTexCoord = texcoord.st;
	vec3 lightVector;
	vec3 indlmap = texture2D(texture,adjustedTexCoord).rgb*color.rgb;
	vec4 frag2 = vec4(vec3(normal) * 0.5 + 0.5, 1.0f);
	
	float dirtest = 0.4;
	float pomsample = 0.0;
	float texinterval = 0.0625;
	
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	} else {
		lightVector = normalize(moonPosition);
	}
	
	dirtest = mix(1.0-0.8*step(dot(frag2.xyz*2.0-1.0,lightVector),-0.02),0.4,float(translucent > 0.01));

	

	gl_FragData[0] = vec4(indlmap,texture2D(texture,adjustedTexCoord).a*color.a);
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4(lmcoord.t, dirtest, lmcoord.s, 1.0);
	
}