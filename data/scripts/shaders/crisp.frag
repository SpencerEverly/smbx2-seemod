#version 120
uniform sampler2D iChannel0;
uniform vec2 inputSize;
varying vec2 crispTexel;
uniform vec2 crispScale;

void main()
{
	vec2 texel = crispTexel;
	vec2 scale = crispScale;
	vec2 texelFloor = floor(texel);
	vec2 texelFrac = fract(texel);
	vec2 range = 0.5 - 0.5 / scale;
	vec2 centerDist = texelFrac - 0.5;
	vec2 newFrac = (centerDist - clamp(centerDist, -range, range)) * scale + 0.5;
	vec2 newTexel = texelFloor + newFrac;

	vec4 c = texture2D(iChannel0, newTexel / inputSize);
	
	gl_FragColor = c*gl_Color;
}