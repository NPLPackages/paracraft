/**
Author: LiXizhi
Email: lixizhi@yeah.net
Date: 2016.8.18
Desc: convert from left/right eye image to red/blue stereo image 
*/

texture sourceTexture0;
sampler leftSampler:register(s0) = sampler_state
{
    Texture = <sourceTexture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU = clamp;
    AddressV = clamp;
};

texture sourceTexture1;
sampler rightSampler:register(s1) = sampler_state
{
	Texture = <sourceTexture1>;
	MinFilter = Linear;
	MagFilter = Linear;
	AddressU = clamp;
	AddressV = clamp;
};

void StereoVS(float3 iPosition:POSITION,
	out float4 oPosition:POSITION,
	inout float2 texCoord:TEXCOORD0)
{
	oPosition = float4(iPosition,1);
}

float4 StereoPS(float2 texCoord:TEXCOORD0):COLOR
{
	float4 Color1 = tex2D(rightSampler, texCoord.xy);
	float4 Color2 = tex2D(leftSampler, texCoord.xy);

	Color1.r = Color2.r;
	Color1.g = Color1.g;
	Color1.b = Color1.b;
	Color1.a = 1.0f;
	return Color1;
}

technique Default
{
    pass P0
    {
		cullmode = none;
		ZEnable = false;
		ZWriteEnable = false;
		FogEnable = False;
		VertexShader = compile vs_2_0 StereoVS();
        PixelShader = compile ps_2_0 StereoPS();
    }
}