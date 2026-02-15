Shader "B1tH0ven/SineWater"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _Wavelength("Wavelength (L)", Float) = 1.0
        _Amplitude("Amplitude (A)", Float) = 1.0
        _PhaseConstant("Phase-Constant, phi = speed * 2 / L", Float) = 2.0
        _Direction("Wave direction (D)", Vector) = (0.707, 0.707, 0.0, 0.0)
        _SimulationTime("Simulation time", Float) = 0.1
        _SineOcclusionFactor("Sine Occlusion", Float) = 0.25
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
                float _Wavelength;
                float _Amplitude;
                float _PhaseConstant;
                float2 _Direction;
                float _SimulationTime;
                half _SineOcclusionFactor;
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
                float3 uv : TEXCOORD2;
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

                float sine = sin(dot(_Direction, positionWS.xz) * _Wavelength + _SimulationTime * _PhaseConstant);
                float height = _Amplitude * sine;
                positionWS.y += height;

                float dHdx = _Amplitude * _Wavelength * cos(dot(_Direction, positionWS.xz) * _Wavelength + _SimulationTime * _PhaseConstant) * _Direction.x;
                float3 binormal = float3(_Direction.x, dHdx, _Direction.y);

                float dHdz = _Amplitude * _Wavelength * cos(dot(_Direction, positionWS.xz) * _Wavelength + _SimulationTime * _PhaseConstant) * _Direction.y;
                float3 tangent = float3(-_Direction.y, dHdz, _Direction.x);

                OUT.positionWS = positionWS;
                OUT.positionCS = TransformWorldToHClip(positionWS);
                OUT.normalWS = normalize(float3(-dHdx, 1.0, -dHdz));
                OUT.uv = float3(IN.uv, (sine + 1.0) * 0.5);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half3 normal = normalize(IN.normalWS);
                half3 lighting = 0;

                Light mainLight = GetMainLight();
                lighting += mainLight.color *
                            SampleLambert(normal, mainLight.direction) *
                            mainLight.distanceAttenuation *
                            mainLight.shadowAttenuation;

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

                half sineOcclusion = lerp(1.0, IN.uv.z, saturate(_SineOcclusionFactor));
                half3 finalColor = baseTex.rgb * _BaseColor.rgb * lighting * sineOcclusion;

                //return half4(IN.normalWS, 1.0);

                return half4(finalColor, baseTex.a * _BaseColor.a);
            }
            ENDHLSL
        }
    }
}