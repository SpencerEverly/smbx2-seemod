uniform int mipLevels = 4;

vec4 fadeNormalWithDepth(vec4 n, float z)
{
	return mix(n, vec4(0.5,0.5,1,1), clamp((z-200)/1000, 0, 1));
}

float mipFromDepthSmooth(float z)
{
	return (z)/600;
}

int mipFromDepth(float z)
{
	return int(mipFromDepthSmooth(z));
}

vec2 mipSize(int mip)
{	
	return vec2(pow(2.0, -(mip+1.0)), pow(2.0, -float(mip)));
}

vec2 UVtoMip(vec2 uv, int mip)
{	
	uv.x *= 0.5;
	
	float p2 = pow(2.0, -clamp(float(mip), 0.0, float(mipLevels)-1.0));
	
	uv *= p2;
	uv.x += 1 - p2;
	
	return uv;
}

vec4 textureMip(sampler2D sampler, vec2 coords, int mip)
{
	vec2 uv = UVtoMip(coords, mip);
	
	return texture2D(sampler, uv);
}

vec4 textureMipBlend(sampler2D sampler, vec2 coords, float mip)
{
	return mix(textureMip(sampler, coords, int(floor(mip))), textureMip(sampler, coords, int(ceil(mip))), fract(mip));
}

/*
//Aniso Mipmaps

//ani -1  =>  vertical
//ani  1  =>  horizontal
vec2 UVtoAniso(vec2 uv, int mip, int ani)
{	
	uv.x *= 0.5;
	
	float p2 = pow(2.0, -clamp(float(mip), 0.0, float(mipLevels)-1.0));
	
	
	float mipped = clamp(sign(mip-0.5),0,1);
	
	//Horizontal aniso
	float h = clamp(float(ani),0,1) * mipped;
	uv.y *= mix(1, 0.5, h);
	uv.y += h;
	
	//Vertical aniso
	float v = clamp(-float(ani),0,1) * mipped;
	uv.x *= mix(1, 0.5, v);
	uv.x += 0.5*v;
	
	uv *= p2;
	uv.x += 1 - p2;
	
	uv.y += 0.5*v;
	
	return uv;
}

vec4 textureAniso(sampler2D sampler, vec2 coords, int mip, int ani)
{
	vec2 uv = UVtoAniso(coords, mip, ani);
	
	return texture2D(sampler, uv);
}

vec4 textureAnisoBlend(sampler2D sampler, vec2 coords, float mip, int ani)
{
	return mix(textureAniso(sampler, coords, int(floor(mip)), ani), textureAniso(sampler, coords, int(ceil(mip)), ani), fract(mip));
}
*/