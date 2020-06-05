Shader "ChessBot/BoardGen"
{
    Properties
    {
        _BufferTex ("ChessBot Buffer", 2D) = "black" {}
        _TouchTex ("Touch Sensor Texture", 2D) = "black" {}
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
            #include "Layout.cginc"

            /*
                Max moves per piece
                Piece  Rq  Rk  Nq  Nk  Bq  Bk  Q   K  P
                Moves  16  16  8   8   15  15  31  8  32  =  149 possible moves

                Every board generates 149 boards, one board is 2x2 pixels
                298 x 2 pixels generated per board
            */

            Texture2D<float4> _BufferTex;
            Texture2D<float4> _TouchTex;
            float4 _TouchTex_TexelSize;
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

            /*
                ID = Column id
            */
            void doMoveParams (in uint4 boardInput[4], in uint ID, in uint turn,
                out uint2 srcPieceID, out int2 src, out int2 dest)
            {

                uint idx_t = ID.x;

                // Pawns
                if (idx_t < moveNum[PAWN].y)
                {
                    // Each unique pawn have 4 moves each
                    // pID for pawns goes from 8 to 15
                    srcPieceID = uint2(PAWN, floor(idx_t / 4) + 8);
                    dest = (turn == WHITE ? pawnListW[idx_t % 4] :
                                            pawnListB[idx_t % 4]);
                }
                // Knights
                else if (idx_t < moveNum[KNIGHT].y)
                {
                    idx_t -= moveNum[PAWN].y;
                    srcPieceID = uint2(KNIGHT,
                        idx_t < uint(moveNum[KNIGHT].x * 0.5) ? 1 : 6);
                    dest = knightList[idx_t % 8];
                }
                // Bishops
                else if (idx_t < moveNum[BISHOP].y)
                {
                    idx_t -= moveNum[KNIGHT].y;
                    srcPieceID = uint2(BISHOP,
                        idx_t < uint(moveNum[BISHOP].x * 0.5) ? 2 : 5);
                    dest = 0;
                }
                // Rooks
                else if (idx_t < moveNum[ROOK].y)
                // King side rooks don't shift
                {
                    idx_t -= moveNum[BISHOP].y;
                    srcPieceID = uint2(ROOK,
                        idx_t < uint(moveNum[ROOK].x * 0.5) ? 0 : 7);
                    dest = 0;
                }
                // Queen
                // Kings/Queens don't need shifts srcPieceID.y shifts
                else if (idx_t < moveNum[QUEEN].y)
                {
                    srcPieceID = uint2(QUEEN, 3);
                    dest = 0;
                }
                // King
                else if (idx_t < moveNum[KING].y)
                {
                    idx_t -= moveNum[QUEEN].y;
                    srcPieceID = uint2(KING, 4);
                    dest = kingList[idx_t];
                }
                else
                {
                    srcPieceID = 0;
                    dest = -1000;
                }
                srcPieceID.x |= turn << 3;

                // Find the source position
                uint shift = pID[srcPieceID.y] -
                    (floor(pID[srcPieceID.y] / 100) * 100);
                uint buff = ((boardInput[turn == WHITE ? T_LEFT : T_RIGHT]
                    [floor(pID[srcPieceID.y] / 100)]) >> shift) & 0xff;
                
                // The board saves positions in (y, x) format
                // y, x to x, y make sure to -1 
                src = int2(buff & 0xf, buff >> 4) - 1;

                // Reset ID
                idx_t = ID.x;

                // Pawns
                if (idx_t < moveNum[PAWN].y)
                { dest = src + dest; }
                // Knights
                else if (idx_t < moveNum[KNIGHT].y)
                { dest = src + dest; }
                // Bishops
                else if (idx_t < moveNum[BISHOP].y)
                {
                    idx_t -= moveNum[KNIGHT].y;
                    int4 bOrigin = getBishopOrigin(src);
                    // King/Queen side
                    uint IDcond = fmod(idx_t, moveNum[BISHOP].x * 0.5);
                    [flatten]
                    // Queen side
                    if (idx_t < uint(moveNum[BISHOP].x * 0.5))
                    {
                        // Since the bishop moves aren't mirror for the black pieces
                        dest = IDcond < (turn ? 7 : 8) ?
                            bOrigin.xy + int2(-1, 1) * IDcond :
                            bOrigin.zw + int2(1, 1) * (IDcond - (turn ? 7 : 8));
                    }
                    // King side
                    else
                    {
                        dest = IDcond < (turn ? 7 : 8) ?
                            bOrigin.zw + int2(1, 1) * IDcond :
                            bOrigin.xy + int2(-1, 1) * (IDcond - (turn ? 7 : 8));
                    }
                }
                // Rooks
                else if (idx_t < moveNum[ROOK].y)
                {
                    idx_t -= moveNum[BISHOP].y;
                    // Half of the move-set goes horizontal, half vertical
                    uint idMod = fmod(idx_t, moveNum[ROOK].x * 0.5);
                    uint r = moveNum[ROOK].x * 0.25;
                    dest.x = idMod < r ? idMod : src.x ;
                    dest.y = idMod < r ? src.y : idMod - r ;
                }
                // Queen
                else if (idx_t < moveNum[QUEEN].y)
                {
                    idx_t -= moveNum[ROOK].y;
                    [flatten]
                    // Rook like movement
                    if (idx_t < uint(moveNum[ROOK].x * 0.5)) {
                        uint r = moveNum[ROOK].x * 0.25;
                        dest.x = idx_t < r ? idx_t : src.x ;
                        dest.y = idx_t < r ? src.y : idx_t - r ;
                    }
                    // Bishop like movement
                    else {
                        idx_t -= uint(moveNum[ROOK].x * 0.5);
                        int4 bOrigin = getBishopOrigin(src);
                        // Different moves on white/black tiles
                        bool onBlack = (src.x % 2 == src.y % 2);
                        dest = idx_t < (onBlack ? 7 : 8) ?
                            bOrigin.xy + int2(-1, 1) * idx_t :
                            bOrigin.zw + int2(1, 1) * (idx_t - (onBlack ? 7 : 8));
                    }
                }
                // King
                else if (idx_t < moveNum[KING].y)
                { dest = src + dest; }
            }

            // Given the board ID, return the parent position
            // of the generated board
            int2 findParentBoard(int boardSetID)
            {
                return boardSetID == 0 ?
                    txCurBoardBL :
                    int2((boardSetID - 1) * 2, 0) ;
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

            uint4 frag (v2f ps) : SV_Target
            {
                clip(ps.uv.z);
                int2 px = floor(ps.uv.xy * _ScreenParams.xy);
                uint4 col = asuint(_BufferTex.Load(int3(px, 0)));

                // 20 FPS
                float4 timerLift = LoadValueFloat(_BufferTex, txTimerLift);
                timerLift.x += unity_DeltaTime;

                if (timerLift.x < 0.05)
                {
                    StoreValueFloat(txTimerLift, timerLift, col, px);
                    return col;
                }
                else timerLift.x = 0.0;

                // UVs of set of boards generated per board
                float2 boardsUV = fmod(px, boardParams.xy) / boardParams.xy;

                // UVs of a single board (2x2)
                float3 singleUV_ID = 0.0;
                singleUV_ID.xy = fmod(px, 2..xx);
                // ID of each corner
                singleUV_ID.z = singleUV_ID.y * 2 + singleUV_ID.x;

                // ID for each set of boards, 150 total
                uint boardSetID = floor(ps.uv.y * _ScreenParams.y * 0.5);

                float4 turnWinUpdateLate = LoadValueFloat(_BufferTex, txTurnWinUpdateLate);
                float4 kingMoved = LoadValueFloat(_BufferTex, txKingMoved);
                float4 playerSrcDest = LoadValueFloat(_BufferTex, txPlayerSrcDest);
                float4 playerPosState = LoadValueFloat(_BufferTex, txPlayerPosState);

                // Initialize the shaduuurrr
                if (_Time.y < 1.0) {
                    turnWinUpdateLate.xyzw = float4(1.0, -1.0, 6.0, 0.0);
                    kingMoved.xyzw = 0.0;
                    timerLift.xyzw = 0.0;
                    playerSrcDest = -1.0;
                    playerPosState.xyzw = float4(-1..xx, 0..xx);
                }

                [branch]
                // Flatten min-max tree into 150 pixels
                if (all(px >= txEvalArea.xy))
                {
                    float4 evalPrev = asfloat(_BufferTex.Load(int3(px, 0)));
                    // Reset
                    evalPrev = turnWinUpdateLate.z < 6.0 ?
                        float4(FLT_MIN, 0..xxx) : evalPrev;

                    // Only update after all boards are generated
                    [branch]
                    if (turnWinUpdateLate.z == 6.0 && evalPrev.w < 1.0)
                    {
                        const int MAX_KEEP = 10;
                        uint4 board[2];
                        uint2 c = 0;
                        int2 bestBoards[MAX_KEEP]; // Keep 10 of the best
                        int id = px.x - txEvalArea.x + 1;
                        [loop]
                        for (int i = 0; i < floor(boardParams.x * 0.5); i++)
                        {
                            // Only the top pixels
                            board[0] = asuint(_BufferTex.Load(int3(i * 2, id * 2 + 1, 0)));
                            board[1] = asuint(_BufferTex.Load(int3(i * 2 + 1, id * 2 + 1, 0)));
                            float score = eval(board, turnWinUpdateLate.w);
                            [flatten]
                            if (score >= evalPrev.x) {
                                c.xy = score > evalPrev.x ? 0 : c.xy;
                                bestBoards[c.x] = int2(i * 2, id * 2);
                                evalPrev.x = score;
                                c.x = (c.x + 1) % MAX_KEEP;
                                c.y += 1;
                            }
                        }
                        // Pick a "random" board if scores are equal
                        uint ind = floor(hash11(c.x + c.y) * min(c.y, 10));
                        evalPrev.yz = bestBoards[ind].xy;
                        // Mark as done
                        evalPrev.w = 1.0;
                    }
                    col = asuint(evalPrev);
                }
                // Parameters to save
                else if (px.y >= int(txCurBoardBL.y))
                {
                    uint4 curBoard[4];
                    curBoard[B_LEFT] =  LoadValueUint(_BufferTex, txCurBoardBL);
                    curBoard[B_RIGHT] = LoadValueUint(_BufferTex, txCurBoardBR);
                    curBoard[T_LEFT] =  LoadValueUint(_BufferTex, txCurBoardTL);
                    curBoard[T_RIGHT] = LoadValueUint(_BufferTex, txCurBoardTR);
                    
                    uint4 bTop[2] = {curBoard[T_LEFT], curBoard[T_RIGHT]};
                    buffer[0] = eval(bTop, 0).xxxx;

                    // New board
                    if (floor(turnWinUpdateLate.x) == 1)
                    {
                        curBoard[B_LEFT] = newBoard(B_LEFT);
                        curBoard[B_RIGHT] = newBoard(B_RIGHT);
                        curBoard[T_LEFT] = newBoard(T_LEFT);
                        curBoard[T_RIGHT] = newBoard(T_RIGHT);
                    }

                    // buffer[0] = (uint4((curBoard[T_RIGHT][2] & 0xffff0000) >> 16,
                    //     curBoard[T_RIGHT][2] & 0xffff,
                    //     (curBoard[T_RIGHT][3] & 0xffff0000) >> 16,
                    //     curBoard[T_RIGHT][3] & 0xffff));

                    // Increment board generation counter
                    // only on computers turn
                    turnWinUpdateLate.z = turnWinUpdateLate.z < 6.0 &&
                        fmod(turnWinUpdateLate.x, 2.0) == BLACK ?
                            turnWinUpdateLate.z + 1.0 :
                            turnWinUpdateLate.z;
                    
                    uint4 buf;
                    // Check if king moved, for castling
                    bool2 moved;
                    moved.x = kingMoved.x > 0.0 ? true : false;
                    moved.y = kingMoved.y > 0.0 ? true : false;
                    buf.x = curBoard[T_LEFT][1];
                    buf.y = curBoard[T_RIGHT][1];
                    buf = (buf >> 24) & 0xff;
                    moved.x = moved.x || (uint2(buf.x >> 4, buf.x & 0xf) == 
                        uint2(1, 5) ? false : true);
                    moved.y = moved.y || (uint2(buf.y >> 4, buf.y & 0xf) == 
                        uint2(8, 5) ? false : true);
                    kingMoved.x = moved.x ? 1.0 : 0.0;
                    kingMoved.y = moved.y ? 1.0 : 0.0;

                    // Check if king is dead
                    turnWinUpdateLate.y = turnWinUpdateLate.y < 0.0 ?
                        buf.x == 0 ? BLACK :
                            buf.y == 0 ? WHITE : turnWinUpdateLate.y :
                        turnWinUpdateLate.y;

                    // Check if current board is in late game
                    bool lateGame = turnWinUpdateLate.w > 0.0 ? true : false;
                    
                    // Both sides no queens
                    buf.x = curBoard[T_LEFT][0];
                    buf.y = curBoard[T_RIGHT][0];
                    buf = buf & 0xff;
                    lateGame = lateGame || ((buf.x + buf.y) > 0 ? false : true);

                    // One queen no pieces
                    buf.x = curBoard[T_LEFT][0] & 0xffffff00;
                    buf.y = curBoard[T_LEFT][1] & 0x00ffffff;
                    buf.z = curBoard[T_RIGHT][0] & 0xffffff00;
                    buf.w = curBoard[T_RIGHT][1] & 0x00ffffff;
                    lateGame = lateGame || ((buf.x + buf.y + buf.z + buf.w) > 0 ?
                        false : true);
                    
                    // Minor piece only
                    int c = 0;
                    [unroll]
                    for (int i = 0; i <= 24; i += 8) {
                        // There is a piece, position does not matter
                        uint4 bt = ((buf >> i) & 0xff);
                        c = bt.x > 0 ? c + 1 : c;
                        c = bt.y > 0 ? c + 1 : c;
                        c = bt.z > 0 ? c + 1 : c;
                        c = bt.w > 0 ? c + 1 : c;
                    }
                    lateGame = lateGame || (c <= 1 ? true : false);
                    turnWinUpdateLate.w = lateGame ? 1.0 : 0.0;

                    // Computer's turn
                    float checkEval = asfloat(_BufferTex.Load(int3(txEvalArea.xy, 0)).w);
                    // Game not over, correct update phase
                    [branch]
                    if ((uint(turnWinUpdateLate.x) % 2 == BLACK) &&
                        checkEval > 0.0 && turnWinUpdateLate.z == 6.0 &&
                        turnWinUpdateLate.y < 0.0)
                    {
                        // Pick best move for computer (black)
                        int2 bestMove = -1;
                        float bestScore = FLT_MAX;
                        [unroll]
                        for (int i = txEvalArea.x; i <= txEvalArea.z; i++) {
                            float4 eOut = asfloat(_BufferTex.Load(int3(i, txEvalArea.y, 0)));
                            bestMove = ((eOut.x < bestScore) && (eOut.x > FLT_MIN)) ?
                                eOut.yz : bestMove;
                            bestScore = ((eOut.x < bestScore) && (eOut.x > FLT_MIN)) ?
                                eOut.x : bestScore;
                        }

                        // Replace the current board
                        if (bestMove.x > -1) {
                            // The y value corresponds to the parent board
                            bestMove.xy = int2(bestMove.y - 2, 0);
                            curBoard[B_LEFT] = LoadValueUint(_BufferTex, bestMove);
                            curBoard[B_RIGHT] = LoadValueUint(_BufferTex, bestMove + int2(1, 0));
                            curBoard[T_LEFT] = LoadValueUint(_BufferTex, bestMove + int2(0, 1));
                            curBoard[T_RIGHT] = LoadValueUint(_BufferTex, bestMove + int2(1, 1));
                        }

                        // Player's turn
                        turnWinUpdateLate.x += 1.0;
                    }

                    // Player's turn
                    [branch]
                    if (turnWinUpdateLate.y < 0.0 &&
                        fmod(turnWinUpdateLate.x, 2.0) == WHITE)
                    {
                        // Average position
                        float3 touchPosCount = 0.0;
                        [unroll]
                        for (int i = 0; i < 8; i++) {
                            [unroll]
                            for (int j = 0; j < 8; j++) {
                                float d = _TouchTex.Load(int3(i, j, 0)).r;
                                touchPosCount.xy += d > 0.0 ? float2(i, j) : 0..xx;
                                touchPosCount.z += d > 0.0 ? 1.0 : 0.0;
                            }
                        }
                        touchPosCount.xy = floor(touchPosCount.xy /
                            max(touchPosCount.z, 1.));

                        // x is flipped
                        touchPosCount.x = 7.0 - touchPosCount.x;

                        playerPosState.xy = touchPosCount.z > 0.0 ?
                            touchPosCount.xy : playerPosState.xy;
                        playerPosState.z = touchPosCount.z;

                        // Figure out player inputs
                        if (playerPosState.w == PSTATE_SRC)
                        {
                            playerSrcDest.zw = -1;
                            int2 srcPos = playerPosState.z > 0.0 ?
                                playerPosState.xy : playerSrcDest.xy;
                            uint4 board[2] = { curBoard[B_LEFT], curBoard[B_RIGHT] };
                            uint pc = srcPos.x > -1 ? getPiece(board, srcPos) : 0;
                            // If something there with the player color
                            [flatten]
                            if ((pc.x & kMask) != 0 && (pc.x >> 3) == WHITE)
                            {

                                playerSrcDest.xy = srcPos;
                                playerPosState.w = PSTATE_LIFT;
                                timerLift.y = 0.0;
                            }
                        }
                        // Wait for nothing touching
                        else if (playerPosState.w == PSTATE_LIFT)
                        {
                            timerLift.y += unity_DeltaTime;
                            playerPosState.w = playerPosState.z < 1.0 &&
                                timerLift.y > 0.35 ?
                                    PSTATE_DEST : PSTATE_LIFT;
                        }
                        // Accept next input
                        else
                        {
                            int2 destPos = playerPosState.z > 0.0 ?
                                playerPosState.xy : playerSrcDest.zw;
                            uint4 board[2] = { curBoard[B_LEFT], curBoard[B_RIGHT] };
                            // Make player move
                            [branch]
                            if (destPos.x > -1 &&
                                validMove(board, playerSrcDest.xy, destPos, kingMoved))
                            {
                                // Find the ID
                                uint2 pieceID = 0;
                                pieceID.x = getPiece(board, playerSrcDest.xy);
                                uint4 wPcs = curBoard[T_LEFT];
                                [unroll]
                                for (int i = 0; i < 4; i++) {
                                    [unroll]
                                    for (int j = 0; j < 4; j++) {
                                        uint buf = (wPcs[i] >> (8 * (3 - j))) & 0xff;
                                        pieceID.y = all(int2(playerSrcDest.xy) ==
                                            (int2(buf & 0xf, buf >> 4) - 1)) ?
                                                i * 4 + j : pieceID.y;
                                    }
                                }

                                uint4 pastBoard[4] = {
                                    curBoard[B_LEFT], curBoard[B_RIGHT],
                                    curBoard[T_LEFT], curBoard[T_RIGHT]
                                };

                                curBoard[B_LEFT] = doMoveNoCheck(pastBoard, B_LEFT,
                                    pieceID, playerSrcDest.xy, destPos, 1);
                                curBoard[B_RIGHT] = doMoveNoCheck(pastBoard, B_RIGHT,
                                    pieceID, playerSrcDest.xy, destPos, 1);
                                curBoard[T_LEFT] = doMoveNoCheck(pastBoard, T_LEFT,
                                    pieceID, playerSrcDest.xy, destPos, 1);
                                curBoard[T_RIGHT] = doMoveNoCheck(pastBoard, T_RIGHT,
                                    pieceID, playerSrcDest.xy, destPos, 1);
                                
                                //buffer[0] = float4(pieceID, destPos);

                                // Next turn and reset player
                                turnWinUpdateLate.x += 1.0;
                                turnWinUpdateLate.z = 0.0;
                                playerSrcDest.xy = -1.0;
                                playerSrcDest.zw = destPos;
                                playerPosState.xyzw = float4(-1..xx, 0..xx);
                            }
                            else
                            {
                                // Else reset source position
                                playerPosState.w = destPos.x < 0 ?
                                    PSTATE_DEST : PSTATE_SRC;
                                playerSrcDest = destPos.x < 0 ? playerSrcDest : -1;
                            }
                        }
                    }

                    StoreValueUint(txCurBoardBL, curBoard[B_LEFT], col,  px);
                    StoreValueUint(txCurBoardBR, curBoard[B_RIGHT], col, px);
                    StoreValueUint(txCurBoardTL, curBoard[T_LEFT], col,  px);
                    StoreValueUint(txCurBoardTR, curBoard[T_RIGHT], col, px);
                    StoreValueFloat(txKingMoved, kingMoved, col, px);
                    StoreValueFloat(txTimerLift, timerLift, col, px);
                    StoreValueFloat(txPlayerSrcDest, playerSrcDest, col, px);
                    StoreValueFloat(txPlayerPosState, playerPosState, col, px);
                    StoreValueFloat(txTurnWinUpdateLate, turnWinUpdateLate, col, px);
                }
                // Actual board
                else if (all(px < int2(boardParams.zw)))
                {
                    // Stagger the move generation for slower GPUs
                    [branch]
                    if (turnWinUpdateLate.z < 6.0 &&
                        px.y >= boardUpdate[int(turnWinUpdateLate.z)] &&
                        px.y < boardUpdate[int(turnWinUpdateLate.z + 1.0)])
                    {
                        int2 parentPos = findParentBoard(boardSetID);
                        uint4 parentBoard[4];
                        parentBoard[B_LEFT] =  LoadValueUint(_BufferTex, parentPos);
                        parentBoard[B_RIGHT] = LoadValueUint(_BufferTex, parentPos +
                            int2(1, 0));
                        parentBoard[T_LEFT] =  LoadValueUint(_BufferTex, parentPos +
                            int2(0, 1));
                        parentBoard[T_RIGHT] = LoadValueUint(_BufferTex, parentPos +
                            int2(1, 1));
                        
                        uint2 srcPieceID = 0;
                        int2 src = 0;
                        int2 dest = 0;

                        // Anything after the first row of boards is the following turn
                        uint turn = px.y > 1 ? WHITE : BLACK;
                // void doMoveParams (in uint4 boardInput[4], in uint ID, in uint turn,
                //     out uint2 srcPieceID, out int2 src, out int2 dest)

                        doMoveParams(parentBoard, floor(px.x * 0.5),
                            turn, srcPieceID, src, dest);

                // uint4 doMove(in uint4 boardPosArray[4], in uint posID, in uint2 srcPieceID,
                //     in int2 source, in int2 dest)

                        col = (doMove(parentBoard, uint(singleUV_ID.z),
                            srcPieceID, src, dest, kingMoved));
                    }
                }
                return col;
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
