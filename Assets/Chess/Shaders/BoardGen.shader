Shader "ChessBot/BoardGen"
{
    Properties
    {
        _ControllerTex ("Controller", 2D) = "black" {}
        _BufferTex ("Buffer", 2D) = "black" {}
        _MaxDist ("Max Distance", Float) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"
            #include "BotInclude.cginc"
            #include "Debugging.cginc"

            Texture2D<float4> _ControllerTex;
            Texture2D<float4> _BufferTex;
            float _MaxDist;

            struct appdata
            {
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            void findParent (out uint4 outBoard[4], uint3 ID)
            {
                Texture2D<float4> srcTex = ID.z == 0 ? _ControllerTex : _BufferTex;
                // The bottom left pixel
                int2 src = 0;

                if (ID.z < 1) { src = 0; }
                else if (ID.z < 139) { src = int2((ID.x - 1) * 2, 0); }

                outBoard[B_LEFT] = srcTex.Load(int3(src.xy, 0));
                outBoard[B_RIGHT] = srcTex.Load(int3(src.x + 1, src.y, 0));
                outBoard[T_LEFT] = srcTex.Load(int3(src.x, src.y + 1, 0));
                outBoard[T_RIGHT] = srcTex.Load(int3(src.xy + 1, 0));
            }

            //doMove(uint4 boardPosArray[4], uint posID, uint2 srcPieceID,
            //    int2 source, int2 dest)
            /*
                ID.x = Column id
                ID.y = Row id
                ID.z = Depth id
            */
            uint4 genNewBoard (uint4 boardInput[4], uint3 ID, uint turn)
            {
                uint2 srcPieceID = 0;
                uint2 src = 0;
                uint2 dest = 0;
                uint2 pieceLoc = 0;

                // Rooks, queen side then king side
                if (ID.x < 28) { srcPieceID = uint2(ID.x < 14 ? 0 : 1, pID[0]); }
                // Knights
                else if (ID.x < 44)
                { srcPieceID = uint2(ID.x < 36 ? 0 : 1, pID[1]); }
                // Bishops
                else if (ID.x < 70)
                { srcPieceID = uint2(ID.x < 57 ? 0 : 1, pID[2]); }
                // Queen
                else if (ID.x < 97)
                { srcPieceID = uint2(0, pID[3]); }
                // King
                else if (ID.x < 106)
                { srcPieceID = uint2(1, pID[3]); }
                // Pawns
                else if (ID.x < 138)
                { srcPieceID = uint2(ID.x < 122 ? 2 : 3, pID[((ID.x - 106) / 4) % 4]); }

                srcPieceID.x += turn << 3;

                uint buff = boardInput[turn == WHITE ? T_LEFT : T_RIGHT]
                    [floor(srcPieceID.y / 100)];

                return doMove(boardInput, ID.x % 1 + ID.y % 1, srcPieceID, src, dest);

            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = float4(v.uv * 2 - 1, 0, 1);
                #ifdef UNITY_UV_STARTS_AT_TOP
                v.uv.y = 1-v.uv.y;
                #endif
                o.uv.xy = UnityStereoTransformScreenSpaceTex(v.uv);
                o.uv.z = distance(_WorldSpaceCameraPos,
                    mul(unity_ObjectToWorld, fixed4(0,0,0,1)).xyz) > _MaxDist ?
                    -1 : 1;
                return o;
            }

            /*
                Max moves per piece
                Piece  Rq  Rk  Nq  Nk  Bq  Bk  Q   K  P
                Moves  14  14  8   8   13  13  27  9  32  =  138 possible moves

                Every board generates 138 boards, one board is 2x2 pixels
                276 x 2 pixels generated per board
            */

            #define BOARD_DIM      float2(276, 2)

            float4 frag (v2f ps) : SV_Target
            {
                clip(ps.uv.z);
                float4 col = 0;

                // UVs of set of boards generated per board
                float2 boardsUV = fmod(ps.uv.xy * _ScreenParams.xy,
                    BOARD_DIM) / BOARD_DIM;

                // UVs of a single board (2x2)
                uint3 singleUV_ID;
                singleUV_ID.xy = fmod(ps.uv.xy * _ScreenParams.xy, 2..xx);
                // ID of each corner
                singleUV_ID.z = singleUV_ID.y * 2 + singleUV_ID.x;

                // Board number
                uint boardID = ps.uv.y;

                col = newBoard(singleUV_ID.z);

                return col;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
