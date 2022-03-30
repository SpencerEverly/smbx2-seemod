//Sets up position, texture coordinates, and tint colour for each vertex.
//This is regular glDraw behaviour and is the same as using no shader.

#version 120

//Do your per-vertex shader logic here.
void main()
{    
	gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
	gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	gl_FrontColor = gl_Color;
}