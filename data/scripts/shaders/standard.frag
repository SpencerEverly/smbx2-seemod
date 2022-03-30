#version 120
uniform sampler2D iChannel0;

void main()
{
	vec4 c = texture2D(iChannel0, gl_TexCoord[0].xy);
	
	gl_FragColor = c*gl_Color;
}