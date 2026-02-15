Shader "B1tH0ven/SimplexLit"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _ADDITIONAL_LIGHTS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            // --- SRP Batcher Compliant Uniforms ---
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            // --- Minimal Lambert implementation ---
            half3 SampleLambert(half3 normalWS, half3 lightDirWS)
            {
                return saturate(dot(normalWS, lightDirWS));
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                OUT.positionWS = positionWS;
                OUT.positionCS = TransformWorldToHClip(positionWS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 normal = normalize(IN.normalWS);
                half3 lighting = 0;

                // -------------------------
                // Main Light
                // -------------------------
                Light mainLight = GetMainLight();

                lighting += mainLight.color *
                            SampleLambert(normal, mainLight.direction) *
                            mainLight.distanceAttenuation *
                            mainLight.shadowAttenuation;

                // -------------------------
                // Additional Lights (Forward path)
                // -------------------------
                #if defined(_ADDITIONAL_LIGHTS)
                    uint pixelLightCount = GetAdditionalLightsCount();

                    LIGHT_LOOP_BEGIN(pixelLightCount)
                        Light light = GetAdditionalLight(lightIndex, IN.positionWS);

                        lighting += light.color *
                                    SampleLambert(normal, light.direction) *
                                    light.distanceAttenuation *
                                    light.shadowAttenuation;
                    LIGHT_LOOP_END
                #endif

                // -------------------------
                // Surface
                // -------------------------
                half4 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);

                half3 finalColor = baseTex.rgb * _BaseColor.rgb * lighting;

                return half4(finalColor, baseTex.a * _BaseColor.a);
            }
            ENDHLSL
        }
    }
}