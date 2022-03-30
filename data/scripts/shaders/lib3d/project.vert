#version 120
uniform mat4 mat_mvp;
uniform mat4 mat_p;
uniform mat4 obj2world;
uniform mat4 world2obj;
uniform float cam_nearclip;
uniform float cam_farclip;
uniform vec3 cam_position;

attribute vec3 _vertexdata;
attribute vec3 _normaldata;
attribute vec3 _tangentdata;

varying float _invdepth;
varying vec3 _world_normal;
varying vec3 _world_position;
varying vec4 _clippos;
varying vec3 view_dir;

varying mat3 tgt2world;

#include "shaders/lib3d/material_data.glsl"

#define VERTEX default_vert

//Default vertex shader is a nop
void default_vert(inout vertdata data){}

//Declare built-in functions for the fragment shader
float linear_depth(){ return 0.0; }
float normalised_linear_depth(){ return 0.0; }
float fresnel(float power){ return 0.0; }

//Declare built-in lighting functions
vec3 lighting_default(in surfdata data, vec3 direction, vec3 view, vec3 lightcolor, float atten){ return vec3(0); }
vec3 lighting_lambert(in surfdata data, vec3 direction, vec3 view, vec3 lightcolor, float atten){ return vec3(0); }
vec3 lighting_blinnphong(in surfdata data, vec3 direction, vec3 view, vec3 lightcolor, float atten){ return vec3(0); }
vec3 lighting_cel(in surfdata data, vec3 direction, vec3 view, vec3 lightcolor, float atten){ return vec3(0); }

#ifdef SHADER
	#include SHADER
#endif

void main()
{   
	//Generate vertex data from attributes
	vertdata data = vertdata(_vertexdata, _normaldata, gl_MultiTexCoord0, gl_Color);
	//Run vertex shader
	VERTEX(data);

	//Project into clip space
	vec4 v = mat_mvp * vec4(data.position,1);
	
	//Set up the clipping plane to remove vertices outside the clipping space (store negative because of inverted coordinate spaces, but keep positive for ortho projection)
	//gl_ClipVertex = v;
	_clippos = mix(-v,v,mat_p[3][3]);
	
	//Store 1/depth to allow for reconstructing UVs
	_invdepth = 1/v.w;
	
	//Interpolate texture over inverse depth
    gl_TexCoord[0] = gl_TextureMatrix[0] * (data.uv * _invdepth);
	
	//Homogeneous normalisation
	v /= v.wwww;
	
	//Set vertex position
    gl_Position = v;
	
	//Set vertex colour
	gl_FrontColor = data.color;
	 
	 //Compute world space position
	_world_position = vec3(obj2world * vec4(data.position,1));
	//Compute world space normal
	_world_normal = normalize(vec3(obj2world * vec4(data.normal,0)));
	//Compute world space tangent
	vec3 tangent = normalize(vec3(obj2world * vec4(_tangentdata, 0)));
	tangent = normalize(tangent - dot(tangent, _world_normal) * _world_normal);
	//Compute world space bitangent
	vec3 bitangent = cross(_world_normal, tangent);
	//Compute tangent to world matrix
	tgt2world = mat3(tangent,bitangent,_world_normal);
	//Compute view direction
	view_dir = normalize(_world_position-cam_position);
}