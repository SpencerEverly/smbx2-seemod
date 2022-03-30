#version 120

uniform vec2 inputSize;
varying vec2 crispTexel;
uniform vec2 crispScale;

void main()
{    
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	gl_FrontColor = gl_Color;
	
	crispTexel = gl_TexCoord[0].xy * inputSize.xy;
}