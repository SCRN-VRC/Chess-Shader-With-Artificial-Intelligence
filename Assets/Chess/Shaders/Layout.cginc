#ifndef _LAYOUT
#define _LAYOUT

#define txCurBoardBL                    int2(0, 510)
#define txCurBoardBR                    int2(1, 510)
#define txCurBoardTL                    int2(0, 511)
#define txCurBoardTR                    int2(1, 511)
#define txTurnWinUpdateLate             int2(2, 511)
#define txKingMoved                     int2(3, 511)
#define txTimerLiftSeed                 int2(4, 511)
#define txPlayerSrcDest                 int2(5, 511)
#define txPlayerPosState                int2(6, 511)
#define txDrawResignNewReset            int2(7, 511)
#define txButtonPos                     int2(8, 511)
#define txLastDest                      int2(9, 511)
#define txVRCBotState                   int2(10, 511)
#define txEvalArea                      int4(360, 511, 511, 511)

// States for extracting touch input
#define PSTATE_SRC         0
#define PSTATE_LIFT        1    // Wait for no touch
#define PSTATE_DEST        2    // Then accept next input

#define DRAW_DECLINE      -2
#define DRAW_ACCEPT        2

// x, y dimensions of set of board group generated per board
// z, w dimensions of all boards combined
#define boardParams        float4(302, 2, 302, 304)

// VRCBot States
#define BOT_IDLE           0
#define BOT_PLAY           1
#define BOT_WIN            2
#define BOT_LOSE           3

// Response Animations
#define BOT_NONE           0
#define BOT_NO             1

// Number of rows we update each frame
static const int boardDiv = 62;

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
    10,         151     // King
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

float4 HueShift (in float3 Color, in float Shift)
{
    float3 P = float3(0.55735, 0.55735, 0.55735)*
        dot(float3(0.55735,0.55735,0.55735),Color);
    float3 U = Color-P;
    float3 V = cross(float3(0.55735,0.55735,0.55735),U);    
    Color = U*cos(Shift*6.2832) + V*sin(Shift*6.2832) + P;
    return float4(Color,1.0);
}

float attenUV (float lightAtten0, float3 LightPos5, float3 worldPos) {
    float range = (0.005 * sqrt(1000000.0 - lightAtten0)) / sqrt(lightAtten0);
    return distance(LightPos5, worldPos) / range;
}

float attenFunc (float attenUV) {
    return saturate(1.0 / (1.0 + 25.0 * attenUV * attenUV) * saturate((1.0 - attenUV) * 5.0));
}

#endif