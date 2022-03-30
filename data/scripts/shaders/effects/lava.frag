#version 120
uniform sampler2D iChannel0;
uniform float time;
uniform vec4 sectionBounds;
uniform vec4 cameraBounds;
uniform sampler2D noise;

void main()
{	
	float y = cameraBounds.y + gl_TexCoord[0].y * (cameraBounds.w - cameraBounds.y);
	float d = sectionBounds.w - y;
	float t = d/(64 + 2 * (sin(time * 0.1)+cos(time * 0.07)));
	
	vec2 uv = vec2(clamp(gl_TexCoord[0].x + (1 - clamp(t/3, 0, 1)) * 0.0009 * sin(t*8 + time * 0.1),0,0.999), gl_TexCoord[0].y);
	vec4 c = texture2D(iChannel0, uv);
	
	float flash = sin(time * 0.06);
	vec4 r = vec4(1,(flash*flash) * 0.15,0,1);
	
	vec2 camcoord = mod(gl_TexCoord[0].xy + (cameraBounds.xy/vec2(800,600)), vec2(1));
	vec2 puv = camcoord + vec2(0.007 * sin(time * 0.0456), time*0.0005);
	vec2 puv2 = camcoord + vec2(0.0043 * cos(time * 0.0385), -time*0.00015);
	puv.x = mod(puv.x, 1.0);
	puv.y = mod(puv.y, 1.0);
	puv2.x = mod(puv2.x, 1.0);
	puv2.y = mod(puv2.y, 1.0);
	float n = texture2D(noise, puv).r + texture2D(noise, puv2).r;
	
	n = clamp(smoothstep(0, 0.4, n), 0, 1);
	n = clamp((1-n)*(1-t/1.25), 0,1);
	
	flash = cos(time * 0.073);
	vec4 r2 = vec4(1,(flash*flash) * 0.35,0 , 1);
	
	t = 1 - clamp(t, 0, 1);
	
	gl_FragColor = mix(c*gl_Color, r*0.5, t*0.5) + r * t * 0.25;
	gl_FragColor = mix(gl_FragColor, r2, n*0.5) + r2 * n * 0.25;
}