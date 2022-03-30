uniform float shadowSoftness = 0.95;
uniform float shadowResolution = 0.5;

const vec2 screensize = vec2(800,600);

vec3 shadow(vec3 col, vec2 lightpos, vec2 pixpos)
{
	vec2 stp = -(lightpos-pixpos);
	float stepnum = floor(length(stp)*shadowResolution);
	stepnum = max(1,stepnum);
	stp = normalize(stp)/shadowResolution;
	
	vec2 newpos = pixpos;
	vec3 adder = col/stepnum;
	vec3 agg = vec3(0);
	float mult = 1;
	for (int i = 0; i < stepnum; i++)
    {
		newpos -= stp;
		float m = 1 - texture2D(mask, clamp((newpos-cameraPos)/screensize,0.001,0.999)).r;
		
		agg += adder*m;
		mult *= mix(shadowSoftness, 1, m);
	}
	agg *= mult;
	
	return agg;
}