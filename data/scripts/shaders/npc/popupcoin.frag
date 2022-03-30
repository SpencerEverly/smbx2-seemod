#version 120
uniform sampler2D iChannel0;
uniform vec3 iResolution;
uniform float maxh;
uniform float val;

float lt(float x, float y) 
{
  return max(sign(y - x), 0.0);
}

void main()
{
	vec2 uv = gl_TexCoord[0].xy;
    vec2 one = vec2(1,1) / iResolution.xy;
    
    vec2 oneU = vec2(0, one.y);
    vec2 oneR = vec2(one.x, 0);
    
    float ac = texture2D(iChannel0, uv).a;
    
	float dwnside = lt(1, uv.y + 2*one.y);
	float upside  = lt(uv.y - 2*one.y, 0);
	float rgtside = lt(1, uv.x + 2*one.x);
	float lftside = lt(uv.x - 2*one.x, 0);
	
    float a2d = mix(texture2D(iChannel0, uv+2.0*oneU).a, 0, dwnside);
    float a2u = mix(texture2D(iChannel0, uv-2.0*oneU).a, 0, upside);
    float a2r = mix(texture2D(iChannel0, uv+2.0*oneR).a, 0, rgtside);
    float a2l = mix(texture2D(iChannel0, uv-2.0*oneR).a, 0, lftside);
	
	//Treat all pixels off the bottom of the first frame as empty pixels.
	a2d = max(sign(maxh - (uv.y+2.0*one.y)), 0.0) * a2d;
    
    float a = ac - (a2u * a2d * a2r * a2l);
	
	float hor = step(1,mod(uv.x*iResolution.x*0.5,2.0));
	float ver = step(1,mod(uv.y*iResolution.y*0.5,2.0));
    
	float check = mix(hor, 1-hor, ver);
	
	
	float v = check;
	
	v = a*mix(v, 1-v, val);
    
	gl_FragColor = vec4(v,v,v,a);
}