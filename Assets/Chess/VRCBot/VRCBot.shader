Shader "ChessBot/VRCBot"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BufferTex ("ChessBot Buffer", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "../Shaders/Layout.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
            };

            Texture2D<float4> _BufferTex;
            sampler2D _MainTex;

            v2f vert (appdata v)
            {
                v2f o;

                // Vertex IDs are baked into the second UV map
                // Animate the ring
                float timeRing = fmod(_Time.y * 1.4, 1.5);
                v.vertex.y -= v.uv2.x > 0.75 ? timeRing * 0.5 : 0.0;
                v.vertex.xz *= v.uv2.x > 0.75 ? 1.0 - timeRing * 0.5 : 1.0;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv2 = v.uv2;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                // Lighting
                float3 lightDirection;
                float atten;

                // Directional light
                if(_WorldSpaceLightPos0.w == 0.0)
                {
                    atten = 1.0;
                    lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                }
                else
                {
                    float3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - i.worldPos.xyz;
                    float dist = length(fragmentToLightSource);
                    atten = 1.0/dist;
                    lightDirection = normalize(fragmentToLightSource);
                }

                float3 diffuseReflection = atten * _LightColor0.xyz *
                    saturate(dot(i.worldNormal, lightDirection));

                float3 lightFinal = pow(UNITY_LIGHTMODEL_AMBIENT.xyz +
                    diffuseReflection, 0.5);
                
                // Don't cast light on the rings
                col.rgb *= i.uv2.x < 0.75 ? lightFinal : 1.0;
                // Make rings transparent
                col.a = i.uv2.x < 0.75 ? col.a : col.r;

                return col;
            }
            ENDCG
        }
    }
}
