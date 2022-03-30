#version 120
uniform sampler2D iChannel0;
uniform float time;
uniform float cameraX;
uniform float intensity;

void main()
{
	vec2 xy = gl_TexCoord[0].xy;
	xy.y += intensity*sin((cameraX + xy.x) * 2.0 * 3.14159 + time)/15.0;
	vec4 c = texture2D(iChannel0, xy);
	if (xy.y < 0 || xy.y > 1) c.rgb = vec3(0.0);
	c.r += 0.15*intensity*sin(time);
	c.g += 0.15*intensity*sin(time + 2.0 * 3.14159 / 3.0);
	c.b += 0.15*intensity*sin(time + 4.0 * 3.14159 / 3.0);
	gl_FragColor = c;
}