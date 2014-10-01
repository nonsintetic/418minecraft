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
varying vec3 sunlight;
varying vec3 lightVector;
varying vec3 ambient_color;

uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux4;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D gnormal;
uniform sampler2D gdepth;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform vec3 skyColor;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 previousCameraPosition;
uniform ivec2 eyeBrightness;
uniform float far;
uniform float near;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float wetness;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform int isEyeInWater;
uniform int worldTime;
uniform int fogMode;

float rainStrength2 = clamp(wetness, 0.0f, 1.0f)/1.0f;

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;

float timefract = worldTime;
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset2  = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 13000.0, 13001.0) - 13000.0) / 1.0);
float TimeMidnight2 = ((clamp(timefract, 13000.0, 13001.0) - 13000.0) / 1.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);
float TimeMidnight3 = ((clamp(timefract, 12500.0, 13250.0) - 12500.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);
float TimeDay = TimeSunrise+ TimeNoon + TimeSunset;

vec3 fogclr = mix(gl_Fog.color.rgb,vec3(0.2,0.2,0.2),rainStrength2)*ambient_color;
	
vec3 fragpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
vec3 aux = texture2D(gaux1, texcoord.st).rgb;
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0 - 1.0;
	
vec4 color = texture2D(composite,texcoord.xy);
	
float material_flag = texture2D(gaux1,texcoord.xy).g;
float lightmap = pow(aux.r,3.0);
float iswet = wetness*pow(lightmap,5.0)*sqrt(0.5+max(dot(normal,normalize(upPosition)),0.0));
	
float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.x-0.5),abs(coord.y-0.5))*2.0;
}

float getnoise(vec2 pos) {
    return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}

const int maxf = 4;				//number of refinements
const float stp = 1.2;			//size of one step for raytracing algorithm
const float ref = 0.1;			//refinement multiplier
const float inc = 2.2;			//increasement factor at each step

vec2 textCoord = texcoord.st;
float noise = vec2(getnoise(textCoord),getnoise(-textCoord.yx+0.05));

vec4 raytrace(vec3 fragpos, vec3 normal) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
    for(int i=0;i<30;i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = distance(fragpos.xyz,spos.xyz);
        if(err < length(vector)*pow(length(tvector),0.11)*1.75){

                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 5.0), 0.0, 1.0);
                    color = texture2D(composite, pos.st);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
				tvector -=vector;
                vector *=ref;
				
        
}
        vector *= inc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
    return color;
}

vec4 ground_raytrace(vec3 fragpos, vec3 normal) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = 20 * rvector * noise;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
    for(int i=0;i<30;i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = distance(fragpos.xyz,spos.xyz);
        if(err < length(vector)*pow(length(tvector),0.11)*1.75){

                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 5.0), 0.0, 1.0);
                    color = texture2D(composite, pos.st);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
				tvector -=vector;
                vector *=0.5;
			
        
}
        vector *= 2.0;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
    return color;
}



float distratio(vec2 pos, vec2 pos2, float ratio) {
    float xvect = pos.x*ratio-pos2.x*ratio;
    float yvect = pos.y-pos2.y;
    return sqrt(xvect*xvect + yvect*yvect);
}











/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main() {

	int land = int(material_flag < 0.03);
	int iswater = int(material_flag > 0.04 && material_flag < 0.07);
	int hand  = int(material_flag > 0.75 && material_flag < 0.85);
	
	fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));

	
	
// rain reflections

    if (iswater < 0.99 && rainStrength2 > 0.01) {
	
	    vec4 reflection = ground_raytrace(fragpos, normal);
		
		    float normalDotEye = dot(normal, normalize(fragpos));
		    float fresnel = clamp(pow(1.0 + normalDotEye, 1.0),0.0,1.0);
		
		    reflection.rgb = mix(gl_Fog.color.rgb/2, reflection.rgb, reflection.a);			//fake sky reflection, avoid empty spaces
		    reflection.a = min(reflection.a + 0.5,0.5);
		    color.rgb = mix(color.rgb,reflection.rgb , fresnel *reflection.a*iswet);
		    color.rgb += color.a*sunlight*(1.0-rainStrength2)*3.0;
		
	}
		




// water reflections

    if (iswater > 0.99) {

	    vec4 reflection = raytrace(fragpos, normal);
		
		    float normalDotEye = dot(normal, normalize(fragpos));
		    float fresnel = clamp(pow(1.0 + normalDotEye, 5.0),0.0,1.0);
		
		    reflection.rgb = mix(gl_Fog.color.rgb, reflection.rgb, reflection.a);			//fake sky reflection, avoid empty spaces
		    reflection.a = min(reflection.a + 0.75,1.0);
		    color.rgb = mix(color.rgb,reflection.rgb , fresnel * (1.0-isEyeInWater*0.8) *2*color.rgb);
		    color.rgb += color.a*sunlight*(1.0-rainStrength2)*3.0;
		
	}
	



	
	vec3 colmult = mix(vec3(1.0),vec3(0.08,0.24,0.43),isEyeInWater);
	vec3 colmult2 = mix(vec3(1.0),vec3(0.46,0.69,0.81),iswater);
	float depth_diff = clamp(pow(ld(texture2D(depthtex0, texcoord.st).r)*3.9,2.0),0.0,0.8);
	color.rgb = mix(color.rgb*colmult*colmult2,vec3(0.05,0.1,0.15)*0.5,depth_diff*isEyeInWater);
	
    float time = float(worldTime);
	float transition_fading = 1.0-(clamp((time-12000.0)/500.0,0.0,1.0)-clamp((time-13000.0)/500.0,0.0,1.0) + clamp((time-22800.0)/400.0,0.0,1.0)-clamp((time-23400.0)/600.0,0.0,1.0));
		
		
		
// rain fog
	
	float fog = clamp(exp(-length(fragpos)/192.0*(1.0+rainStrength2)/1.4)+0.25*(1.0-rainStrength2),0.0,2.0);
	float fogfactor =  clamp(fog + hand,0.0,1.0);
	fogclr = mix(fogclr,color.rgb,(1.0-rainStrength2));
	color.rgb = mix(fogclr*(eyeBrightness.y/255.0),color.rgb,fogfactor);
		
		
		
		
/* DRAWBUFFERS:5 */
	
	//draw rain
	color += texture2D(gaux4,texcoord.xy).a*0.05;

	
	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;
	
	
	
// godrays
	
	const float EXPOSURE = 0.5;
	const float DENSITY = 0.5;			
	const int NUM_SAMPLES = 20;
	const float GR_NOISE = 0.0;
	
	float truepos = pow(clamp(dot(-lightVector,tpos.xyz)/length(tpos.xyz),0.0,1.0),0.25);
	if (truepos > 0.05) {
	    vec2 deltaTextCoord = vec2( texcoord.st - lightPos.xy );
    vec2 textCoord = texcoord.st;
    deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * DENSITY;
    float illuminationDecay = 1.0;
	vec2 noise = vec2(getnoise(textCoord),getnoise(-textCoord.yx+0.05));
	float gr = 0.0;
	float avgdecay = 0.0;
			float distx = abs(texcoord.x*aspectRatio-lightPos.x*aspectRatio);
			float disty = abs(texcoord.y-lightPos.y);
            illuminationDecay = pow(max(1.0-sqrt(distx*distx+disty*disty),0.0),1.0);
    for(int i=0; i < NUM_SAMPLES ; i++)
    {
		
            textCoord -= deltaTextCoord;
			



            float sample = texture2D(gdepth, textCoord + noise*GR_NOISE).r;
			gr += sample;

    }
	
	    if (isEyeInWater < 0.01) {
	        vec3 EXPOSURE_color_day = vec3(1.02, 0.59, 0.4)*TimeDay*(1.0 - rainStrength2 * 1.0);
	        vec3 EXPOSURE_color_night = vec3(0.13, 0.59, 0.99)*0.5*TimeMidnight2*(1.0 - rainStrength2 * 1.0);
	        vec3 EXPOSURE_color_rain = vec3(1.0, 1.0, 1.0)*0.3*rainStrength2 * (1.0-TimeMidnight2*1.0);
	
	        vec3 EXPOSURE_color = EXPOSURE_color_day + EXPOSURE_color_night + EXPOSURE_color_rain;
	
	        color.rgb = mix(color.rgb,pow(sunlight,vec3(1.0/4.0)),(gr/NUM_SAMPLES)*EXPOSURE*EXPOSURE_color*length(pow(sunlight,vec3(1.0/2.2)))*illuminationDecay*truepos/sqrt(3.0)*transition_fading);
	    } else {
	        color.rgb = mix(color.rgb,pow(sunlight,vec3(1.0/4.0)),(gr/NUM_SAMPLES)*0.3*length(pow(sunlight,vec3(1.0/2.2)))*illuminationDecay*truepos/sqrt(3.0)*transition_fading);
	    }
	}


	
	
	
// fake sun / rain sun
	
	if (land > 0.99) {
	    color.rgb += vec3(0.1, 0.15, 0.2)*TimeDay*rainStrength2;
		
	    vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		     tpos = vec4(tpos.xyz/tpos.w,1.0);
	    vec2 lightPos = tpos.xy/tpos.z;
		     lightPos = (lightPos + 1.0f)/2.0f;
	
        float xydistratio = distratio(lightPos.xy,texcoord.xy,aspectRatio);
	
        if ((worldTime < 23000 || worldTime > 13000) && -sunPosition.z < 0 && isEyeInWater < 0.99){
            float anamorphic_lens = max(pow(max(1.0 - xydistratio/1.012,0.01),2.0)-0.1,0.0);
            color.rgb += vec3(0.13, 0.59, 0.99) * 0.05 * TimeMidnight * anamorphic_lens * rainStrength2;
		}
		
        if ((worldTime < 13000 || worldTime > 23000) && sunPosition.z < 0){
            float anamorphic_lens = max(pow(max(1.0 - xydistratio/1.012,0.01),2.0)-0.1,0.0);
            color += 0.3 * TimeDay * anamorphic_lens * rainStrength2;
		}
		
        if ((worldTime < 13000 || worldTime > 23000) && sunPosition.z < 0){
            float anamorphic_lens = max(pow(max(1.0 - xydistratio/0.512,0.01),2.0)-0.1,0.0);
            color.rgb += vec3(1.02, 0.59, 0.4) * TimeDay * anamorphic_lens * (1.0-rainStrength2*1.0);
		}
	}


	
	
	
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

	color = clamp(color,0.0,1.0);
	gl_FragData[0] = vec4(color.rgb,visiblesun);
	
}
