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

//Greater than conditional
float gt(float x, float y)
{
	return max(sign(x - y), 0.0);
}

//Less or equal conditional
float le(float x, float y) 
{
  return 1.0 - gt(x, y);
}

//Condition conjunction
float and(float a, float b)
{
	return a*b;
}

//Condition disjunction
float or(float a, float b)
{
	return min(a + b, 1.0);
}

//Condition negation
float nt(float a)
{
	return 1.0 - a;
}

//Equality
float eq(float a, float b)
{
	return and(ge(a,b), le(a,b));
}

//Not equal
float neq(float a, float b)
{
	return nt(eq(a,b));
}

//Condition exclusive disjunction
float xor(float a, float b)
{
	return 1.0 - abs(a + b - 1);
}