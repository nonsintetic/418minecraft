#version 120

/*
Chocapic13' shaders, derived from SonicEther v10 rc6
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

//disabling is done by adding "//" to the beginning of a line.

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES

#define LENS_EFFECTS
#define LENS_STRENGTH 0.62

//#define BLOOM								//do the "fog blur" in the same time
	//#define B_HQ					
	#define B_LQ			
	#define B_TRESH 0.4				
	#define B_RAD 20.0					//sampling circle size multiplier, don't affect performance
	#define B_INTENSITY 1.0		//basic multiplier

//#define DOF
	//lens properties
const float focal = 0.024;
float aperture = 0.009;	
const float sizemult = 100.0;
/*
Try different setting by replacing the values above by the values here
----------------------------------
"Near to human eye (for gameplay,default)":

const float focal = 0.024;
float aperture = 0.009;	
const float sizemult = 100.0;
----------------------------------
"Tilt shift (cinematics)":

const float focal = 0.3;
float aperture = 0.3;	
const float sizemult = 1.0;
----------------------------------
"Camera (cinematics)":

const float focal = 0.05;
float aperture = focal/7.0;	
const float sizemult = 100.0;
---------------------------------- 
*/
#define TONEMAP
#define TONEMAP_CURVE 2.0
#define CONTRAST 0.3
#define GAMMA 1.0							//1.0 = default Gamma. Higher values mean darker.
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES



varying vec4 texcoord;
varying vec3 sunlight;

uniform sampler2D depthtex2;
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
vec3 sunPos = sunPosition;
uniform int fogMode;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float timefract = worldTime;

//Raining
float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;
float wetx  = clamp(wetness, 0.0f, 1.0f);

//Calculate Time of Day
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

// Standard depth function.
float getDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

#ifdef BLOOM
	#ifdef B_LQ
		const vec2 offsets[25] = vec2[25](vec2(-0.4894566f,-0.3586783f),
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
	#endif
	
	#ifdef B_HQ
		const vec2 offsets[60] = vec2[60](vec2( 0.0000, 0.2500 ),
									vec2( -0.2165, 0.1250 ),
									vec2( -0.2165, -0.1250 ),
									vec2( -0.0000, -0.2500 ),
									vec2( 0.2165, -0.1250 ),
									vec2( 0.2165, 0.1250 ),
									vec2( 0.0000, 0.5000 ),
									vec2( -0.2500, 0.4330 ),
									vec2( -0.4330, 0.2500 ),
									vec2( -0.5000, 0.0000 ),
									vec2( -0.4330, -0.2500 ),
									vec2( -0.2500, -0.4330 ),
									vec2( -0.0000, -0.5000 ),
									vec2( 0.2500, -0.4330 ),
									vec2( 0.4330, -0.2500 ),
									vec2( 0.5000, -0.0000 ),
									vec2( 0.4330, 0.2500 ),
									vec2( 0.2500, 0.4330 ),
									vec2( 0.0000, 0.7500 ),
									vec2( -0.2565, 0.7048 ),
									vec2( -0.4821, 0.5745 ),
									vec2( -0.6495, 0.3750 ),
									vec2( -0.7386, 0.1302 ),
									vec2( -0.7386, -0.1302 ),
									vec2( -0.6495, -0.3750 ),
									vec2( -0.4821, -0.5745 ),
									vec2( -0.2565, -0.7048 ),
									vec2( -0.0000, -0.7500 ),
									vec2( 0.2565, -0.7048 ),
									vec2( 0.4821, -0.5745 ),
									vec2( 0.6495, -0.3750 ),
									vec2( 0.7386, -0.1302 ),
									vec2( 0.7386, 0.1302 ),
									vec2( 0.6495, 0.3750 ),
									vec2( 0.4821, 0.5745 ),
									vec2( 0.2565, 0.7048 ),
									vec2( 0.0000, 1.0000 ),
									vec2( -0.2588, 0.9659 ),
									vec2( -0.5000, 0.8660 ),
									vec2( -0.7071, 0.7071 ),
									vec2( -0.8660, 0.5000 ),
									vec2( -0.9659, 0.2588 ),
									vec2( -1.0000, 0.0000 ),
									vec2( -0.9659, -0.2588 ),
									vec2( -0.8660, -0.5000 ),
									vec2( -0.7071, -0.7071 ),
									vec2( -0.5000, -0.8660 ),
									vec2( -0.2588, -0.9659 ),
									vec2( -0.0000, -1.0000 ),
									vec2( 0.2588, -0.9659 ),
									vec2( 0.5000, -0.8660 ),
									vec2( 0.7071, -0.7071 ),
									vec2( 0.8660, -0.5000 ),
									vec2( 0.9659, -0.2588 ),
									vec2( 1.0000, -0.0000 ),
									vec2( 0.9659, 0.2588 ),
									vec2( 0.8660, 0.5000 ),
									vec2( 0.7071, 0.7071 ),
									vec2( 0.5000, 0.8660 ),
									vec2( 0.2588, 0.9659 ));
	#endif
	
#endif


#ifdef DOF

//hexagon pattern
const vec2 hex_offsets[60] = vec2[60] (	vec2(  0.2165,  0.1250 ),
									vec2(  0.0000,  0.2500 ),
									vec2( -0.2165,  0.1250 ),
									vec2( -0.2165, -0.1250 ),
									vec2( -0.0000, -0.2500 ),
									vec2(  0.2165, -0.1250 ),
									vec2(  0.4330,  0.2500 ),
									vec2(  0.0000,  0.5000 ),
									vec2( -0.4330,  0.2500 ),
									vec2( -0.4330, -0.2500 ),
									vec2( -0.0000, -0.5000 ),
									vec2(  0.4330, -0.2500 ),
									vec2(  0.6495,  0.3750 ),
									vec2(  0.0000,  0.7500 ),
									vec2( -0.6495,  0.3750 ),
									vec2( -0.6495, -0.3750 ),
									vec2( -0.0000, -0.7500 ),
									vec2(  0.6495, -0.3750 ),
									vec2(  0.8660,  0.5000 ),
									vec2(  0.0000,  1.0000 ),
									vec2( -0.8660,  0.5000 ),
									vec2( -0.8660, -0.5000 ),
									vec2( -0.0000, -1.0000 ),
									vec2(  0.8660, -0.5000 ),
									vec2(  0.2163,  0.3754 ),
									vec2( -0.2170,  0.3750 ),
									vec2( -0.4333, -0.0004 ),
									vec2( -0.2163, -0.3754 ),
									vec2(  0.2170, -0.3750 ),
									vec2(  0.4333,  0.0004 ),
									vec2(  0.4328,  0.5004 ),
									vec2( -0.2170,  0.6250 ),
									vec2( -0.6498,  0.1246 ),
									vec2( -0.4328, -0.5004 ),
									vec2(  0.2170, -0.6250 ),
									vec2(  0.6498, -0.1246 ),
									vec2(  0.6493,  0.6254 ),
									vec2( -0.2170,  0.8750 ),
									vec2( -0.8663,  0.2496 ),
									vec2( -0.6493, -0.6254 ),
									vec2(  0.2170, -0.8750 ),
									vec2(  0.8663, -0.2496 ),
									vec2(  0.2160,  0.6259 ),
									vec2( -0.4340,  0.5000 ),
									vec2( -0.6500, -0.1259 ),
									vec2( -0.2160, -0.6259 ),
									vec2(  0.4340, -0.5000 ),
									vec2(  0.6500,  0.1259 ),
									vec2(  0.4325,  0.7509 ),
									vec2( -0.4340,  0.7500 ),
									vec2( -0.8665, -0.0009 ),
									vec2( -0.4325, -0.7509 ),
									vec2(  0.4340, -0.7500 ),
									vec2(  0.8665,  0.0009 ),
									vec2(  0.2158,  0.8763 ),
									vec2( -0.6510,  0.6250 ),
									vec2( -0.8668, -0.2513 ),
									vec2( -0.2158, -0.8763 ),
									vec2(  0.6510, -0.6250 ),
									vec2(  0.8668,  0.2513 ));

#endif

//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

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
void main() {
	vec2 fake_refract = vec2(sin(worldTime/15.0 + texcoord.x*100.0 + texcoord.y*50.0),cos(worldTime/15.0 + texcoord.y*100.0 + texcoord.x*50.0)) * isEyeInWater;
	vec3 color = texture2D(gaux2, texcoord.st + fake_refract * 0.005).rgb;
	
/*
#ifdef DOF
	float focal = ld(texture2D(depthtex2,vec2(0.5)).x);
	float ddiff;
	float mult = 1.0;
	vec3 bcolor = vec3(0.0);
	vec2 samplecoord;
	bcolor = color.rgb;
	for (int i = -3; i < 4; i++) {
		for (int j = -3; j < 4; j++) {
			samplecoord = vec2(pw*i*2.0f,pw*cos(j/3.0f)*6.0f);
			ddiff = ld(texture2D(depthtex2, texcoord.xy + samplecoord).x);
			if (ddiff - ld(depth) < 0.0) {
				ddiff -= -focal;
				bcolor += texture2D(gaux2,texcoord.xy + samplecoord).rgb*ddiff;
				mult += ddiff;
			}
		}
	}
	color.rgb = bcolor/mult;
#endif
*/


#ifdef DOF
	
	//Calculate pixel Circle of Confusion that will be used for bokeh depth of field
	float z = ld(texture2D(depthtex2, texcoord.st).r)*far;
	float focus = ld(texture2D(depthtex2, vec2(0.5)).r)*far;
	float pcoc = min(abs(aperture * (focal * (z - focus)) / (z * (focus - focal)))*sizemult,pw*10.0);		
	
	vec4 sample = vec4(0.0);
	vec3 bcolor = vec3(0.0);
	float nb = 0.0;
	vec2 bcoord = vec2(0.0);

	for ( int i = 0; i < 60; i++) {
		sample = texture2D(gaux2, texcoord.xy + hex_offsets[i]*pcoc*vec2(1.0,aspectRatio));
		bcolor += sample.rgb;
	}
	
	color.rgb = bcolor/60.0;
	
#endif
	
	float plum = luma(color.rgb);

#ifdef BLOOM
const int GL_LINEAR = 9729;
const int GL_EXP = 2048;
	//color.rgb = color.rgb*(1.0+(luma(color.rgb)-texture2D(gaux2,vec2(1.0)).a));
	vec3 blur = vec3(0.0);
	float depth_diff = clamp(pow(ld(texture2D(depthtex2, texcoord.st).r)*4.0,0.8),0.0,1.0)+0.1;
	float fog = 0.0;
	if (fogMode == 0) fog = 1.0-clamp(exp(-ld(texture2D(depthtex2, texcoord.st).r)),0.0,1.0);
	#ifdef B_LQ
			float scale = length(vec2(pw,ph));
			vec3 csample = vec3(0.0);
				for (int i=0; i < 25; i++) {
				vec2 coords = offsets[i];
				vec3 sample = texture2D(gaux2,texcoord.xy + coords*B_RAD*scale).rgb;
				csample += max(texture2D(gaux2,texcoord.xy + coords*B_RAD*scale).rgb-plum*0.75-B_TRESH,0.0) * (length(coords)+0.6)/2.0;
				blur += sample;
			}
			color += csample/25.0*B_INTENSITY;
		
		//fog blurring with the distance
		color.rgb = mix(color,blur/25.0,depth_diff*isEyeInWater*0.4+fog*(1.0-isEyeInWater)*rainStrength);
	#endif

	#ifdef B_HQ
			float scale = length(vec2(pw,ph));
			vec3 csample = vec3(0.0);
				for (int i=0; i < 60; i++) {
				vec2 coords = offsets[i];
				vec3 sample = texture2D(gaux2,texcoord.xy + coords*B_RAD*scale).rgb;
				csample += max(texture2D(gaux2,texcoord.xy + coords*B_RAD*scale).rgb-plum*0.75-B_TRESH,0.0) * (length(coords)+0.6)/2.0;
				blur += sample;
			}
			color += csample/60.0*B_INTENSITY;
		
		//fog blurring with the distance
		color.rgb = mix(color,blur/60.0,depth_diff*isEyeInWater*0.4+fog*(1.0-isEyeInWater)*rainStrength);
	#endif
	
#endif
	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lightPos = tpos.xy/tpos.z;
		lightPos = (lightPos + 1.0f)/2.0f;
		
#ifdef LENS_EFFECTS
float xdist = abs(lightPos.x-texcoord.x);
float ydist = abs(lightPos.y-texcoord.y);
float xydist = distance(lightPos.xy,texcoord.xy);
float xydistratio = distratio(lightPos.xy,texcoord.xy,aspectRatio);

float distof = min(min(1.0-lightPos.x,lightPos.x),min(1.0-lightPos.y,lightPos.y));
float fading = clamp(1.0-step(distof,0.1)+pow(distof*10.0,5.0),0.0,1.0);

float time = float(worldTime);
float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/300.0,0.0,1.0) + clamp((time-22800.0)/200.0,0.0,1.0)-clamp((time-23400.0)/200.0,0.0,1.0));

float sunvisibility = min(texture2D(gaux2,vec2(0.0)).a*2.5,1.0) * (1.0-rainStrength*0.9) * fading * transition_fading;


//float anamorphic_lens = clamp( 0.75-(pow(ydist,0.1)) - pow(xdist*2.0,2.0),0.0,1.0)*5.0;


float centerdist = distance(lightPos.xy,vec2(0.5))/1.412;
float sizemult = 1.0 + centerdist;
float noise = fract(sin(dot(texcoord.st ,vec2(18.9898f,28.633f))) * 4378.5453f)*0.1 + 0.9;
							
float circles_lens = 0.0;


if (sunvisibility > 0.05) {
/*
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
circles_lens += gen_circular_lens(coord,carac.z*0.75)*strength;

carac = pattern[i];
carac.x /= aspectRatio;
carac.yx *= (2.0 - dir)/2.5;

coord = -carac.yx * sizemult + lightPos.xy;
strength = sin(length(coord-vec2(0.5))*40.0)*0.5+0.5;
circles_lens += gen_circular_lens(coord,carac.z*0.66)*strength;
}
color += sunlight*vec3(circles_lens) * sunvisibility * noise * 0.25 ;
}

*/
if (ydist < 0.27) {
float anamorphic_lens = max(pow(max(1.0 - ydist/1.412,0.01),8.0)-0.2,0.0);
color += sunlight * vec3(0.0,0.0,1.0)*anamorphic_lens*LENS_STRENGTH*sunvisibility;
}
}
//rain drops on screen
if (rainStrength > 0.1) {
const float pi = 3.14159265359;
vec3 fogclr = mix(gl_Fog.color.rgb,vec3(0.25,0.25,0.25),rainStrength)*vec3(0.7,0.7,1.0);
float rainlens = 0.0;
float time = frameTimeCounter;
float gen = sin(time*pi)*0.5+0.5;
vec2 pos = noisepattern(vec2(-0.94386347*floor(time*0.5+0.25),floor(time*0.5+0.25)));
rainlens += gen_circular_lens(pos,0.023)*gen*rainStrength;

gen = cos(time*pi)*0.5+0.5;
pos = noisepattern(vec2(0.9347*floor(time*0.5+0.5),-0.2533282*floor(time*0.5+0.5)));
rainlens += gen_circular_lens(pos,0.023)*gen*rainStrength;

gen = cos(time*pi)*0.5+0.5;
pos = noisepattern(vec2(0.785282*floor(time*0.5+0.5),-0.285282*floor(time*0.5+0.5)));
rainlens += gen_circular_lens(pos,0.023)*gen*rainStrength;

gen = sin(time*pi)*0.5+0.5;
pos = noisepattern(vec2(-0.347*floor(time*0.5+0.25),0.6847*floor(time*0.5+0.25)));
rainlens += gen_circular_lens(pos,0.023)*gen*rainStrength;
color += 0.2*fogclr*rainlens*(eyeBrightness.y/255.0);

}

/*
float chroma_circle = pow(xydistratio/1.412,0.5)*0.5;

vec3 circle_color = clamp(sin(xydistratio*5.5+4.7)*vec3(1.0,0.5,0.1)*chroma_circle,0.0,1.0);

color+= sunlight*vec3(circle_color)*LENS_STRENGTH*sunvisibility;
*/
#endif

color = clamp(color,0.0,1.0);

float white = luma(color);
color = color*(1.0+pow(white,CONTRAST))/(2.0-CONTRAST);

color = pow(color,vec3(2.2));
#ifdef TONEMAP

color = color / (color + TONEMAP_CURVE) * (1.0+TONEMAP_CURVE);


#endif

#ifdef COLOR_SAT
vec3 input = color;
float rdist = max(color.r*sqrt(2.0)-length(color.gb),0.0)*(1.0/length(color));
float gdist = max(color.g*sqrt(2.0)-length(color.rb),0.0)*(1.0/length(color));
float bdist = max(color.b*sqrt(2.0)-length(color.rg),0.0)*(1.0/length(color));
color *= (vec3(rdist,gdist,bdist)+SAT)/SAT;

#endif
color = pow(color,vec3(1.0/2.2));
/*
	if (texcoord.x < 0.1 && texcoord.y < 0.1) color.rgb = vec3(texture2D(gaux2,vec2(1.0)).a);
*/

	
	gl_FragColor = vec4(color,1.0);
	
}
