#version 120
uniform sampler2D iChannel0;
uniform sampler2D normalMap;
uniform sampler2D emissiveMap;
uniform float frameNum;
uniform float frameHeight;
uniform vec3 lightDir;
uniform vec4 lightCol = vec4(1,1,1,1);
uniform vec4 ambient = vec4(0.1,0.1,0.1,1);
uniform vec3 view;
uniform float rectana;

uniform float useLighting = 1;

varying float depthBuffer;
varying vec3 normal;
varying vec3 tangent;
varying vec3 bitangent;

#define LIGHTING "shaders/map3d/light_lambert.glsl"
#include LIGHTING

#include "shaders/map3d/mipsampler.glsl"
#include "shaders/map3d/fog.glsl"

uniform float useMip = 1;

//Less than conditional
float lt(float x, float y) 
{
  return max(sign(y - x), 0.0);
}

//Texture heights (to allow tiling)
vec2 heights = vec2(1,frameHeight);

void main()
{
	//Adjust texture coords
	float z = 1/depthBuffer;
	
	//Sample texture
	vec2 uv = clamp(mod(gl_TexCoord[0].xy * z * heights, heights) + vec2(0,frameNum), 0, 1);
	
	float mipdepth = mipFromDepthSmooth(z);
	
	vec4 c = mix(texture2D(iChannel0,  uv), textureMipBlend(iChannel0, uv, mipdepth), useMip) * gl_Color;
	vec4 em = mix(texture2D(emissiveMap,  uv), textureMipBlend(emissiveMap, uv, mipdepth), useMip) * gl_Color;
	vec4 n = fadeNormalWithDepth(texture2D( normalMap,  uv ), z);
	
	//Apply normal map
	n.xy = (n.xy*2)-1;
	vec3 nrm = normalize(n.z * normal + n.x*tangent + n.y*bitangent);
	
	//Apply lighting
	c.rgb = mix(c.rgb, light(nrm, c, view, lightDir, lightCol, ambient.rgb), useLighting) + (em.rgb);
	
	//Apply fog
	gl_FragColor.rgb = applyFogWithSun(c, z, lightDir, view, 800*rectana, gl_FragCoord.xy-vec2(400,300));
	
	//Apply tile alpha
	gl_FragColor.a = c.a;
	
	gl_FragDepth = 1;
	
	//Apply near clip
	gl_FragColor *= lt(32,z);
}