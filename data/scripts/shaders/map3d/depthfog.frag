#version 120
uniform sampler2D iChannel0;
uniform sampler2D normalMap;
uniform sampler2D emissiveMap;
uniform float farclip;
uniform float farFade = 1;
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
uniform float zoffset;

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

//Greater or equal conditional
float ge(float x, float y) 
{
  return 1.0 - lt(x, y);
}

void main()
{
	//Adjust texture coords
	float z = 1/depthBuffer;
	
	//Sample texture
	vec2 uv = clamp(gl_TexCoord[0].xy * z, 0, 1);
	
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

	z += zoffset;
	//Apply depth fade
	gl_FragColor.a = c.a;
	gl_FragColor *= clamp((farclip-z)*farFade,0,1);
	
	//Apply depth clip
	gl_FragColor *= mix(1, 0, lt(z, 32) + ge(z, farclip));
	
	//Write depth
	gl_FragDepth = mix(1, ((z-32)/(farclip-32)), ge(c.a, 0.01));
	
#ifdef DEBUG_DEPTH
	//Preview depth
	gl_FragColor.rgb = mix(gl_FragColor.rgb, vec3((z-32)/(farclip-32))*gl_FragColor.a, DEBUG_DEPTH);
#endif
#ifdef DEBUG_NORMALS	
	//Preview normals
	gl_FragColor.rgb = mix(gl_FragColor.rgb, (nrm*2)-1, DEBUG_NORMALS);
#endif	
#ifdef DEBUG_MIP
	//Preview mip level
	gl_FragColor.rgb = mix(gl_FragColor.rgb, mix(vec3(1,0,0), vec3(0,1,0), clamp(float(mipFromDepthSmooth(z))/mipLevels,0,1)), DEBUG_MIP);
#endif
}