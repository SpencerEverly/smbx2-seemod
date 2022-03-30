#version 120
uniform sampler2D iChannel0;
uniform vec2 texSize;

#define MIPLEVELS 3

#include "shaders/map3d/bicubic.glsl"

//Less than conditional
float lt(float x, float y) 
{
  return max(sign(y - x), 0.0);
}

//Greater or equal conditional
float ge(float x, float y) 
{
  return 1.0 - lt(x, y);
}

void main()
{
	vec2 uv = gl_TexCoord[0].xy;
	uv.x *= 2;
	
	//Vertical Aniso
	/*
	float v = ge(uv.x, 1.5) * ge(uv.y, 0.5);
	uv.x = mix(uv.x, (uv.x-1.5)*2 + 1,v);
	uv.y = mix(uv.y, (uv.y-0.5)*0.5 + 0.5,v);
	*/
	
	for(int i = 1; i < MIPLEVELS; i++)
	{
		uv = mix(uv, 2*uv, ge(uv.x, pow(2.0,float(i))-1.0));
		//Aniso
		//uv.y = mix(uv.y, (uv.y-1)*2, ge(uv.y,1));
	}
	
	float sam = lt(uv.x, 1);
	
	
	uv.x = mod(clamp(uv.x, 0.0, pow(2.0,float(MIPLEVELS))-1.0), 1.0);
	
	//Horizontal Aniso
	/*
	float anih = clamp(ge(uv.y, 1)*(ge(uv.x,0.5)+ge(uv.y,2))*(1-sam),0,1);
	uv.y = mix(uv.y, mix(uv.y, 0.5*uv.y, clamp(ge(uv.y, 2)+lt(uv.x,0.9), 0, 1)), anih);
	*/
	
	uv = clamp(uv, 0.0, 1.0);
	
	vec4 c = mix(textureBicubic(iChannel0, texSize, uv), texture2D(iChannel0, uv), sam);
	
	gl_FragColor = c*gl_Color;
}