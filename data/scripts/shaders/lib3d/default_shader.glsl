#define SURFACE default_surf

uniform sampler2D iChannel0;

//prefix n_ marks the sampler as a normal map
uniform sampler2D n_normalmap;

uniform sampler2D metallicmap;

uniform sampler2D roughnessmap;

uniform sampler2D occlusionmap;

uniform sampler2D emissivemap;

uniform float metallic = 0;

uniform float roughness = 1;

uniform float occlusion = 1;

uniform float emissive = 0;


//Default surface shader calculations
void default_surf(in fragdata data, inout surfdata o)
{
	o.albedo = texture2D( iChannel0, data.uv ) * data.color;
	vec4 e = texture2D( emissivemap, data.uv );
	o.emissive = e.rgb * e.a * emissive;
	o.normal = normal2D( n_normalmap, data.uv );
	o.metallic = texture2D( metallicmap, data.uv ).r * metallic;
	o.roughness = texture2D( roughnessmap, data.uv ).r * roughness;
	o.occlusion = clamp(mix(1, texture2D( occlusionmap, data.uv ).r, occlusion),0,1);
}