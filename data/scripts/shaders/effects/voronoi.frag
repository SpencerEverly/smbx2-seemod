#version 120
uniform sampler2D iChannel0;

uniform float stepSize;

const vec3 offset = vec3(-1,0,1);

#include "shaders/logic.glsl"
#include "shaders/effects/coordsmap.glsl"

vec3 updatePos(vec3 pos, vec2 pixel, vec2 kernel)
{
	float d = mix(pos.z, length(pixel-kernel), ge(kernel.x, 0.01));
	
	pos = mix(pos, vec3(kernel.xy, d), lt(d, pos.z));
	
	return pos;
}

void main()
{
	vec3 c = texture2D(iChannel0, gl_TexCoord[0].xy).rgb;
	
	vec2 _11 = c.gb;
	vec2 _00 = texture2D(iChannel0, gl_TexCoord[0].xy + stepSize*offset.xx).gb;
	vec2 _01 = texture2D(iChannel0, gl_TexCoord[0].xy + stepSize*offset.xy).gb;
	vec2 _02 = texture2D(iChannel0, gl_TexCoord[0].xy + stepSize*offset.xz).gb;
	vec2 _10 = texture2D(iChannel0, gl_TexCoord[0].xy + stepSize*offset.yx).gb;
	vec2 _12 = texture2D(iChannel0, gl_TexCoord[0].xy + stepSize*offset.yz).gb;
	vec2 _20 = texture2D(iChannel0, gl_TexCoord[0].xy + stepSize*offset.zx).gb;
	vec2 _21 = texture2D(iChannel0, gl_TexCoord[0].xy + stepSize*offset.zy).gb;
	vec2 _22 = texture2D(iChannel0, gl_TexCoord[0].xy + stepSize*offset.zz).gb;
	
	vec3 pos = vec3(0,0, 10);
	vec2 p = mapCoords(gl_TexCoord[0].xy);
	
	pos = updatePos(pos, p, _00);
	pos = updatePos(pos, p, _01);
	pos = updatePos(pos, p, _02);
	pos = updatePos(pos, p, _10);
	pos = updatePos(pos, p, _11);
	pos = updatePos(pos, p, _12);
	pos = updatePos(pos, p, _20);
	pos = updatePos(pos, p, _21);
	pos = updatePos(pos, p, _22);
	
	gl_FragColor.gb = pos.xy;
	gl_FragColor.r = c.r;
	gl_FragColor.a = 1;
}