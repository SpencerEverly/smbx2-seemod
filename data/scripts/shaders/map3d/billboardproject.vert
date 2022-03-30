#version 120
attribute float zCoords;
attribute float xCoords;

uniform vec2 pos;
uniform float frame;
uniform float frameHeight;
uniform mat4 w2c;
uniform mat4 proj;
uniform mat3 rot;
uniform vec3 view;

uniform vec3 lightDir;

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

//Sample the heightmap to generate a y coordinate
float sampleHM(vec2 pos)
{
	vec2 uv = (pos.xy-heightmapPosition.xy)/(32.0*heightmapSize);
	
	return textureBicubic(heightmap, heightmapSize, uv).r;
}

#define EPSILON 0.00000004

void main()
{    
	//Rotate vertices around the centre point
	vec3 rotvert = vec3(gl_Vertex.x - pos.x, zCoords - gl_Vertex.y, 0);
	rotvert = rot*rotvert;
	
	//Generate the base vertex positions based on rotated offset, centrepoint, and heightmap
	float y = (sampleHM(vec2(xCoords,zCoords)))*heightmapScale + yoffset;
	vec4 vert = vec4(rotvert,1) + vec4(pos.x, y, zCoords, 0);
	
	//Generate normals and tangents from camera direction (normal is slightly rotated to counter the fact that billboards are flat and therefore unlit from most angles)
	normal.rgb = mix(-vec3(rot[0][2],rot[1][2],rot[2][2]), lightDir, 0.4);
	tangent = vec3(rot[0][0],rot[1][0],rot[2][0]);
	bitangent = -vec3(rot[0][1],rot[1][1],rot[2][1]);
	
	//Project into camera space
	vert = w2c*vert;
	vert.z = max(vert.z, 0);
	
	//Project into clip space
	vert = proj*vert;
	vert.xy /= vec2(vert.w);
	
	//Adjust positions for screen size
	vert.x += 400;
	vert.y += 300;
	
	//Get depth of centre point
	float dv = (w2c*vec4(pos.x, y, zCoords, 1)).z;
	
	//Store 1/depth to allow for reconstructing UVs
	depthBuffer = 1/dv;
	
	//Adjust UVs and store them /depth (allows for more accurate textures)
    gl_TexCoord[0] = clamp(gl_TextureMatrix[0] * (clamp(gl_MultiTexCoord0 + vec4(0,frame,0,0), vec4(0,frame+EPSILON,0,0), vec4(1,frame+frameHeight-EPSILON,1,1)))/dv, 0, 1);
	
	//Reset unused values
	vert.z = 0.0;
	vert.w = 1.0;
	
	//Set vertex position
    gl_Position = gl_ModelViewProjectionMatrix * vert;
	
	//Set vertex colour
	gl_FrontColor = gl_Color;
}