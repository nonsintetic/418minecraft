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

varying vec4 texcoord;
varying vec3 lightVector;
varying vec3 ambient_color;
varying float handItemLight;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int worldTime;
uniform int heldItemId;
uniform float rainStrength;

// Ambient color 
	const ivec4 ToD2[25] = ivec4[25](ivec4(0,10,20,45), //hour,r,g,b
							ivec4(1,10,20,45),
							ivec4(2,10,20,45),
							ivec4(3,10,20,45),
							ivec4(4,10,20,45),
							ivec4(5,60,120,180),
							ivec4(6,160,200,255),
							ivec4(7,160,205,255),
							ivec4(8,160,210,260),
							ivec4(9,165,220,270),
							ivec4(10,190,235,280),
							ivec4(11,205,250,290),
							ivec4(12,220,250,300),
							ivec4(13,205,250,290),
							ivec4(14,190,235,280),
							ivec4(15,165,220,270),
							ivec4(16,150,210,260),
							ivec4(17,140,200,255),
							ivec4(18,120,140,220),
							ivec4(19,50,55,110),
							ivec4(20,10,20,45),
							ivec4(21,10,20,45),
							ivec4(22,10,20,45),
							ivec4(23,10,20,45),
							ivec4(24,10,20,45));

							
							
							
							
							
							
							
							
							
							
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main() {
	
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0;

	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	} else {
		lightVector = normalize(moonPosition);
	}

	handItemLight = 0.0;
	
	if (heldItemId == 50) {
		// torch
		handItemLight = 0.5;
		
	} else if (heldItemId == 76 || heldItemId == 94) {
		// active redstone torch / redstone repeater
		handItemLight = 0.0;
		
	} else if (heldItemId == 89) {
		// lightstone
		handItemLight = 0.5;
		
	} else if (heldItemId == 10 || heldItemId == 11 || heldItemId == 51) {
		// lava / lava / fire
		handItemLight = 0.5;
		
	} else if (heldItemId == 91) {
		// jack-o-lantern
		handItemLight = 0.5;
		
	} else if (heldItemId == 327) {
		handItemLight = 0.5;
	}

	

	float hour = worldTime/1000.0+6.0;
	if (hour > 24.0) hour = hour - 24.0;
	
	
							
	ivec4 tempa = ToD2[int(floor(hour))];
	ivec4 tempa2 = ToD2[int(floor(hour)) + 1];
	
	ambient_color = mix(vec3(tempa.yzw),vec3(tempa2.yzw),(hour-float(tempa.x))/float(tempa2.x-tempa.x))/255.0f;
	
	vec3 ambient_color_rain = vec3(0.2, 0.2, 0.2);
	ambient_color = sqrt(pow(mix(ambient_color, ambient_color_rain, rainStrength*0.75),vec3(2.0))*2.0*ambient_color);
	
}
