//Lambertian lighting
vec3 light(vec3 normal, vec4 albedo, vec3 viewDir, vec3 lightDir, vec4 lightCol, vec3 ambient)
{
	float ndotl = dot(normalize(normal), normalize(lightDir));
	
	//No light when sun is below horizon
	float ldotup = clamp(dot(lightDir, vec3(0,1,0)),0,1);
	ldotup *= ldotup;
	
	return albedo.rgb*clamp(lightCol.rgb*lightCol.a*ldotup*max(ndotl, 0) + ambient, 0, 1);
}
