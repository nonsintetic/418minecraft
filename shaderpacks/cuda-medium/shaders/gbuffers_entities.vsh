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

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;

attribute vec4 mc_Entity;

uniform int worldTime;
uniform float rainStrength;











/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main() {
	
	texcoord = gl_MultiTexCoord0;
	
	vec4 position = gl_Vertex;
	
	vec4 locposition = gl_ModelViewMatrix * gl_Vertex;
	
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * position);
	
	color = gl_Color;
	
	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	
	gl_FogFragCoord = gl_Position.z;
	
	normal = normalize(gl_NormalMatrix * gl_Normal);
	
}