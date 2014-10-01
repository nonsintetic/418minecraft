#version 120


/*
Chocapic13' shaders, derived from SonicEther v10 rc6
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

//to increase shadow draw distance, edit shadowDistance and SHADOWHPL below. Both should be equal. Needs decimal point.
//disabling is done by adding "//" to the beginning of a line.

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES





#define SHADOW_DARKNESS 0.34	//shadow darkness levels, lower values mean darker shadows, see .vsh for colors /0.27 is default
//#define VARIABLE_PENUMBRA_SHADOWS
//#define SHADOW_FILTER						//smooth shadows
//----------End of Shadows----------//

//----------Lighting----------//
	//#define DYNAMIC_HANDLIGHT		
	#define SUNLIGHTAMOUNT 1.1		//change sunlight strength , see .vsh for colors. /1.7 is default
//Torch Color//
	vec3 torchcolor = vec3(0.6,0.32,0.1);		//RGB - Red, Green, Blue / vec3(0.6,0.32,0.1) is default
	#define TORCH_ATTEN 3.0						//how much the torch light will be attenuated (decrease if you want that the torches cover a bigger area))/3.0 is default
	#define TORCH_INTENSITY 2.0					//torch light intensity /2.0 is default
//----------End of Lighting----------//

//----------Visual----------//
	#define GODRAYS
	const float density = 0.6;			
	const int NUM_SAMPLES = 5;			//increase this for better quality at the cost of performance /5 is default
	const float grnoise = 0.01;		//amount of noise /0.012 is default
	
	//#define SSAO					//works but is turned off by default due to performance cost
	//SSAO constants
	const int nbdir = 5;			//the two numbers here affect the number of sample used. Increase for better quality at the cost of performance /5 and 5 is default
	const float sampledir = 5;	
	const float ssaorad = 1.0;		//radius of ssao shadows /1.0 is default
	
	//#define CELSHADING
		#define BORDER 1.0

	const float	sunPathRotation	= -35.0f;		//determines sun/moon inclination /-35.0 is default - 0.0 is normal rotation
//----------End of Visual----------//

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES

const int 		R8					= 0;
const int 		gdepthFormat 			= R8;
const int 		RGBA8					= 1;
const int 		compositeFormat 			= RGBA8;


varying vec4 texcoord;
varying vec3 lightVector;
varying vec3 sunlight_color;
varying vec3 ambient_color;
varying float handItemLight;

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D gaux1;
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
uniform float rainStrength;
uniform float wetness;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int worldTime;
uniform int fogMode;

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

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
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


vec2 texel = vec2(1.0/viewWidth,1.0/viewHeight);
vec3 aux = texture2D(gaux1, texcoord.st).rgb;
vec3 sunPos = sunPosition;


float pixeldepth = texture2D(depthtex0,texcoord.xy).x;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float shadowexit = 0.0;

float handlight = handItemLight;


float torch_lightmap = pow(aux.b,TORCH_ATTEN)*TORCH_INTENSITY;

//poisson distribution for shadow sampling		
vec2 circle_offsets[25] = vec2[25](vec2(-0.4894566f,-0.3586783f),
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

float ctorspec(vec3 ppos, vec3 lvector, vec3 normal) {
    //half vector
	vec3 pos = -normalize(ppos);
    vec3 cHalf = normalize(lvector + pos);
	
    // beckman's distribution function D
    float normalDotHalf = dot(normal, cHalf);
    float normalDotHalf2 = normalDotHalf * normalDotHalf;

    float roughness2 = 0.05;
    float exponent = -(1.0 - normalDotHalf2) / (normalDotHalf2 * roughness2);
    float e = 2.71828182846;
    float D = pow(e, exponent) / (roughness2 * normalDotHalf2 * normalDotHalf2);
	
    // fresnel term F
	float normalDotEye = dot(normal, pos);
    float F = pow(1.0 - normalDotEye, 5.0);

    // self shadowing term G
    float normalDotLight = dot(normal, lvector);
    float X = 2.0 * normalDotHalf / dot(pos, cHalf);
    float G = min(1.0, min(X * normalDotLight, X * normalDotEye));
    float pi = 3.1415927;
    float CookTorrance = (D*F*G)/(pi*normalDotEye);
	
    return max(CookTorrance/pi,0.0);
}

float diffuseorennayar(vec3 pos, vec3 lvector, vec3 normal, float spec, float roughness) {
	
    vec3 v=normalize(pos);
	vec3 l=normalize(lvector);
	vec3 n=normalize(normal);

	float vdotn=dot(v,n);
	float ldotn=dot(l,n);
	float cos_theta_r=vdotn; 
	float cos_theta_i=ldotn; 
	float cos_phi_diff=dot(normalize(v-n*vdotn),normalize(l-n*ldotn));
	float cos_alpha=min(cos_theta_i,cos_theta_r); // alpha=max(theta_i,theta_r);
	float cos_beta=max(cos_theta_i,cos_theta_r); // beta=min(theta_i,theta_r)

	float r2=roughness*roughness;
	float a=1.0-0.5*r2/(r2+0.33);
	float b_term;
	
	if(cos_phi_diff>=0.0) {
		float b=0.45*r2/(r2+0.09);
		//b_term=b*sqrt((1.0-cos_alpha*cos_alpha)*(1.0-cos_beta*cos_beta))/cos_beta*cos_phi_diff;
		b_term = b*sin(cos_alpha)*tan(cos_beta)*cos_phi_diff;
	}
	else b_term=0.0;

	return clamp(cos_theta_i*(a+b_term*spec),0.0,1.0);
}

#ifdef CELSHADING
vec3 celshade(vec3 clrr) {
	//edge detect
	float d = edepth(texcoord.xy);
	float dtresh = 1/(far-near)/5000.0;	
	vec4 dc = vec4(d,d,d,d);
	vec4 sa;
	vec4 sb;
	sa.x = edepth(texcoord.xy + vec2(-pw,-ph)*BORDER);
	sa.y = edepth(texcoord.xy + vec2(pw,-ph)*BORDER);
	sa.z = edepth(texcoord.xy + vec2(-pw,0.0)*BORDER);
	sa.w = edepth(texcoord.xy + vec2(0.0,ph)*BORDER);
	
	//opposite side samples
	sb.x = edepth(texcoord.xy + vec2(pw,ph)*BORDER);
	sb.y = edepth(texcoord.xy + vec2(-pw,ph)*BORDER);
	sb.z = edepth(texcoord.xy + vec2(pw,0.0)*BORDER);
	sb.w = edepth(texcoord.xy + vec2(0.0,-ph)*BORDER);
	
	vec4 dd = abs(2.0* dc - sa - sb) - dtresh;
	dd = vec4(step(dd.x,0.0),step(dd.y,0.0),step(dd.z,0.0),step(dd.w,0.0));
	
	float e = clamp(dot(dd,vec4(0.5f,0.5f,0.5f,0.5f)),0.0,1.0);
	return clrr*e;
}
#endif

float getnoise(vec2 pos) {
return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));

}

float interpolate(vec3 truepos,float center,vec3 poscenter,float value2,vec3 pos2,float value3,vec3 pos3,float value4,vec3 pos4,float value5,vec3 pos5) {
/*
float mix1 = mix(center,value2,1.0-length(truepos-pos2));
float mix2 = mix(mix1,value3,1.0-length(truepos-pos3));
float mix3 = mix(mix2,value4,1.0-length(truepos-pos4));
return mix(mix3,value5,1.0-length(truepos-pos5));
*/
return center*(1.0-distance(truepos,poscenter))+value2*(1.0-distance(truepos,pos2))+value3*(1.0-distance(truepos,pos3))+value4*(1.0-distance(truepos,pos4))+value5*(1.0-distance(truepos,pos5));
}

//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {
	
	
	#ifndef DYNAMIC_HANDLIGHT
	handlight = 0.0;
	#endif

	float shadowexit = float(aux.g > 0.1 && aux.g < 0.3);
	float land = float(aux.g > 0.03);
	float iswater = float(aux.g > 0.04 && aux.g < 0.07);
	float translucent = float(aux.g > 0.3 && aux.g < 0.5);
	float hand = float(aux.g > 0.75 && aux.g < 0.85);
	
	vec3 color = texture2D(gcolor, texcoord.st).rgb;
	color = pow(color,vec3(2.2));



if (isEyeInWater < 0.1 && land < 0.9){
		color = mix(color,(gl_Fog.color.rgb+vec3(0.25,0.25,0.25))/2.0,rainStrength)*vec3(0.75,0.82,1.0);
	}

/* DRAWBUFFERS:31 */

#ifdef CELSHADING
	if (land > 0.9 && iswater < 0.9) color = celshade(color);
#endif


	
	
	#ifdef GODRAYS
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;
	
	float gr = 0.0;
	
	float truepos = pow(clamp(dot(-lightVector,tpos.xyz)/length(tpos.xyz),0.0,1.0),0.5);		//temporary fix that check if the sun/moon position is correct
	
	if (truepos > 0.05) {	
		vec2 deltaTextCoord = vec2( texcoord.st - lightPos.xy );
		vec2 textCoord = texcoord.st;
		deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
	
			float avgdecay = 0.0;
			float distx = abs(texcoord.x*aspectRatio-lightPos.x*aspectRatio);
			float disty = abs(texcoord.y-lightPos.y);
			vec2 noise = vec2(getnoise(textCoord),getnoise(-textCoord.yx+0.05));
			
			for(int i=0; i < NUM_SAMPLES ; i++) {			
				textCoord -= deltaTextCoord;
				float sample = step(texture2D(gaux1, textCoord+ textCoord*noise*grnoise).g,0.01);
				gr += sample;
		}
	}
	#endif
float visiblesun = 0.0;
float temp;
int nb = 0;

			
//calculate sun occlusion (only on one pixel) 
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
		
	color = pow(color,vec3(1.0/2.2));
	color = clamp(color,0.0,1.0);
	gl_FragData[0] = vec4(color, visiblesun);
	gl_FragData[1] = vec4(vec3((gr/NUM_SAMPLES)),1.0);
}
