#version 120
uniform sampler2D iChannel0;

const vec4 c1 = vec4(0.60784, 0.73725, 0.05882, 1);
const vec4 c2 = vec4(0.54510, 0.67451, 0.05882, 1);
const vec4 c3 = vec4(0.18824, 0.38431, 0.18824, 1);
const vec4 c4 = vec4(0.05882, 0.21961, 0.05882, 1);

const vec2 scale = vec2(400, 300);

#include "shaders/logic.glsl"

void main()
{
	//Downsample
	vec2 uv = floor(gl_TexCoord[0].xy * scale + 0.5);
	vec2 iscale = 1/scale;
	uv *= iscale;
	vec2 d = iscale*0.5;
	vec3 m = vec3(1,-1,0);
	vec4 c = texture2D(iChannel0, uv)*3;
	c += texture2D(iChannel0, uv+d*m.zx);
	c += texture2D(iChannel0, uv+d*m.xx);
	c += texture2D(iChannel0, uv+d*m.xy);
	c += texture2D(iChannel0, uv+d*m.yx);
	c += texture2D(iChannel0, uv+d*m.yy);
	
	c += texture2D(iChannel0, uv+d*m.xz);
	c += texture2D(iChannel0, uv+d*m.zz);
	c += texture2D(iChannel0, uv+d*m.zy);
	c += texture2D(iChannel0, uv+d*m.yz);
	
	c /= 12;
	
	//Quantize
	vec4 c1c2 = mix(c1,c2,gt(distance(c,c1), distance(c,c2)));
	vec4 c1c3 = mix(c1,c3,gt(distance(c,c1), distance(c,c3)));
	vec4 c1c4 = mix(c1,c4,gt(distance(c,c1), distance(c,c4)));
	
	vec4 c1c2c3 = mix(c1c2,c1c3,gt(distance(c,c1c2), distance(c,c1c3)));
	
	c = mix(c1c2c3,c1c4,gt(distance(c,c1c2c3), distance(c,c1c4)));
	
	gl_FragColor = c*gl_Color;
}