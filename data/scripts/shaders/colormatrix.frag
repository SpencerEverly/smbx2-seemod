#version 120
uniform sampler2D iChannel0;
uniform mat3 matrix;

void main()
{
	vec4 c = texture2D( iChannel0, gl_TexCoord[0].xy);
	
	gl_FragColor = c*gl_Color;
	gl_FragColor.rgb = matrix*gl_FragColor.rgb;
}