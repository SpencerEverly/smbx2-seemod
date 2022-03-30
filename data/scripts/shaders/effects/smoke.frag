#version 120
uniform sampler2D iChannel0;
uniform float time;
uniform vec4 sectionBounds;
uniform vec4 cameraBounds;
uniform sampler2D perlin;
uniform vec4 color;
uniform vec2 size;

void main()
{	
	float y = cameraBounds.y + gl_TexCoord[0].y * (cameraBounds.w - cameraBounds.y);
	float d = sectionBounds.w - y;
	float t = d/size.y;
	
	vec2 uv = gl_TexCoord[0].xy;
	vec4 c = texture2D(iChannel0, uv);
	
	
	vec2 camcoord = mod(gl_TexCoord[0].xy + ((cameraBounds.xy * vec2(size.x,1))/vec2(800,600)), vec2(1));
	vec2 puv = camcoord + vec2(time*0.003, time*0.002);
	vec2 puv2 = camcoord + vec2(-time*0.002, time*0.001);
	puv.x = mod(puv.x, 1.0);
	puv.y = mod(puv.y, 1.0);
	puv2.x = mod(puv2.x, 1.0);
	puv2.y = mod(puv2.y, 1.0);
	float n = texture2D(perlin, puv).r + texture2D(perlin, puv2).r;
	
	n *= (1-t);
	
	gl_FragColor = mix(c*gl_Color, color*0.6, clamp(n, 0 ,1));
}