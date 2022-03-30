#version 120

#include "shaders/effects/coordsmap.glsl"

uniform sampler2D iChannel0;
const vec2 screensize = vec2(800,600);

void main()
{
	float a = texture2D(iChannel0, gl_TexCoord[0].xy).a;
	
	//gl_FragColor.gb = mix(vec2(0,0), mapCoords(gl_FragCoord.xy/screensize), a);
	//gl_FragColor.r = a;
	
	gl_FragColor.rgb = gl_Color.rgb*a;
	gl_FragColor.a = 0;
}