#version 120
uniform mat4 mat_mvp;
uniform mat4 mat_p;
uniform mat4 obj2world;
uniform mat4 world2obj;
uniform float cam_nearclip;
uniform float cam_farclip;
uniform vec3 cam_position;

varying float _invdepth;
varying vec3 _world_normal;
varying vec3 _world_position;
varying vec4 _clippos;
varying vec3 view_dir;

varying mat3 tgt2world;

#define DEBUG_OFF 0
#define DEBUG_NORMALS 1
#define DEBUG_DEPTH 2
#define DEBUG_POSITION 3
#define DEBUG_UNLIT 4
#define DEBUG_OCCLUSION 5

#define DEBUG DEBUG_OFF

#define ALPHA_OPAQUE 0
#define ALPHA_CUTOFF 0.5
#define ALPHA_BLEND 1

#define ALPHAMODE ALPHA_OPAQUE

#define NUM_LIGHTS 10

#define UV_UNBOUND 0
#define UV_WRAP 1
#define UV_CLAMP 2

#define UV_MODE UV_WRAP

#define TONEMAP 1

uniform vec3 _dir_lightDirection[NUM_LIGHTS];
uniform vec4 _dir_lightColor[NUM_LIGHTS];

uniform vec4 _pnt_lightPosition[NUM_LIGHTS];
uniform vec4 _pnt_lightColor[NUM_LIGHTS];

uniform vec4 _ambientLight;

#include "shaders/lib3d/material_data.glsl"

#define LIGHTING lighting_default

//Lambert diffuse lighting calculations
vec3 lighting_lambert(in surfdata data, vec3 direction, vec3 view, vec3 lightcolor, float atten)
{
	return (max(dot(normalize(data.normal), -direction)*lightcolor*atten, 0.0)*data.albedo.rgb)/3.14159265359;
}


//Blinn-Phong lighting calculations
vec3 lighting_blinnphong(in surfdata data, vec3 direction, vec3 view, vec3 lightcolor, float atten)
{
	vec3 N = normalize(data.normal);
	vec3 R = -direction - 2 * dot(-direction, N) * N;
	vec3 specular = atten * (1-data.roughness) * pow(max(dot(view, R), 0.0), 32) * lightcolor;
	return lighting_lambert(data, direction, view, lightcolor, atten) + specular;
}


//* Functions for PBR *//

//Fresnel function - Schlick approximation
vec3 _fresnelschlick(float costheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - costheta, 5.0);
}  

//Normal distribution function - Trowbridge-Reitz GGX
float _distributionGGX(vec3 N, vec3 H, float roughness)
{
    float a = roughness*roughness;
    a *= a;
    float NdotH = max(dot(N, H), 0.0);
	NdotH *= NdotH;
	
    float d = (NdotH * (a - 1.0) + 1.0);
    d *= 3.14159265359 * d;
	
    return a / d;
}

//Geometry function - Schlick-GGX
float _geometryschlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;
	
    return NdotV / (NdotV * (1.0 - k) + k);
}

//Geometry function - Smith's-GGX
float _geometrysmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    return _geometryschlickGGX(max(dot(N, V), 0.0), roughness) * _geometryschlickGGX(max(dot(N, L), 0.0), roughness);
}

//Compute lighting components for microfacet PBR
void _doPBR(surfdata data, vec3 direction, vec3 view, vec3 lightcolor, float atten, out vec3 col_diffuse, out vec3 col_specular, out vec3 col_radiance)
{
	//Adjust roughness as 0 roughness produces infinitely small highlights
	float roughness = (data.roughness + 0.075)/1.075;
	
	//Normalise normal, view dir, light dir, and half vector
	vec3 N = normalize(data.normal);
    vec3 V = -view;
    vec3 L = normalize(-direction);
	vec3 H = normalize(V + L);
	
	//Material base reflectivity approximation
    vec3 F0 = mix(vec3(0.04), data.albedo.rgb, data.metallic);
	
	//Light radiance
	vec3 radiance = lightcolor * atten;

	//Compute normal distribution, geometry, and fresnel functions
	float NDF = _distributionGGX(N, H, roughness);
    float G = _geometrysmith(N, V, L, roughness);  
    vec3 F = _fresnelschlick(max(dot(H, V), 0.0), F0);
	
	//Apply energy conservation
    vec3 kD = (vec3(1.0) - F) * (1.0 - data.metallic);
	
	//Solve reflectance equation
	vec3 numerator = NDF * G * F;
    float NdotL = max(dot(N, L), 0.0);  
    float denominator = 4.0 * max(dot(N, V), 0.0) * NdotL;
    vec3 specular = numerator / max(denominator, 0.001);
	
	col_diffuse = kD / 3.14159265359;
	col_specular = specular;
	col_radiance = radiance * NdotL;
}

//Default microfacet PBR lighting
//TODO: Image based lighting
vec3 lighting_default(in surfdata data, vec3 direction, vec3 view, vec3 lightcolor, float atten)
{
	vec3 diffuse;
	vec3 specular;
	vec3 radiance;
	_doPBR(data, direction, view, lightcolor, atten, diffuse, specular, radiance);
	
	return (diffuse*data.albedo.rgb + specular)* radiance;
}

//PBR based simple cel-shading
vec3 lighting_cel(in surfdata data, vec3 direction, vec3 view, vec3 lightcolor, float atten)
{
	vec3 diffuse;
	vec3 specular;
	vec3 radiance;
	_doPBR(data, direction, view, lightcolor, atten, diffuse, specular, radiance);
	
	float difflum = length(diffuse);
	float speclum = length(specular*radiance);
	float radlum = length(radiance);
	
	float celdiff = clamp(sign(difflum - 0.5), 0,1);
	float celspec = clamp(sign(speclum - 0.5), 0,1);
	vec3 celrad = clamp(sign(radlum - 0.5), 0,1) * lightcolor;
	
    return celdiff*data.albedo.rgb*celrad + celspec*lightcolor;
}


//Gets the current fragment's linear depth in view space
float linear_depth()
{
	return (2.0 * cam_nearclip * cam_farclip) / (cam_farclip + cam_nearclip - gl_FragCoord.z * (cam_farclip - cam_nearclip));
}

//Gets the current fragment's linear depth, normalised between 0 and 1
float normalised_linear_depth()
{
	return cam_nearclip * (gl_FragCoord.z+1)/((cam_nearclip - cam_farclip)*gl_FragCoord.z + cam_nearclip + cam_farclip);
}

//Gets a fresnel value between 0 and 1
float fresnel(float power)
{
	return pow(clamp( dot(_world_normal, view_dir) + 1.0, 0.0, 1.0), power);
}

#ifdef SHADER
	#include SHADER
#else
	#include "shaders/lib3d/default_shader.glsl"
#endif

//Calculate brightness for a single light source
vec3 _dolightcalc(in surfdata data, vec3 direction, vec3 view, vec3 lightcolor, float atten)
{
	return LIGHTING(data, direction, view, lightcolor, atten);
}

//Compute aggregate lighting
vec3 _dolighting(in surfdata data)
{
	#if !(defined UNLIT && UNLIT > 0 && !(TONEMAP > 0))
		//Conversion to linear color space
		data.albedo.rgb = pow(data.albedo.rgb, vec3(2.2));
	#endif
	vec3 c;
	#if defined UNLIT && UNLIT > 0
		c = data.albedo.rgb;
	#else
		c = vec3(0);
		for(int i = 0; i<NUM_LIGHTS; i++)
		{
			//Directional
			c += _dolightcalc(data, _dir_lightDirection[i], view_dir, _dir_lightColor[i].rgb, _dir_lightColor[i].a);
			
			//Point
			vec3 dir = _world_position-_pnt_lightPosition[i].xyz;
			float d = length(dir);
			dir = normalize(dir);
			d = min(d/_pnt_lightPosition[i].w, 1.0) + 0.88320;
			c += _dolightcalc(data, dir, view_dir, _pnt_lightColor[i].rgb, max(_pnt_lightColor[i].a*(1/(d*d) - 0.281972), 0));
		}
		
		//Apply ambient light
		c += _ambientLight.rgb * data.albedo.rgb * data.occlusion;
	#endif
	
	#if TONEMAP > 0
		//Reinhard tonemapper
		const float limit = 3.14159265359;
		c *= (vec3(1)+c/(limit*limit))/(vec3(1)+c);
	#endif
	
	#if !(defined UNLIT && UNLIT > 0 && !(TONEMAP > 0))
		//Gamma correction
		c = pow(c, vec3(1.0/2.2));  
	#endif
	return c;
}

//Perform surface shader (this is put in a separate function to ensure the fragdata cannot be edited)
void _dosurface(in fragdata v, inout surfdata s)
{
	SURFACE(v, s);
}

void main()
{
	//Clip based on clip space depth TODO: use gl_ClipVertex from vertex shader
	if (/*_clippos.x < -_clippos.w || _clippos.x > _clippos.w || _clippos.y < -_clippos.w || _clippos.y > _clippos.w || */ _clippos.z < -_clippos.w || _clippos.z > _clippos.w) 
	{
		discard;
	}
	//Compute frag depth and clip if necessary
	float depth = (1+gl_FragCoord.z)*0.5;
	
	//* SURFACE SHADER *//
	
	#if UV_MODE == UV_CLAMP
		vec2 uvs = clamp(gl_TexCoord[0].xy / _invdepth, 0, 1);
	#elif UV_MODE == UV_WRAP
		vec2 uvs = mod(gl_TexCoord[0].xy / _invdepth, 1.0);
	#else
		vec2 uvs = gl_TexCoord[0].xy / _invdepth;
	#endif
	//Generate fragment data from interpolated values
	fragdata vdata = fragdata(gl_FragCoord.xy, _world_position, _world_normal, uvs, gl_Color, depth);
	//Generate initial surface data, so that values can be left out of the surface shader
	surfdata data = surfdata(vec4(0,0,0,1), vec3(0,0,0), vdata.worldnormal, 0.0, 1.0, 1.0);
	//Run surface shader
	_dosurface(vdata, data);
	
	#if ALPHAMODE < 1 && ALPHAMODE > 0
		//Alpha cutoff
		data.albedo.a = clamp(sign(data.albedo.a - ALPHAMODE),0,1);
	#endif
	
	//Alpha blend or cutoff
	#if ALPHAMODE != ALPHA_OPAQUE
		//Discard invisible pixels
		if(data.albedo.a <= 0.039)
		{
			discard;
		}
	#endif
	
	#if DEBUG == DEBUG_NORMALS
		//Display world normal
		gl_FragColor = vec4((vdata.worldnormal+1)/2,1);
	#elif DEBUG == DEBUG_DEPTH
		//Display depth
		gl_FragColor = vec4(vec3(normalised_linear_depth()), 1);
	#elif DEBUG == DEBUG_POSITION
		//Display world position
		gl_FragColor = vec4(((vdata.worldposition/10000)+1)/2,1);
	#elif DEBUG == DEBUG_UNLIT
		//Display unlit albedo
		gl_FragColor = clamp(data.albedo,0,1);
	#elif DEBUG == DEBUG_OCCLUSION
		//Display ambient occlusion
		gl_FragColor.rgb = clamp(vec3(data.occlusion),0,1);
		gl_FragColor.a = clamp(data.albedo.a,0,1);
	#else
		//Perform lighting calculations
		gl_FragColor = vec4(_dolighting(data), clamp(data.albedo.a,0,1)) + vec4(data.emissive.rgb,0);
	#endif
	
	//No transparency on opaque materials
	#if ALPHAMODE != ALPHA_BLEND
		gl_FragColor.a = 1;
	#endif
}