Shader "Unlit/TimeFade"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _FadeTimer ("Fade Timer (seconds)", Float) = 30.0
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
            #include "Layout.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float _FadeTimer;

            float cubicPulse( float c, float w, float x )
            {
                x = abs(x - c);
                if(x > w) return 0.0;
                x /= w;
                return 1.0 - x*x*(3.0-2.0*x);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Blocky fade out effect
                fixed2 hashID = floor(i.uv * float2(_MainTex_TexelSize.z / _MainTex_TexelSize.w, 1.0) * 8.0);
                fixed timer = _Time.y + hash11((hashID.x + hashID.y * 8.0) * 82712.3384);
                fixed alpha = max(step(timer, _FadeTimer), cubicPulse(_FadeTimer, 2.0, timer));
                fixed4 col = tex2D(_MainTex, i.uv);
                col.a *= alpha;
                col.rgb *= col.a;
                return col;
            }
            ENDCG
        }
    }
}
