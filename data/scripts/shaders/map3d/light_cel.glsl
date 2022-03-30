//Lambertian lighting
vec3 light(vec3 normal, vec4 albedo, vec3 viewDir, vec3 lightDir, vec4 lightCol, vec3 ambient)
{
	float ndotl = max(dot(normalize(normal), normalize(lightDir)), 0);
	
	//No light when sun is below horizon
	float ldotup = clamp(dot(lightDir, vec3(0,1,0)),0,1);
	ldotup *= ldotup;
	
	return albedo.rgb*clamp(lightCol.rgb*lightCol.a*ldotup*step(0.5, ndotl) + ambient, 0, 1);
}
