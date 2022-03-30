#version 120
uniform sampler2D iChannel0;

const vec4 c1 = vec4(0.60784, 0.73725, 0.05882, 1);
const vec4 c2 = vec4(0.54510, 0.67451, 0.05882, 1);
const vec4 c3 = vec4(0.18824, 0.38431, 0.18824, 1);
const vec4 c4 = vec4(0.05882, 0.21961, 0.05882, 1);

const vec2 scale = vec2(400, 300);

#include "shaders/logic.glsl"


const mat4x4 indexMat = mat4x4(	 0 / 16.0, 	 8 / 16.0,   2 / 16.0,  10 / 16.0,
								12 / 16.0, 	 4 / 16.0,  14 / 16.0, 	 6 / 16.0,
								 3 / 16.0, 	11 / 16.0, 	 1 / 16.0, 	 9 / 16.0,
								15 / 16.0, 	 7 / 16.0,  13 / 16.0, 	 5 / 16.0);

float getIndex(vec2 uv) 
{
    int x = int(mod(uv.x, 4));
    int y = int(mod(uv.y, 4));
    return indexMat[y][x];
}

vec4 dither(vec2 uv, vec4 color, vec4 closest, vec4 secondclosest) 
{
    float d = getIndex(uv);
    float dist = distance(closest, color);
    return mix(secondclosest, closest, or(lt(dist, d), and(gt(distance(color,secondclosest), 0.85), lt(dist, 0.6))));
}

void main()
{
	//Downsample
	vec2 iscale = 1/scale;
	
	/*// Uncomment for rounded dither (more blocky)
	vec2 uv = floor(gl_TexCoord[0].xy * scale + 0.5);
	vec2 uv2 = uv*iscale;
	//*/
	
	//*// Uncomment for unrounded dither
	vec2 uv = gl_TexCoord[0].xy * scale;
	vec2 uv2 = floor(uv + 0.5)*iscale;
	//*/
	
	vec2 d = iscale*0.5;
	vec3 m = vec3(1,-1,0);
	vec4 c = texture2D(iChannel0, uv2)*3;
	c += texture2D(iChannel0, uv2+d*m.zx);
	c += texture2D(iChannel0, uv2+d*m.xx);
	c += texture2D(iChannel0, uv2+d*m.xy);
	c += texture2D(iChannel0, uv2+d*m.yx);
	c += texture2D(iChannel0, uv2+d*m.yy);
	
	c += texture2D(iChannel0, uv2+d*m.xz);
	c += texture2D(iChannel0, uv2+d*m.zz);
	c += texture2D(iChannel0, uv2+d*m.zy);
	c += texture2D(iChannel0, uv2+d*m.yz);
	
	c /= 12;
	
	//Quantize
	vec4 c1c2 = mix(c1,c2,gt(distance(c,c1), distance(c,c2)));
	vec4 c1c3 = mix(c1,c3,gt(distance(c,c1), distance(c,c3)));
	vec4 c1c4 = mix(c1,c4,gt(distance(c,c1), distance(c,c4)));
	
	vec4 c1c2c3 = mix(c1c2,c1c3,gt(distance(c,c1c2), distance(c,c1c3)));
	
	vec4 closest = mix(c1c2c3,c1c4,gt(distance(c,c1c2c3), distance(c,c1c4)));
	
	
	c1c2 = mix(c1,c2,lt(distance(c,c1), distance(c,c2)));
	c1c3 = mix(c1,c3,lt(distance(c,c1), distance(c,c3)));
	c1c4 = mix(c1,c4,lt(distance(c,c1), distance(c,c4)));
	
	c1c2c3 = mix(c1c2,c1c3,gt(distance(c,c1c2), distance(c,c1c3)));
	
	vec4 secondclosest = mix(c1c2c3,c1c4,gt(distance(c,c1c2c3), distance(c,c1c4)));
	
	
	gl_FragColor = dither(uv, c, closest, secondclosest)*gl_Color;
}