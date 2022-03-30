#version 120
uniform sampler2D iChannel0;
uniform vec2 inputSize;
varying vec2 crispTexel;
varying vec2 crispSize;
varying vec4 glyphRangeFrag;

void main()
{
	vec2 texel = crispTexel;
	vec2 scale = crispSize;
	vec2 texelFloor = floor(texel);
	vec2 texelFrac = fract(texel);
	vec2 range = 0.5 - 0.5 / scale;
	vec2 centerDist = texelFrac - 0.5;
	vec2 newFrac = (centerDist - clamp(centerDist, -range, range)) * scale + 0.5;
	vec2 newTexel = texelFloor + newFrac;
	
	// Clip texel and find out how much we're clipping by in each axis
	vec2 clippedTexel = clamp(newTexel, glyphRangeFrag.xy, glyphRangeFrag.zw);
	vec2 clipAmount = 1.0 - 2.0*abs(newTexel - clippedTexel);
	
	// Sample the texture
	vec4 col = texture2D(iChannel0, clippedTexel / inputSize);
	
	// Fade edges based on clipping amount, as if we'd been sampling into a transparent border
	vec4 colClipMixed = mix(vec4(0.0, 0.0, 0.0, 0.0), col, clipAmount.x * clipAmount.y);
	
	gl_FragColor = colClipMixed*gl_Color;
}