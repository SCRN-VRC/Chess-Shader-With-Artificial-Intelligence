#ifndef _LAYOUT
#define _LAYOUT

#define txCurBoardBL       int2(0, 510)
#define txCurBoardBR       int2(1, 510)
#define txCurBoardTL       int2(0, 511)
#define txCurBoardTR       int2(1, 511)
#define txTurnWinUpdate    int2(2, 511)

// x, y dimensions of set of board group generated per board
// z, w dimensions of all boards combined
#define boardParams        float4(300, 2, 300, 302)

static const int boardDiv = floor(boardParams.x / 5.0);

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
    9,          150     // King
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

#endif