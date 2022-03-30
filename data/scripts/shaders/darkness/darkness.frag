#version 120

uniform sampler2D iChannel0;
uniform vec2 cameraPos;

#if _MAXLIGHTS > 0
//  PosX		ColR		SpotDirX
//	PosY		ColG		SpotDirY
//	Radius		ColB		SpotAngle
//	ExtraData	Brightness	LightType
uniform mat3x4 [_MAXLIGHTS] lightData;
#endif

//Uses of ExtraData:
//Spot Lights - Spot Power


uniform sampler2D mask;
uniform vec4 ambient;

uniform vec4 bounds;
uniform float useBounds = 0;
uniform float boundBlend = 64;

#include FALLOFF
#include SHADOWS

void main()
{
	vec4 c = texture2D( iChannel0, gl_TexCoord[0].xy);
	vec3 light = vec3(0);
	vec3 addlight = vec3(0);
	vec2 pos = gl_FragCoord.xy + cameraPos;
	
	light.rgb = vec3(mix(0, clamp(smoothstep(bounds.x+boundBlend, bounds.x, pos.x) + smoothstep(bounds.z-boundBlend, bounds.z, pos.x) + smoothstep(bounds.y+boundBlend, bounds.y, pos.y) + smoothstep(bounds.w-boundBlend, bounds.w, pos.y),0,1), useBounds));
		
	#if _MAXLIGHTS > 0
		for (int i = 0; i < _MAXLIGHTS; i++)
		{
			float d = abs(length(pos - lightData[i][0].xy));
			d = mix(d, mix(d, lightData[i][0].z, clamp(pow(1.0-max(((dot(lightData[i][2].xy, normalize(pos - lightData[i][0].xy))+1) * 0.5) - 1 + lightData[i][2].z, 0.0)/lightData[i][2].z, lightData[i][0].w) - pow(max(lightData[i][2].z-1.0, 0.0), lightData[i][0].w*2.0), 0.0, 1.0)), lightData[i][2].w);
			if(d < lightData[i][0].z)
			{
				light.rgb += shadow(falloff(lightData[i][1], d, lightData[i][0].z), lightData[i][0].xy, pos);
			}
		}
		
	#if ADDITIVE_BRIGHTNESS == 1
		addlight.rgb = max(light.rgb - 1.0, 0.0);
		vec3 bloomlight = max(addlight.rgb - 1.0, 0.0);
		bloomlight.rgb = vec3((bloomlight.r + bloomlight.g + bloomlight.b)/3.0);
		addlight.rgb = min(addlight, 1.0) + bloomlight;
		addlight.rgb *= mix(1.0, 1.0 - clamp(smoothstep(bounds.x+boundBlend, bounds.x, pos.x) + smoothstep(bounds.z-boundBlend, bounds.z, pos.x) + smoothstep(bounds.y+boundBlend, bounds.y, pos.y) + smoothstep(bounds.w-boundBlend, bounds.w, pos.y),0,1), useBounds);
	#endif
	
	#endif
		
	light.rgb = clamp(light.rgb,0,1);
	
	gl_FragColor = (c*clamp(vec4(light,1)+ambient,0,1) + vec4(addlight/2.5,0))*gl_Color;
}