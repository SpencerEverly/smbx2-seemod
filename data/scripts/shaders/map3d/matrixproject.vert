#version 120
uniform float frame;
uniform mat4 w2c;
uniform mat4 proj;
uniform vec3 view;

uniform sampler2D heightmap;
uniform vec2 heightmapPosition;
uniform vec2 heightmapSize;
uniform float heightmapScale;
uniform float farclip;
uniform float yoffset;

varying float depthBuffer;
varying vec3 normal;
varying vec3 tangent;
varying vec3 bitangent;

#include "shaders/map3d/bicubic.glsl"

//Less than conditional
float lt(float x, float y) 
{
  return max(sign(y - x), 0.0);
}

//Greater than conditional
float gt(float x, float y) 
{
  return max(sign(x - y), 0.0);
}

//Sample a texture to generate a normal and height value
vec4 textureNormal(sampler2D sampler, vec2 texSize, vec2 texCoords)
{
	const vec3 off = vec3(-1,0,1);
	const vec2 size = vec2(2.0,0.0);
	
    vec4 h = textureBicubic(sampler, texSize, texCoords);
    float s11 = h.r;   
	float s01 = textureBicubic(sampler, texSize, texCoords + off.xy/texSize).r;
    float s21 = textureBicubic(sampler, texSize, texCoords + off.zy/texSize).r;
    float s10 = textureBicubic(sampler, texSize, texCoords + off.yx/texSize).r;
    float s12 = textureBicubic(sampler, texSize, texCoords + off.yz/texSize).r;
	
	//Minimum height value to be considered non-zero (avoids lighting bugs at heightmap edge)
	const float ep = 0.015723032;
	s11 = mix(s11, 0, lt(s11, ep));
	s01 = mix(s01, 0, lt(s01, ep));
	s21 = mix(s21, 0, lt(s21, ep));
	s10 = mix(s10, 0, lt(s10, ep));
	s12 = mix(s12, 0, lt(s12, ep));
	
	
    vec3 va = normalize(vec3(size.xy,s21-s01));
    vec3 vb = normalize(vec3(size.yx,s12-s10));
	
	vec2 px = (1-(1/texSize));
	
	return vec4(cross(va,vb), s11);
}

//Sample the heightmap to generate a set of normals and a y coordinate
vec4 sampleNormal(vec2 pos)
{
	vec2 uv = clamp((pos.xy-heightmapPosition.xy)/(32.0*heightmapSize),0,1);
	vec4 r = textureNormal(heightmap, heightmapSize, uv);
	r.xy *= heightmapScale/32;
	r.xyz = normalize(r.xyz);
	
	return r;
}

void main()
{   
	//Generate normals and height value
	vec4 n = sampleNormal(gl_Vertex.xy);
	normal = n.rbg;
	
	//Generate tangents based on UVs for applying normal maps (note these hardcoded vectors do not work if surfaces are fully vertical)
	tangent = normalize(cross(normal, vec3(0,0,1)));
	bitangent = normalize(cross(normal, vec3(-1,0,0)));
	
	//Generate the base vertex positions based on vertex coordinates and heightmap
	vec4 vert = vec4(gl_Vertex.x, n.a*heightmapScale+yoffset, gl_Vertex.y, 1.0);
	
	//Project into camera space
	vert = w2c*vert;
	vert.z = max(vert.z, 0);
	
	//Project into clip space
	vert = proj*vert;
	vert.xy /= vec2(vert.w);
	
	//Adjust positions for screen size
	vert.x += 400;
	vert.y += 300;
	
	//Store 1/depth to allow for reconstructing UVs
	depthBuffer = 1/(vert.z);
	
	//Adjust UVs and store them /depth (allows for more accurate textures)
    gl_TexCoord[0] = gl_TextureMatrix[0] * ((gl_MultiTexCoord0 + vec4(0,frame,0,0))*depthBuffer);
	
	//Reset unused values
	vert.z = 0.0;
	vert.w = 1.0;
	
	//Set vertex position
    gl_Position = gl_ModelViewProjectionMatrix * vert;
	
	//Set vertex colour
	gl_FrontColor = gl_Color;
}