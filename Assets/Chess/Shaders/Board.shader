Shader "ChessBot/Board"
{
    Properties
    {
        _Color1 ("Color 1", Color) = (1,1,1,1)
        _Color2 ("Color 2", Color) = (0,0,0,1)
        _Color3 ("Color 3", Color) = (1,1,1,1)
        _Color4 ("Color 4", Color) = (0,0,0,1)
        _AtlasTex ("Chess Pieces Atlas", 2D) = "white" {}
        _BufferTex ("ChessBot Buffer", 2D) = "black" {}
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

                // uint4 boardBottom[4] = { castleTests[0][0], castleTests[0][1],
                //     castleTests[0][2], castleTests[0][3] };

                uint4 boardBottom[4];
                boardBottom[B_LEFT] =  LoadValueUint(_BufferTex, _Pixel * 2);
                boardBottom[B_RIGHT] = LoadValueUint(_BufferTex, _Pixel * 2 + uint2(1, 0));
                boardBottom[T_LEFT] =  LoadValueUint(_BufferTex, _Pixel * 2 + uint2(0, 1));
                boardBottom[T_RIGHT] = LoadValueUint(_BufferTex, _Pixel * 2 + uint2(1, 1));

                uint4 board[2] = { boardBottom[0], boardBottom[1] };

                //buffer[0] = float4((boardBottom[2] & 0xffff0000));

                // int2 src = int2(0, 1);
                // int2 dest = int2(0, 2);
                // uint2 pid = uint2(9, 8);

                // uint4 moved[4] = {
                //     doMove(boardBottom, 0, pid, src, dest),
                //     doMove(boardBottom, 1, pid, src, dest),
                //     doMove(boardBottom, 2, pid, src, dest),
                //     doMove(boardBottom, 3, pid, src, dest)
                // };

                // uint4 newPos[2] = { moved[0], moved[1] };

                // boardBottom[0] = moved[0];
                // boardBottom[1] = moved[1];
                // boardBottom[2] = moved[2];
                // boardBottom[3] = moved[3];
                // board[0] = boardBottom[0];
                // board[1] = boardBottom[1];
                // src = int2(2, 6);
                // dest = int2(2, 4);
                // pid = uint2(PAWN, 10);
                // moved[0] = doMove(boardBottom, 0, pid, src, dest);
                // moved[1] = doMove(boardBottom, 1, pid, src, dest);
                // moved[2] = doMove(boardBottom, 2, pid, src, dest);
                // moved[3] = doMove(boardBottom, 3, pid, src, dest);
                // newPos[0] = moved[0];
                // newPos[1] = moved[1];

                uint curPos;// = getPiece(newPos, uv_id);
                //if (index > 0.5) {
                    curPos = getPiece(board, uv_id);
                //}

                float2 piecePos = 0.14286 * float2((curPos & kMask), (curPos >> 3));
                float4 pc = tex2D(_AtlasTex, grid_uv * 0.14286 + piecePos);
                pc.rgb = lerp(_Color4, _Color3, smoothstep(0, 1, dot(pc.rgb, 1..xxx) * 0.5));

                float4 playerPosState = LoadValueFloat(_BufferTex, txPlayerPosState);
                col = lerp(col, float3(1., 0., 0.), playerPosState.x > -1 && all(uint2(playerPosState.xy) == uv_id));
                
                float4 playerSrcDest = LoadValueFloat(_BufferTex, txPlayerSrcDest);
                col = lerp(col, float3(0., 0., 1.), playerSrcDest.x > -1 && all(uint2(playerSrcDest.xy) == uv_id));
                
                bool clear = validMove(board, playerSrcDest.xy, uv_id);
                col = lerp(col, float3(0., 1., 0.), clear);

                col = lerp(col.rgb, pc.rgb, pc.a);

                return float4(col, 1.);
            }
            ENDCG
        }
    }
}
