#version 120
uniform sampler2D iChannel0;

#include "shaders/effects/coordsmap.glsl"

const vec2 screensize = vec2(800,600);

void main()
{
	vec3 c = texture2D(iChannel0, gl_TexCoord[0].xy).gbr;
	vec2 t = c.xy * screensize;
	
	vec2 p = mapCoords(gl_TexCoord[0].xy) * screensize;
	
	gl_FragColor.r = c.b;
	gl_FragColor.g = 0;
	gl_FragColor.b = length(t-p)/800;
	gl_FragColor.a = 1;
}