Shader "ChessBot/Board"
{
    Properties
    {
        _Color1 ("Color 1", Color) = (1,1,1,1)
        _Color2 ("Color 2", Color) = (0,0,0,1)
        _Color3 ("Color 3", Color) = (1,1,1,1)
        _Color4 ("Color 4", Color) = (0,0,0,1)
        _AtlasTex ("Chess Pieces", 2D) = "white" {}
        _BufferTex ("Buffer", 2D) = "black" {}
        _Pixel ("Pixel Check", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"
            #include "BotInclude.cginc"
            #include "Debugging.cginc"
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

            Texture2D<float4> _BufferTex;
            sampler2D _AtlasTex;
            float3 _Color1;
            float3 _Color2;
            float3 _Color3;
            float3 _Color4;
            uint2 _Pixel;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            float4 frag (v2f i) : SV_Target
            {
                uint2 uv_id = floor(i.uv * 8);
                float3 col = fmod(dot(uv_id, 1..xx), 2);
                col = lerp(_Color2, _Color1, col.r);
                float2 grid_uv = fmod(i.uv * 8, 1.);

                int index = fmod(floor(_Time.y), 2);
                // int index2 = fmod(floor(_Time.w / 8), 8);
                //uint4 boardBottom[4] = { newBoard(0), newBoard(1), newBoard(2), newBoard(3) };

                uint4 boardBottom[4] = { pawnTests[4][0], pawnTests[4][1],
                    pawnTests[4][2], pawnTests[4][3] };

                // uint4 boardBottom[4];
                // boardBottom[B_LEFT] =  LoadValue(_BufferTex, _Pixel);
                // boardBottom[B_RIGHT] = LoadValue(_BufferTex, _Pixel + uint2(1, 0));
                // boardBottom[T_LEFT] =  LoadValue(_BufferTex, _Pixel + uint2(0, 1));
                // boardBottom[T_RIGHT] = LoadValue(_BufferTex, _Pixel + uint2(1, 1));

                uint4 board[2] = { boardBottom[0], boardBottom[1] };

                buffer[0] = float4((boardBottom[3] & 0xffff0000) >> 16);

                int2 src = int2(2, 6);
                int2 dest = int2(2, 4);
                uint pid = PAWN;

                uint4 moved[2] = {
                    doMove(boardBottom, 0, uint2(pid, 10), src, dest),
                    doMove(boardBottom, 1, uint2(pid, 10), src, dest)
                };

                uint4 newPos[2] = {
                    doMove(boardBottom, 2, uint2(pid, 10), src, dest),
                    doMove(boardBottom, 3, uint2(pid, 10), src, dest)
                };

                uint curPos = getPiece(moved, uv_id);
                if (index > 0.5) {
                    curPos = getPiece(board, uv_id);
                }

                float2 piecePos = 0.14286 * float2((curPos & kMask), (curPos >> 3));
                float4 pc = tex2D(_AtlasTex, grid_uv * 0.14286 + piecePos);
                pc.rgb = lerp(_Color4, _Color3, smoothstep(0, 1, dot(pc.rgb, 1..xxx) * 0.5));

                bool clear = validMove(board, src, uv_id);

                col = lerp(col, float3(0., 1., 0.), clear);

                col = lerp(col.rgb, pc.rgb, pc.a);

                return float4(col, 1.);
            }
            ENDCG
        }
    }
}
