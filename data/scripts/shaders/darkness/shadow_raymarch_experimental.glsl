uniform float shadowSoftness = 0.95;
uniform float shadowResolution = 0.5;

const vec2 screensize = vec2(800,600);

#include "shaders/logic.glsl"
#include "shaders/darkness/coordsmap.glsl"

vec3 shadow(vec3 col, vec2 lightpos, vec2 pixpos)
{
	/*
	vec2 stp = -(lightpos-pixpos);
	float stepnum = floor(length(stp)*shadowResolution);
	stepnum = max(1,stepnum);
	stp = normalize(stp)/shadowResolution;
	
	vec2 newpos = lightpos;
	vec3 adder = col/stepnum;
	vec3 agg = vec3(0);
	for (int i = 0; i < stepnum; i++)
    {
		newpos += stp;
		float m = 1 - texture2D(mask, (newpos-cameraPos)/screensize).r;
		
		agg += adder*m;
		agg *= mix(shadowSoftness, 1, m);
	}
	*/
	
	/*
	vec2 origin = (lightpos-cameraPos)/screensize;
	vec2 dir = normalize(gl_TexCoord[0].xy - origin);
	vec3 agg = col;
	vec2 newpos = gl_TexCoord[0].xy;
	vec3 adder = col/64;
	float t = 0.0;
	for (int i = 0; i < 64; i++)
    {
		float d = texture2D(mask, clamp(gl_TexCoord[0].xy - (dir * t),0.001,0.999)).b;
		
		agg *= mix(1, 0, lt(d,0.001));
		
		t += d;
	}
	
	return agg;
	*/
	
	vec2 dir = lightpos-pixpos;
	dir = normalize(dir);
	vec2 newpos = pixpos;
	vec3 agg = col;
	
	for (int i = 0; i < 2000; i++)
	{
		float d = texture2D(mask, clamp((newpos-cameraPos)/screensize,0.001,0.999)).b;
		float lightdist = length(lightpos-newpos);
		if(lightdist < d*800)
		{
			return col;
		}
		
		newpos += d*800*dir;
		
		if(d <= 0)
		{
			agg *= 1 - length(lightpos-newpos)/64;
			return agg;
		}
	}
	
	
	return agg;
}