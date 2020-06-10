/*
    TODO LIST:
    - None! :)
*/

Shader "ChessBot/BoardGen"
{
    Properties
    {
        _BufferTex ("ChessBot Buffer", 2D) = "black" {}
        _TouchTex ("Touch Sensor Texture", 2D) = "black" {}
        _ButtonTex ("Button Sensor Texture", 2D) = "black" {}
        _MaxDist ("Max Distance", Float) = 0.05
        _Seed ("Random Gen Seed", Float) = 8008
    }
    SubShader
    {
        Tags { "Queue"="Overlay+1" "ForceNoShadowCasting"="True" "IgnoreProjector"="True" }
        ZWrite Off
        ZTest Always
        Cull Front

        Pass
        {
            Lighting Off
            SeparateSpecular Off
            Fog { Mode Off }
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"
            #include "ChessInclude.cginc"
            #include "Debugging.cginc"
            #include "Layout.cginc"

            /*
                Max moves per piece
                Piece  Rq  Rk  Nq  Nk  Bq  Bk  Q   K  P
                Moves  16  16  8   8   15  15  31  10  32  =  151 possible moves

                Every board generates 151 boards, one board is 2x2 pixels
                302 x 2 pixels generated per board
            */

            Texture2D<float4> _BufferTex;
            Texture2D<float4> _TouchTex;
            Texture2D<float4> _ButtonTex;
            float _MaxDist;
            float _Seed;

            struct appdata
            {
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

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

                // 15 FPS
                float4 timerLiftSeed = LoadValueFloat(_BufferTex, txTimerLiftSeed);
                timerLiftSeed.x += unity_DeltaTime;

                if (timerLiftSeed.x < 0.06667)
                {
                    StoreValueFloat(txTimerLiftSeed, timerLiftSeed, col, px);
                    return col;
                }
                else timerLiftSeed.x = 0.0;

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
                float4 drawResignNewReset = LoadValueFloat(_BufferTex, txDrawResignNewReset);
                float4 buttonPos = LoadValueFloat(_BufferTex, txButtonPos);
                float4 lastDest = LoadValueFloat(_BufferTex, txLastDest);

                // Initialize the shaduuurrr
                if (_Time.y < 1.0 ||
                    drawResignNewReset.w > 0.0 ||
                    (drawResignNewReset.z > 0.0 && buttonPos.z < 1.0))
                {
                    turnWinUpdateLate = float4(1.0, -1.0, 6.0, 0.0);
                    kingMoved = 0.0;
                    // I want to randomize the next game unless it's a full reset
                    timerLiftSeed = float4(0.0, 0.0,
                        drawResignNewReset.z > 0.0 ?
                            (hash11(timerLiftSeed.z) * _Seed) : _Seed, 0.0);
                    playerSrcDest = -1.0;
                    playerPosState = float4(-1..xx, 0..xx);
                    drawResignNewReset = 0.0;
                    buttonPos = 0.0;
                    lastDest = -1.0;
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
                                c.xy = score > evalPrev.x ? 0..xx : c.xy;
                                bestBoards[c.x] = int2(i * 2, id * 2);
                                evalPrev.x = score;
                                c.x = (c.x + 1) % MAX_KEEP;
                                c.y += 1;
                            }
                        }
                        // Pick a "random" board if scores are equal
                        uint ind = floor(hash11(id * timerLiftSeed.z)
                            * min(c.y, MAX_KEEP));

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

                    // Offer draw, resign, etc buttons
                    float3 buttonPosCount = 0.0;
                    [unroll]
                    for (int i = 0; i < 6; i++) {
                        [unroll]
                        for (int j = 0; j < 6; j++) {
                            float d = _ButtonTex.Load(int3(i, j, 0)).r;
                            buttonPosCount.xy += d > 0.0 ? float2(i, j) : 0..xx;
                            buttonPosCount.z += d > 0.0 ? 1.0 : 0.0;
                        }
                    }
                    buttonPosCount.xy = floor(buttonPosCount.xy /
                        max(buttonPosCount.z, 1.) * 0.3333 + .3333);

                    // x is flipped
                    buttonPosCount.x = 1.0 - buttonPosCount.x;

                    buttonPos.xyz = buttonPosCount;

                    // Offer draw
                    drawResignNewReset.x = buttonPosCount.z > 0.0 &&
                        all(int2(buttonPosCount.xy) == int2(0, 1)) ? 1.0 : 0.0;
                    // Resign
                    drawResignNewReset.y = buttonPosCount.z > 0.0 &&
                        all(int2(buttonPosCount.xy) == int2(1, 1)) ? 1.0 : 0.0;
                    // New game
                    drawResignNewReset.z = buttonPosCount.z > 0.0 &&
                        all(int2(buttonPosCount.xy) == int2(0, 0)) ? 1.0 : drawResignNewReset.z;
                    // Reset
                    drawResignNewReset.w = buttonPosCount.z > 0.0 &&
                        all(int2(buttonPosCount.xy) == int2(1, 0)) ? 1.0 : drawResignNewReset.w;

                    // New board
                    if (floor(turnWinUpdateLate.x) == 1)
                    {
                        curBoard[B_LEFT] = newBoard(B_LEFT);
                        curBoard[B_RIGHT] = newBoard(B_RIGHT);
                        curBoard[T_LEFT] = newBoard(T_LEFT);
                        curBoard[T_RIGHT] = newBoard(T_RIGHT);
                    }

                    // // Debug Stuff
                    // {
                    //     int2 pos = int2(floor(fmod(_Time.y * 4, 151)) * 2, floor(fmod(_Time.y * 4, 151)) * 2 + 1);
                    //     //int2 pos = int2(34, 35);
                    //     uint4 boardTop[2] = {
                    //         asuint(_BufferTex.Load(int3(pos.x, 231, 0))),
                    //         asuint(_BufferTex.Load(int3(pos.y, 231, 0)))
                    //     };
                    //     float score = eval(boardTop, turnWinUpdateLate.w);
                    //     buffer[0] = float4(score, pos.x, 231, 0);
                    // }

                    // If player resigned computer wins
                    turnWinUpdateLate.y = drawResignNewReset.y > 0.0 ?
                        BLACK : turnWinUpdateLate.y;

                    // Only accept draw if it's losing
                    if (drawResignNewReset.x > 0.0)
                    {
                        uint4 boardTop[2] = { curBoard[T_LEFT], curBoard[T_RIGHT] };
                        float score = eval(boardTop, turnWinUpdateLate.w);
                        turnWinUpdateLate.y = score > 0.0 ? DRAW_ACCEPT : DRAW_DECLINE;
                    }

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
                    moved.x = moved.x || (all(uint2(buf.x >> 4, buf.x & 0xf) == 
                        uint2(1, 5)) ? false : true);
                    moved.y = moved.y || (all(uint2(buf.y >> 4, buf.y & 0xf) == 
                        uint2(8, 5)) ? false : true);
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
                    for (int j = 0; j <= 24; j += 8) {
                        // There is a piece, position does not matter
                        uint4 bt = ((buf >> j) & 0xff);
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
                        const int MAX_KEEP = 10;
                        uint2 c = 0;
                        int2 bestBoards[MAX_KEEP]; // Keep 10 of the best
                        int2 bestMove = -1;
                        bestBoards[0] = -1;
                        float bestScore = FLT_MAX; // Minimize this

                        [unroll]
                        for (int i = txEvalArea.x; i <= txEvalArea.z; i++) {
                            float4 eOut = asfloat(_BufferTex.Load(int3(i, txEvalArea.y, 0)));
                            [flatten]
                            if ((eOut.x <= bestScore) && (eOut.x > FLT_MIN))
                            {
                                c.xy = eOut.x < bestScore ? 0..xx : c.xy;
                                bestBoards[c.x] = eOut.yz;
                                bestScore = eOut.x;
                                c.x = (c.x + 1) % MAX_KEEP;
                                c.y += 1;
                            }
                        }
                        uint ind = floor(hash11(c.y * timerLiftSeed.z)
                            * min(c.y, MAX_KEEP));
                        bestMove = bestBoards[ind].xy;

                        // Replace the current board
                        if (bestMove.x > -1) {

                            // Keep last board
                            uint4 boardHistory[2];
                            boardHistory[0] = curBoard[T_RIGHT];

                            // The y value corresponds to the parent board
                            bestMove.xy = int2(bestMove.y - 2, 0);
                            curBoard[B_LEFT] = LoadValueUint(_BufferTex, bestMove);
                            curBoard[B_RIGHT] = LoadValueUint(_BufferTex, bestMove + int2(1, 0));
                            curBoard[T_LEFT] = LoadValueUint(_BufferTex, bestMove + int2(0, 1));
                            curBoard[T_RIGHT] = LoadValueUint(_BufferTex, bestMove + int2(1, 1));
                        
                            // Highlight computer's move
                            boardHistory[1] = curBoard[T_RIGHT];
                            lastDest.xy = findComputerDest(boardHistory);
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
                        for (int i = 0; i < 24; i++) {
                            [unroll]
                            for (int j = 0; j < 24; j++) {
                                float d = _TouchTex.Load(int3(i, j, 0)).r;
                                touchPosCount.xy += d > 0.0 ? float2(i, j) : 0..xx;
                                touchPosCount.z += d > 0.0 ? 1.0 : 0.0;
                            }
                        }
                        touchPosCount.xy = floor(touchPosCount.xy /
                            max(touchPosCount.z, 1.) * 0.3333 + .3333);

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
                                timerLiftSeed.y = 0.0;
                            }
                        }
                        // Wait for nothing touching
                        else if (playerPosState.w == PSTATE_LIFT)
                        {
                            timerLiftSeed.y += unity_DeltaTime;
                            playerPosState.w = playerPosState.z < 1.0 &&
                                timerLiftSeed.y > 0.1 ?
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
                            if (validMove(board, playerSrcDest.xy, destPos, kingMoved))
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

                                // Next turn and reset player
                                turnWinUpdateLate.x += 1.0;
                                turnWinUpdateLate.z = 0.0;
                                playerSrcDest.xy = -1.0;
                                playerSrcDest.zw = destPos;
                                lastDest.xy = destPos;
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
                    StoreValueFloat(txTimerLiftSeed, timerLiftSeed, col, px);
                    StoreValueFloat(txPlayerSrcDest, playerSrcDest, col, px);
                    StoreValueFloat(txPlayerPosState, playerPosState, col, px);
                    StoreValueFloat(txTurnWinUpdateLate, turnWinUpdateLate, col, px);
                    StoreValueFloat(txDrawResignNewReset, drawResignNewReset, col, px);
                    StoreValueFloat(txButtonPos, buttonPos, col, px);
                    StoreValueFloat(txLastDest, lastDest, col, px);
                }
                // Generate all possible moves to a depth of 2
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
