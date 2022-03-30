vec3 falloff(vec4 light, float d, float rad)
{	
	return light.rgb*light.a;
}