uniform float shadowResolution = 0.5;

const vec2 screensize = vec2(800,600);

vec3 shadow(vec3 col, vec2 lightpos, vec2 pixpos)
{
	vec2 stp = -(lightpos-pixpos);
	float stepnum = floor(length(stp)*shadowResolution);
	stepnum = max(1,stepnum);
	stp = normalize(stp)/shadowResolution;
	
	vec2 newpos = pixpos;
	for (int i = 0; i < stepnum; i++)
    {
		newpos -= stp;
		
		float m = texture2D(mask, clamp((newpos-cameraPos)/screensize,0.001,0.999)).r;
		
		if(m > 0.5)
		{
			return vec3(0);
		}
		
		stp = normalize(-(lightpos-newpos))/shadowResolution;
	}
	return col;
}