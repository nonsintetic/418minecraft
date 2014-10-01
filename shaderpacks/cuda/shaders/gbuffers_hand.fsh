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

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;

uniform sampler2D texture;
uniform sampler2D normals;
uniform int fogMode;











/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main() {	
	
	vec2 adjustedTexCoord = texcoord.st;
	
	float texinterval = 0.0625f;
	
	vec3 indlmap = texture2D(texture,adjustedTexCoord).rgb*color.rgb;
	
	gl_FragData[0] = vec4(indlmap,texture2D(texture,adjustedTexCoord).a*color.a);
	gl_FragData[1] = vec4(normal*0.5+0.5,1.0);	
	//x = specularity / y = land(0.0/1.0)/shadow early exit(0.2)/water(0.05)/hand(0.8) / z = torch lightmap
	gl_FragData[2] = vec4(lmcoord.t, 0.8, lmcoord.s, 1.0f);
	
}