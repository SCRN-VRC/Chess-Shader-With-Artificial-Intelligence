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
            #pragma target 5.0

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "../Shaders/Layout.cginc"
            //#include "../Shaders/Debugging.cginc"

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

            #define rot2(a) float2x2(cos(a+float4(0.,33.,11.,0.)))

            // https://www.iquilezles.org/www/articles/functions/functions.htm
            inline float cubicPulse( float c, float w, float x )
            {
                x = abs(x - c);
                if( x>w ) return 0.0;
                x /= w;
                return 1.0 - x*x*(3.0-2.0*x);
            }

            inline float triangleWave (float x, float h)
            {
                return h - abs(x % (2 * h) - h);
            }

            v2f vert (appdata v)
            {
                v2f o;

                // Vertex IDs are baked into the second UV map
                // Animate the ring
                float3 timeRing;
                timeRing.x = fmod(_Time.y * 1.4, 1.5);
                timeRing.y = fmod(_Time.y, 3.0);
                timeRing.z = sin(_Time.y * 5.0);

                v.vertex.y -= v.uv2.x > 0.75 ? timeRing.x * 0.5 : 0.0;
                v.vertex.xz *= v.uv2.x > 0.75 ? 1.0 - timeRing.x * 0.5 : 1.0;

                float4 vrcBotState = LoadValueFloat(_BufferTex, txVRCBotState);

                // // x-axis
                // v.vertex.xy = mul(rot2(_Time.y), v.vertex.xy);
                // // y-axis
                // v.vertex.xz = mul(rot2(_Time.y), v.vertex.xz);
                // // z-axis
                // v.vertex.yz = mul(rot2(_Time.y), v.vertex.yz);

                // Response animations first
                [flatten]
                if (vrcBotState.y == BOT_NO)
                {
                    // Shake
                    v.vertex.xz = mul(rot2(triangleWave(_Time.w * 2, 1.0) - 0.5), v.vertex.xz);
                }
                
                // State animations last
                [flatten]
                if (vrcBotState.x == BOT_IDLE)
                {
                    // Blink
                    float2 pulse;
                    pulse.x = cubicPulse(.2, .2, fmod(_Time.y, 8.0));
                    pulse.y = cubicPulse(.61, .14, fmod(_Time.y, 17.0));
                    v.vertex.y -= v.uv2.y > 0.5 ? 0.5 * min(pulse.x + pulse.y, 1.0): 0;
                    // Hover
                    v.vertex.y += _SinTime.z * 0.2;
                    // Sway
                    v.vertex.z += timeRing.z * 0.4;
                    v.vertex.yz = mul(rot2(timeRing.z * 0.2), v.vertex.yz);
                }
                else if (vrcBotState.x == BOT_PLAY)
                {
                    // Angry Eyes
                    v.vertex.y -= (v.uv2.y > 0.5 && v.uv2.x > 0.5) ?
                        0.15 : 0;
                    // Hover
                    v.vertex.y += 0.25 + _SinTime.z * 0.2;
                    // Lean forward
                    v.vertex.xy = mul(rot2(0.5), v.vertex.xy);
                    // Sway
                    v.vertex.xz = mul(rot2(_SinTime.y * 0.2), v.vertex.xz);
                }
                else if (vrcBotState.x == BOT_WIN)
                {
                    // Happy Eyes
                    v.vertex.y += v.uv2.y < 0.5 && v.uv2.y > 0.25 ? 0.28 : 0;
                    // Hop
                    v.vertex.y += timeRing.z * 0.7;
                    // Twist
                    float pulse = timeRing.y > 0.5 ? 1.0 : cubicPulse(.5, .5, timeRing.y);
                    v.vertex.xz = mul(rot2(pulse * UNITY_PI * 2), v.vertex.xz);
                }
                else if (vrcBotState.x == BOT_LOSE)
                {
                    // Sad Eyes
                    v.vertex.y += (v.uv2.x > 0.5 && v.uv2.x < 0.75) ?
                        0.1 : 0;
                    // Hover
                    v.vertex.y += 0.5 + _SinTime.z * 0.2;
                    // Lay down
                    v.vertex.xy = mul(rot2(-UNITY_PI * 0.5), v.vertex.xy);
                    v.vertex.y -= 0.8;
                }

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
