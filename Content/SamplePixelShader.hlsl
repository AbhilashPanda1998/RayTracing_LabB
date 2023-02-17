static float4 Eye = float4(0, 0, 15, 1); //eye position 
static float nearPlane = 1.0;
static float farPlane = 1000.0;
 
static float4 LightColor = float4(1, 1, 1, 1);
static float3 LightPos = float3(0, 100, 0);
static float4 backgroundColor = float4(0.1, 0.2, 0.3, 1);




#define NOBJECTS 3 

struct Sphere
{
    float3 centre;
    float rad2; // radius* radius 
    float4 color;
    float Kd, Ks, Kr, shininess;
};

static float4 sphereColor_1 = float4(1, 0, 0, 1); //sphere1 color 
static float4 sphereColor_2 = float4(0, 1, 0, 1); //sphere2 color 
static float4 sphereColor_3 = float4(1, 0, 1, 1); //sphere3 color 
static float shininess = 40;
 
static Sphere object[NOBJECTS] =
{
 //sphere 1 
    { 0.0, 0.0, 0.0, 1.0, sphereColor_1, 0.3, 0.5, 0.7, shininess },
 //sphere 2    
    { 2.0, -1.0, 0.0, 0.25, sphereColor_2, 0.5, 0.7, 0.4, shininess },
 //sphere 3    
    { -2.0, -2.0, 1.0, 2, backgroundColor, 0.5, 0.3, 0.3, shininess }
};



struct PixelShaderInput
{
    float4 Position : SV_POSITION;
    float2 canvasXY : TEXCOORD0;
};
 
struct Ray
{
    float3 o; // origin 
    float3 d; // direction 
};



float SphereIntersect(Sphere s, Ray ray, out bool hit)
{
    float t;
    float3 v = s.centre - ray.o;
    float A = dot(v, ray.d);
    float B = dot(v, v) - A * A;
 
    float R = sqrt(s.rad2);
    if (B > R * R)
    {
        hit = false;
        t = farPlane;
    }
    else
    {
        float disc = sqrt(R * R - B);
        t = A - disc;
        if (t < 0.0)
        {
            hit = false;
        }
        else
            hit = true;
    }
 
    return t;
}

float3 SphereNormal(Sphere s, float3 pos)
{
    return normalize(pos - s.centre);
}

float3 NearestHit(Ray ray, out int hitobj, out bool anyhit)
{
    float mint = farPlane;
    hitobj = -1;
    anyhit = false;
    for (int i = 0; i < NOBJECTS; i++)
    {
        bool hit = false;
        float t = SphereIntersect(object[i], ray, hit);
        if (hit)
        {
            if (t < mint)
            {
                hitobj = i;
                mint = t;
                anyhit = true;
            }
        }
    }
    return ray.o + ray.d * mint;
}

float4 Phong(float3 n, float3 l, float3 v, float shininess, float4 diffuseColor, float4 specularColor)
{
    float NdotL = dot(n, l);
    float diff = saturate(NdotL);
    float3 r = reflect(l, n);
    float spec = pow(saturate(dot(v, r)), shininess) * (NdotL > 0.0);
    return diff * diffuseColor + spec * specularColor;
}

float4 Shade(float3 hitPos, float3 normal, float3 viewDir, int hitobj, float lightIntensity)
{
    float3 lightDir = normalize(LightPos - hitPos);
 
    float4 diff = object[hitobj].color * object[hitobj].Kd;
    float4 spec = object[hitobj].color * object[hitobj].Ks;
 
    return LightColor * lightIntensity * Phong(normal, lightDir,
    viewDir, object[hitobj].shininess, diff, spec);
}

float4 RayTracing(Ray ray)
{
    int hitobj;
    bool hit = false;
    float3 n;
    float4 c = (float4) 0;
    float lightInensity = 1.0;
 
 //calculate the nearest hit 
    float3 i = NearestHit(ray, hitobj, hit);
 
    for (int depth = 1; depth < 5; depth++)
    {
 
        if (hit)
        {
            n = SphereNormal(object[hitobj], i);
            c += Shade(i, n, ray.d, hitobj, lightInensity);
 
   // shoot refleced ray 
            lightInensity *= object[hitobj].Kr;
            ray.o = i;
            ray.d = reflect(ray.d, n);
            i = NearestHit(ray, hitobj, hit);
        }
        else
        {
            c += backgroundColor / depth / depth;
        }
    }
 
    return c;
}

//float4 RayCasting(Ray eyeray)
//{
 
//    bool hit = false;
//    float t = SphereIntersect(eyeray, hit);
//    float3 interP = eyeray.o + t * normalize(eyeray.d);
 
// //___________________________________   
//   //4. Render 
// //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
 
//    float4 RTColor = (float4) 0;
 
//    if (!hit) 
//        RTColor = backgroundColor;
//    else
//    {
//        float3 c = LightColor.rgb;
//        float3 N = normalize(interP);
//        N = normalize(N);
//        float3 L = normalize(LightPos - interP);
//        float3 V = normalize(Eye.xyz - interP);
//        float3 R = reflect(-L, N);
//        float r = max(0.5 * dot(N, L), 0.2);
//        r += pow(max(0.1, dot(R, V)), 50.);
//        RTColor = float4(1.5 * r * c, 1.0);
//    }
 
//    return RTColor;
//}

float4 main(PixelShaderInput input) : SV_Target
{
    
 // specify primary ray: 
    Ray eyeray;
 
    eyeray.o = Eye.xyz;
    //eyeray.d = float3(0, 0, 0);
 
// set ray direction in view space 
    float dist2Imageplane = 10.0;
    float3 viewDir = float3(input.canvasXY, -dist2Imageplane);
    viewDir = normalize(viewDir);
  
    return RayTracing(eyeray);
}

