vec3 falloff(vec4 light, float d, float rad)
{
	d = d/rad;
	return (1-d)*(light.rgb*light.a);
}