vec3 falloff(vec4 light, float d, float rad)
{
	d = d/rad + 0.88320;
	return (1/(d*d) - 0.281972)*(light.rgb*light.a);
}