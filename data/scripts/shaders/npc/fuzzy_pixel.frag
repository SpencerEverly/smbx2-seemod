#version 120
uniform sampler2D iChannel0;
uniform float time;
uniform vec2 pxSize;

void main()
{
	vec2 xy = gl_TexCoord[0].xy;
	xy = floor(xy*pxSize)/pxSize;
	xy = clamp(xy,0.001,1.0);
	vec4 c = texture2D(iChannel0, xy);
	gl_FragColor = c;
}