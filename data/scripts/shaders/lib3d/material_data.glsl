struct vertdata
{
	vec3 position;
	vec3 normal;
	vec4 uv;
	vec4 color;
};

struct fragdata
{
	vec2 fragposition;
	vec3 worldposition;
	vec3 worldnormal;
	vec2 uv;
	vec4 color;
	float depth;
};

struct surfdata
{
	vec4 albedo;
	vec3 emissive;
	vec3 normal;
	float metallic;
	float roughness;
	float occlusion;
};


vec3 normal2D(sampler2D sampler, vec2 uv)
{
	return normalize(tgt2world * ((texture2D( sampler, uv ).rgb * 2) - 1));
}