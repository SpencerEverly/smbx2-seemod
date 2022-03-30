#version 120
uniform vec4 cameraBounds;

void main()
{    
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
	gl_TexCoord[0].xy *= (cameraBounds.zw - cameraBounds.xy)/vec2(800,600);
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	gl_FrontColor = gl_Color;
}