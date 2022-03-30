#version 120
uniform sampler2D iChannel0;
uniform float time;
uniform float intensity;
uniform vec4 sectionBounds;
uniform vec4 cameraBounds;
uniform sampler2D mask;
uniform sampler2D tex1;

void main()
{	
	vec2 uv = gl_TexCoord[0].xy;
	vec4 c = texture2D(iChannel0, uv);
	vec4 m = texture2D(mask, uv);
	
	float msk = clamp(m.r+m.g+m.b,0,1);
	float bg = 1-clamp(m.r+m.g,0,1);
	
	vec2 camcoord = mod(gl_TexCoord[0].xy + (cameraBounds.xy/vec2(800,600)), vec2(1));
	vec2 uv2 = mod(camcoord + (time + bg*64)*vec2(0.0006, 0.0008), vec2(1));
	vec2 uv3 = mod(camcoord + (time + bg*64)*vec2(-0.0007, 0.00035), vec2(1));
	
	float fader = sin(time*0.009);
	fader *= fader;
	
	float cs = texture2D(tex1, uv2).r * mix(0.25,1,fader) + texture2D(tex1, uv3).r * mix(0.25,1,1-fader);
	gl_FragColor = c*gl_Color + (cs*msk*0.5*vec4(0.8, 0.95, 1, 1));
}