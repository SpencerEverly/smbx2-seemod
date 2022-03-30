uniform int steps = 5;

vec3 falloff(vec4 light, float d, float rad)
{	
	d = d/rad;
	return (ceil((1-d)*(steps+1))/(steps+1))*(light.rgb*light.a);
}