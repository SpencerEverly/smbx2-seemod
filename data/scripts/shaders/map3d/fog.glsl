uniform vec3 fogColour;
uniform float fogStart;
uniform float fogDistance;
uniform float fogDensity;

float computeSundisk(vec3 light, vec3 viewDir, float dist, vec2 uv)
{	
	vec3 ld = -light;
	ld.y *= -1;
	float ldotd = dot(ld, viewDir);
	vec3 p = ld*dist/ldotd;
	
	return max(0,-sign(ldotd)) * clamp(4/length(uv-p.xy), 0, 1);
}

vec3 applyFog(vec4 c, float z)
{	
	float tint = clamp(pow(1.0-clamp((z-fogStart)/(fogDistance-fogStart),0.0,1.0), fogDensity),0.0,1.0);
	
	return c.rgb*tint + fogColour.rgb*c.a*(1-tint);
}


vec3 applyFogWithSun(vec4 c, float z, vec3 light, vec3 viewDir, float dist, vec2 uv)
{	
	float tint = clamp(pow(1.0-clamp((z-fogStart)/(fogDistance-fogStart),0.0,1.0), fogDensity),0.0,1.0);
	float sun = computeSundisk(light, viewDir, dist, uv);
	
	vec3 col = fogColour.rgb + mix(sun, 0, clamp(tint*6,0,1));
	
	return c.rgb*tint + col*c.a*(1-tint);
}

vec3 applySkyboxFog(vec4 c, float z)
{
	float tint = pow(clamp(z*z,0.0,1.0), fogDensity);
	
	return c.rgb*tint + fogColour.rgb*c.a*(1-tint);
}