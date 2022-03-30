#version 120

uniform vec2 inputSize;
varying vec2 crispTexel;
varying vec2 crispSize;
varying vec4 glyphRangeFrag;
attribute vec2 crispScale;
attribute vec4 glyphRange;

void main()
{    
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	gl_FrontColor = gl_Color;
	
	crispTexel = gl_TexCoord[0].xy * inputSize.xy;
	crispSize = crispScale;
	
	glyphRangeFrag = glyphRange;
}