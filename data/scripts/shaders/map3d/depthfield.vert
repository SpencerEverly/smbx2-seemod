#version 120
uniform float frame;
uniform mat4 w2c;
uniform mat4 proj;
uniform float fieldDistance;
uniform vec3 camPos;
uniform vec3 groundDir;

varying float depthBuffer;

void main()
{    
	gl_TexCoord[0] = gl_TextureMatrix[0] * (gl_MultiTexCoord0 + vec4(0,frame,0,0));
	
	vec4 vert = vec4(camPos + groundDir*fieldDistance, 1);
	vert = proj*w2c*vert;
	
	vert.y /= vert.w;
	
	depthBuffer = vert.y + 300;
	
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	
	gl_FrontColor = gl_Color; 
}