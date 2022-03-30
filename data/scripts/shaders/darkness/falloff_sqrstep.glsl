uniform int steps = 5;

vec3 falloff(vec4 light, float d, float rad)
{	
	d = d/rad + 0.88320;
	return (ceil((1/(d*d) - 0.281972)*(steps+1))/(steps+1))*light.rgb*light.a;
}