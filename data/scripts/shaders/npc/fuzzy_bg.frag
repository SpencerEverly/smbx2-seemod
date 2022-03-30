#version 120
uniform sampler2D iChannel0;
uniform float time;
uniform float intensity;

void main()
{
	vec2 xy = gl_TexCoord[0].xy;
	xy.x += intensity*sin(1.38*time + xy.y * 2.0 * 3.14159)/10.0;
	vec4 c = texture2D(iChannel0, xy);
	gl_FragColor = c;
}