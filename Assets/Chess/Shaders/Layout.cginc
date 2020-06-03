#ifndef _LAYOUT
#define _LAYOUT

#define txCurBoardBL                    int2(0, 510)
#define txCurBoardBR                    int2(1, 510)
#define txCurBoardTL                    int2(0, 511)
#define txCurBoardTR                    int2(1, 511)
#define txTurnWinUpdateLate             int2(2, 511)
#define txKingMoved                     int2(3, 511)
#define txTimer                         int2(4, 511)
#define txPlayerSrcDest                 int2(5, 511)
#define txPlayerPosState                int2(6, 511)
#define txEvalArea                      int4(362, 511, 511, 511)

// States for extracting touch input
#define PSTATE_SRC         0
#define PSTATE_LIFT        1    // Wait for no touch
#define PSTATE_DEST        2    // Then accept next input

// x, y dimensions of set of board group generated per board
// z, w dimensions of all boards combined
#define boardParams        float4(298, 2, 298, 300)

// Number of rows we update each frame
static const int boardDiv = floor(boardParams.x / 5.0);

// Index of texture area to update per frame
static const int boardUpdate[7] = 
{
    0,
    2,
    boardDiv + 2,
    boardDiv * 2 + 2,
    boardDiv * 3 + 2,
    boardDiv * 4 + 2,
    boardDiv * 5 + 2
};

// Move count table for branching
static const uint2 moveNum[7] =
{
    // Total    Cumulative
    0,          0,      // Nothing
    32,         32,     // Pawns
    16,         48,     // Knights
    30,         78,     // Bishops
    32,         110,    // Rooks
    31,         141,    // Queen
    8,          149     // King
};

inline uint4 LoadValueUint( in Texture2D<float4> tex, in int2 re )
{
    return asuint(tex.Load(int3(re, 0)));
}

inline void StoreValueUint( in int2 txPos, in uint4 value, inout uint4 col,
    in int2 fragPos )
{
    col = all(fragPos == txPos) ? value : col;
}

inline float4 LoadValueFloat( in Texture2D<float4> tex, in int2 re )
{
    return asfloat(tex.Load(int3(re, 0)));
}

inline void StoreValueFloat( in int2 txPos, in float4 value, inout uint4 col,
    in int2 fragPos )
{
    col = all(fragPos == txPos) ? asuint(value) : col;
}

// Hash without sine
// https://www.shadertoy.com/view/4djSRW

float hash11(float p)
{
    p = frac(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

#endif