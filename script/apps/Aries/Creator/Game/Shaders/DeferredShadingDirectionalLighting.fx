// Directional light

float ViewAspect;
float TanHalfFOV;
float2 screenParam;
float2 viewportOffset;
float2 viewportScale;

float4x4 matWorld;
float4x4 matView;
float4x4 matProj;

float4 light_diffuse;
float4 light_specular;
float4 light_ambient;

float3 light_position;
float3 light_direction;

float light_range;
float light_falloff;

float light_attenuation0;
float light_attenuation1;
float light_attenuation2;

float light_theta;
float light_phi;


texture sourceTexture0;
sampler diffuseSampler : register(s0) = sampler_state
{
    Texture = <sourceTexture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = clamp;
    AddressV = clamp;
};

// TODO: specular texture surface 1

texture sourceTexture2;
sampler depthSampler : register(s2) = sampler_state
{
    Texture = <sourceTexture2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = clamp;
    AddressV = clamp;
};

texture sourceTexture3;
sampler normalSampler : register(s3) = sampler_state
{
    Texture = <sourceTexture3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = clamp;
    AddressV = clamp;
};


struct VSInput
{
    float3 pos : POSITION;
    float2 texCoord : TEXCOORD0;
};

struct VSOut
{
    float4 pos : POSITION;
    float2 texCoord : TEXCOORD0;
    float3 cameraEye : TEXCOORD1;
};

struct PSOut
{
    float4 color : COLOR0;
};

VSOut MainVS(VSInput input)
{
    VSOut output;

    output.pos = float4(input.pos, 1);
    output.texCoord = input.texCoord;
    output.cameraEye = float3(input.pos.x * TanHalfFOV * ViewAspect, input.pos.y * TanHalfFOV, 1);

    return output;
}

float dist_factor(float3 object_pos)
{
    float4 light_pos = mul(float4(light_position, 1), matView);
    float dist = distance(object_pos, light_pos.xyz / light_pos.w);

    float dist_att;
    if (dist > light_range)
    {
        dist_att = 0;
    }
    else
    {
        dist_att = 1 / (light_attenuation0 + light_attenuation1 * dist + light_attenuation2 * dist * dist);
    }

    return dist_att;
}

/*
 * diffuse: object material diffuse color
 * normal: object normal vector in camera space
 * position: object position in camera space
 */
float3 lighting(float4 diffuse, float3 normal, float3 position)
{
    float3 I_diff, I_spec, I_total;
    float3 l, v, n, h;
    float att;

    n = normalize(normal);
    v = normalize(-position);

    // FIXME: two test value
    float m_shi = 1;
    float4 m_spec = float4(1, 1, 1, 1);

    att = 1;

    // tranform light direction from wolrd space to camera space
    float4 light_dir = mul(float4(light_direction, 0), matView);
    l = normalize(-light_dir.xyz);

    I_diff = saturate(dot(l, n)) * (diffuse.xyz * light_diffuse.xyz);

    h = normalize(l + v);

    I_spec = saturate(dot(l, n)) * pow(saturate(dot(h, n)), m_shi) * (m_spec.xyz * light_specular.xyz);

    I_total = att * (I_diff + I_spec);
    return I_total;
}

PSOut MainPS(VSOut input)
{
    PSOut output;

    float2 texCoord = input.texCoord;
    float4 color = tex2D(diffuseSampler, texCoord);
    float alpha = color.a;
	
    // if the normal is world space normal value
    float4 norm = tex2D(normalSampler, texCoord);
    float4 normal_in_camera = mul(float4(norm.rgb * 2.0 - 1.0, 0), matView);
    float3 normal = normalize(normal_in_camera.xyz);

	// screen space depth value. 
    float depth = tex2D(depthSampler, texCoord).x;

    // position in camera space
    float4 position = float4(input.cameraEye * depth, 1);

    float3 total_color = color.rgb;
    total_color = total_color + lighting(color, normal.xyz, position.xyz);

    output.color = float4(total_color, alpha);

    return output;
}


technique DirectionalLight
{
    pass P0
    {
        VertexShader = compile vs_3_0 MainVS();
        PixelShader = compile ps_3_0 MainPS();

        CullMode = None;
        ZEnable = false;
        ZWriteEnable = false;
    }
}
