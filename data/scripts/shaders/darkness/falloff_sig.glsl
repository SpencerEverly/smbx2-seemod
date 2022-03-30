vec3 falloff(vec4 light, float d, float rad)
{	
	d = d/rad;
	
	return smoothstep(1,0.5,d)*(light.rgb*light.a);
}