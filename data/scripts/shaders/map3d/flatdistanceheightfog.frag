#version 120

uniform vec3 view;
uniform float rectana;
uniform vec3 lightDir;
uniform vec4 lightCol = vec4(1,1,1,1);

varying float depthBuffer;

#include "shaders/map3d/fog.glsl"

void main()
{
	vec4 c = vec4(gl_Color.rgb, 1);
	
	gl_FragColor.rgb = applySkyboxFog(c, (depthBuffer-gl_FragCoord.y)/300) + computeSundisk(lightDir, view, 800*rectana, gl_FragCoord.xy-vec2(400,300));
	
	gl_FragColor.a = c.a;
	
	gl_FragDepth = 1;
}