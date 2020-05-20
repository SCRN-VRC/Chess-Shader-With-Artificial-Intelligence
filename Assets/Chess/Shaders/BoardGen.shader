Shader "ChessBot/BoardGen"
{
    Properties
    {
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

            void findParent (out uint4 outBoard[4], uint2 ID)
            {
                /// REDO
                // Texture2D<float4> srcTex = ID.y == 0 ? _ControllerTex : _BufferTex;
                // // The bottom left pixel
                // int2 src = 0;

                // if (ID.y < 1) { src = 0; }
                // else if (ID.y < 139) { src = int2((ID.x - 1) * 2, 0); }

                // outBoard[B_LEFT] = srcTex.Load(int3(src.xy, 0));
                // outBoard[B_RIGHT] = srcTex.Load(int3(src.x + 1, src.y, 0));
                // outBoard[T_LEFT] = srcTex.Load(int3(src.x, src.y + 1, 0));
                // outBoard[T_RIGHT] = srcTex.Load(int3(src.xy + 1, 0));
            }

            /*
                ID.x = Column id
                ID.y = Row id
            */
            uint4 genNewBoard (uint4 boardInput[4], uint2 ID, uint turn)
            {
                uint2 srcPieceID = 0;
                int2 src = 0;
                int2 dest = 0;

                [flatten]
                // Rooks, queen side then king side
                // srcPieceID.y contains the pID index for shifting
                if (ID.x < 28)
                {
                    // King side rooks don't shift
                    srcPieceID = uint2(ROOK, ID.x < 14 ? 0 : 7);
                    dest = 0;
                }
                // Knights
                else if (ID.x < 44)
                {
                    srcPieceID = uint2(KNIGHT, ID.x < 36 ? 1 : 6);
                    dest = knightList[(ID.x - 28) % 8];
                }
                // Bishops
                else if (ID.x < 70)
                {
                    srcPieceID = uint2(BISHOP, ID.x < 57 ? 2 : 5);
                    dest = 0;
                }
                // Queen
                // Kings/Queens don't need shifts srcPieceID.y shifts
                else if (ID.x < 97)
                {
                    srcPieceID = uint2(QUEEN, 3);
                    dest = 0;
                }
                // King
                else if (ID.x < 106)
                {
                    srcPieceID = uint2(KING, 4);
                    dest = kingList[ID.x - 97];
                }
                // Pawns
                else if (ID.x < 138)
                {
                    // Each unique pawn have 4 moves each
                    // pID for pawns goes from 8 to 15
                    srcPieceID = uint2(PAWN, floor((ID.x - 106) / 4) + 8);
                    dest = (turn == WHITE ? pawnListW[(ID.x - 106) % 4] :
                                            pawnListB[(ID.x - 106) % 4]);
                }

                srcPieceID.x += turn << 3;

                // Find the source position
                uint shift = srcPieceID.y - (floor(srcPieceID.y / 100) * 100);
                uint buff = ((boardInput[turn == WHITE ? T_LEFT : T_RIGHT]
                    [floor(pID[srcPieceID.y] / 100)]) >> shift) & 0xff;

                // Remember the board saves positions in (y, x) format
                // y, x to x, y
                src = int2(buff & 0xf, buff >> 4);
                dest = src + dest;

                //doMove(uint4 boardPosArray[4], uint posID, uint2 srcPieceID,
                //    int2 source, int2 dest)
                return doMove(boardInput, ID.y, srcPieceID, src, dest);

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
