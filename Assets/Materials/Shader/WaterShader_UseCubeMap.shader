Shader "Custom/WaterShader_UseCubeMap"
{
 Properties
    {
        _BaseColor("BaseColor", Color) = (1, 1, 1, 1)
        _NormalMap1("NormalMap1", 2D) = "bump"{}
        _NormalMap2("NormalMap2", 2D) = "bump"{}
        _NormalMapMixRate("NormalMapMixRate",Range(0,1)) = 0
        //_ScrollSpeed("ScrollSpeed",float) = 0.01

        _ScrollX_1("ScrollX_1",float) = 0
        _ScrollY_1("ScrollY_1",float) = 0

        _ScrollX_2("ScrollX_2",float) = 0
        _ScrollY_2("ScrollY_2",float) = 0

        _Reflectance("Reflectance",Range(0,1)) = 0.04

        //Cubemap参照用プロパティ
        _BakedCubeMap("BakedCubeMap",Cube) = "white" {}
        _CubeMapPosition("CubeMapPosition",Vector) = (0,0,0,1)
        _BoxMax("Boxmax",Vector) = (0,0,0,0)
        _BoxMin("BoxMin",Vector) = (0,0,0,0) 

    }

    SubShader
    {
        //OpaqueTextureの代わりにあらかじめベイクしておいたCubeMapを参照して屈折表現を行うShader
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" }

        Pass
        {
            Tags{"LightMode"= "UniversalForward"}
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Back
            HLSLPROGRAM

            

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;

                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID 
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv_normal1 : TEXCOORD0;
                float2 uv_normal2 : TEXCOORD1;

                float3 normalWS : TEXCOORD2;

                float3 tangentWS : TEXCOORD3;
                float3 binormalWS : TEXCOORD4;
                float3 positionWS : TEXCOORD5;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_NormalMap1);
            SAMPLER(sampler_NormalMap1);
            TEXTURE2D(_NormalMap2);
            SAMPLER(sampler_NormalMap2);
            TEXTURECUBE(_BakedCubeMap);
            SAMPLER(sampler_BakedCubeMap);
            

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _NormalMap1_ST;
                float4 _NormalMap2_ST;
                float _ScrollX_1;
                float _ScrollY_1;
                float _ScrollX_2;
                float _ScrollY_2;
                half _Reflectance;
                half _NormalMapMixRate;

                half4 _BakedCubeMap_HDR;
                float4 _CubeMapPosition;
                float4 _BoxMax;
                float4 _BoxMin;

                
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                VertexNormalInputs vertexNormal = GetVertexNormalInputs(IN.normalOS,IN.tangentOS);
                //反射計算のためのベクトル取得
                OUT.normalWS = vertexNormal.normalWS;
                OUT.tangentWS = vertexNormal.tangentWS;
                OUT.binormalWS = vertexNormal.bitangentWS;

                OUT.positionWS = GetVertexPositionInputs(IN.positionOS.xyz).positionWS;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                

                float2 uv_normal1 = TRANSFORM_TEX(IN.uv, _NormalMap1);
                float2 uv_normal2 = TRANSFORM_TEX(IN.uv, _NormalMap2);

                OUT.uv_normal1 = float2(uv_normal1.x+_Time.y*_ScrollX_1,uv_normal1.y+_Time.y*_ScrollY_1);
                OUT.uv_normal2 = float2(uv_normal2.x+_Time.y*_ScrollX_2,uv_normal2.y+_Time.y*_ScrollY_2);
                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                float3 viewDir = normalize(GetCameraPositionWS() - IN.positionWS);
                //ノーマルマップを適用
                half3 normalMap1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap1, sampler_NormalMap1, IN.uv_normal1));
                half3 normalMap2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap2,sampler_NormalMap2,IN.uv_normal2));
                half3 mixedNormalMap = normalize(lerp(normalMap1,normalMap2,_NormalMapMixRate));
                half3 normal = normalize(IN.tangentWS * mixedNormalMap.x + IN.binormalWS * mixedNormalMap.y + IN.normalWS * mixedNormalMap.z);
                //屈折光の計算
                half3 refraction = refract(-viewDir,normal,1/1.33);
                half3 boxRefraction = BoxProjectedCubemapDirection(refraction,IN.positionWS,_CubeMapPosition,_BoxMin,_BoxMax);
                half3 refractionPixel = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(_BakedCubeMap,sampler_BakedCubeMap,boxRefraction,0),_BakedCubeMap_HDR);
                //反射光の計算
                
                float NdotVtoC = max(0,saturate(dot(normal,viewDir)));//ベクトルの内積計算式からcosを計算
                float3 reflection = reflect(-viewDir,normal);
                half3 reflectionPixel = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(_BakedCubeMap,sampler_BakedCubeMap,reflection,0),_BakedCubeMap_HDR);


                float fresnel = _Reflectance+((1-_Reflectance)*pow((1-NdotVtoC),5));//フレネル値

                //屈折光と反射光をフレネルの値で合成

                half3 finCol = lerp(refractionPixel,reflectionPixel , fresnel);

                return half4(finCol, 1);
            }
            ENDHLSL
        }
    }
}
