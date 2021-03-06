#version 120
	vec3 torchcolor = vec3(0.6,0.32,0.1);		//RGB - Red, Green, Blue / vec3(0.6,0.32,0.1) is default
	#define TORCH_ATTEN 3.0						//how much the torch light will be attenuated (decrease if you want that the torches cover a bigger area))/3.0 is default
	#define TORCH_INTENSITY 2.0					//torch light intensity /2.0 is default
const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;

uniform sampler2D texture;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int fogMode;
uniform float rainStrength;
uniform int worldTime;

float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;


	////////////////////sunlight color////////////////////
	////////////////////sunlight color////////////////////
	////////////////////sunlight color////////////////////
	const ivec4 ToD[25] = ivec4[25](ivec4(0,10,20,45), //hour,r,g,b
							ivec4(1,10,20,45),
							ivec4(2,10,20,45),
							ivec4(3,10,20,45),
							ivec4(4,10,20,45),
							ivec4(5,10,20,45),
							ivec4(6,120,80,35),
							ivec4(7,255,195,80),
							ivec4(8,255,200,97),
							ivec4(9,255,200,110),
							ivec4(10,255,205,125),
							ivec4(11,255,215,140),
							ivec4(12,255,215,140),
							ivec4(13,255,215,140),
							ivec4(14,255,205,125),
							ivec4(15,255,200,110),
							ivec4(16,255,200,97),
							ivec4(17,255,195,80),
							ivec4(18,255,190,70),
							ivec4(19,77,67,194),
							ivec4(20,10,20,45),
							ivec4(21,10,20,45),
							ivec4(22,10,20,45),
							ivec4(23,10,20,45),
							ivec4(24,10,20,45));

	////////////////////ambient color////////////////////
	////////////////////ambient color////////////////////
	////////////////////ambient color////////////////////
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
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {
	
	vec3 lightVector;
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	}
	
	else {
		lightVector = normalize(moonPosition);
	}
	vec3 albedo = pow(texture2D(texture,texcoord.st).rgb*color.rgb,vec3(2.2));
/* DRAWBUFFERS:04 */
	
	float NdotL = dot(lightVector,normal);
	
	//colors
	float hour = worldTime/1000.0+6.0;
	if (hour > 24.0) hour = hour - 24.0;

							
	ivec4 temp = ToD[int(floor(hour))];
	ivec4 temp2 = ToD[int(floor(hour)) + 1];
	
	vec3 sunlight_color = mix(vec3(temp.yzw),vec3(temp2.yzw),(hour-float(temp.x))/float(temp2.x-temp.x))/255.0f;
	
	sunlight_color = mix(sunlight_color,vec3(0.15),rainStrength)*sunlight_color;

							
	ivec4 tempa = ToD2[int(floor(hour))];
	ivec4 tempa2 = ToD2[int(floor(hour)) + 1];
	
	vec3 ambient_color = mix(vec3(tempa.yzw),vec3(tempa2.yzw),(hour-float(tempa.x))/float(tempa2.x-tempa.x))/255.0f;
	ambient_color = mix(ambient_color,vec3(0.15),rainStrength)*ambient_color;
	
	float sky_atten = min(lmcoord.t*lmcoord.t*lmcoord.t+0.01,1.0);
	
	float lightsphere = NdotL*0.5+0.5;
	vec3 lightcol = mix(ambient_color*0.33,sunlight_color*1.85,lightsphere);
	lightcol = mix(ambient_color*0.5,lightcol,sky_atten*sky_atten*sky_atten*sky_atten)*sky_atten;
	
	float torchlight = lmcoord.s* lmcoord.s* lmcoord.s*TORCH_INTENSITY;
	vec3 pixcolor = pow(albedo*(lightcol+torchlight*torchcolor),vec3(1.0/2.2));
	
	gl_FragData[0] = vec4(pixcolor,texture2D(texture,texcoord.st).a*color.a);
	gl_FragData[1] = vec4(0.0, 0.4, lmcoord.s, 1.0);
	
}