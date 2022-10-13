Shader "Maki/Some Overwatch Shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            // https://forum.unity.com/threads/2d-3d-4d-optimised-perlin-noise-cg-hlsl-library-cginc.218372
            // http://ctrl-alt-test.fr/minifier/index
            #define NOISE_SIMPLEX_1_DIV_289 0.00346020761245674740484429065744f
            float3 mod289(float3 x) { return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.; }
            float4 mod289(float4 x) { return x - floor(x * NOISE_SIMPLEX_1_DIV_289) * 289.; }
            float4 taylorInvSqrt(float4 r) { return 1.79284 - .853735 * r; }
            float4 permute(float4 x) { return mod289(x * x * 34. + x); }

            float snoise(float3 v)
            {
                const float2 C = float2(.166667, .333333);
                const float4 D = float4(0., .5, 1., 2.);
                float3 i = floor(v + dot(v, C.ggg)), x0 = v - i + dot(i, C.rrr), g = step(x0.gbr, x0.rgb), l = 1 - g, i1
                           = min(g.rgb, l.brg), i2 = max(g.rgb, l.brg), x1 = x0 - i1 + C.rrr, x2 = x0 - i2 + C.ggg, x3 =
                           x0 - D.ggg;
                i = mod289(i);
                float4 p = permute(
                    permute(permute(i.b + float4(0., i1.b, i2.b, 1.)) + i.g + float4(0., i1.g, i2.g, 1.)) + i.r +
                    float4(0., i1.r, i2.r, 1.));
                float n_ = .142857;
                float3 ns = n_ * D.agb - D.rbr;
                float4 j = p - 49. * floor(p * ns.b * ns.b), x_ = floor(j * ns.b), y_ = floor(j - 7. * x_), x = x_ * ns.
                           r + ns.gggg, y = y_ * ns.r + ns.gggg, h = 1. - abs(x) - abs(y), b0 = float4(x.rg, y.rg), b1 =
                           float4(x.ba, y.ba), s0 = floor(b0) * 2. + 1., s1 = floor(b1) * 2. + 1., sh = -step(h, 0.), a0
                           = b0.rbga + s0.rbga * sh.rrgg, a1 = b1.rbga + s1.rbga * sh.bbaa;
                float3 p0 = float3(a0.rg, h.r), p1 = float3(a0.ba, h.g), p2 = float3(a1.rg, h.b), p3 = float3(
                           a1.ba, h.a);
                float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
                p0 *= norm.r;
                p1 *= norm.g;
                p2 *= norm.b;
                p3 *= norm.a;
                float4 m = max(.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.);
                m = m * m;
                return 42. * dot(m * m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
            }

            #define mod(x,y) (x-y*floor(x/y))

            float3 HSVtoRGB(float3 hsv)
            {
                // thx shaderforge <3~
                return (lerp(float3(1, 1, 1),
                             saturate(3.0 * abs(1.0 - 2.0 * frac(hsv.r + float3(0.0, -1.0 / 3.0, 1.0 / 3.0))) - 1),
                             hsv.g) * hsv.b);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv * float2(2, 1);

                float2 bigCirclesUv = uv;
                bigCirclesUv *= 8;
                bigCirclesUv = mod(bigCirclesUv, 1.0);
                bigCirclesUv -= 0.5;

                float2 smallCirclesUv = uv;
                smallCirclesUv *= 48;
                smallCirclesUv.y -= _Time.y * 4;
                smallCirclesUv = mod(smallCirclesUv, 1.0);
                smallCirclesUv -= 0.5;

                float bigCircles = abs(distance(bigCirclesUv, 0));
                bigCircles = bigCircles > 0.46 ? 0 : 1;

                float smallCircles = abs(distance(smallCirclesUv, 0));
                smallCircles = smallCircles > 0.44 ? 0 : 1;

                float2 patternUv = uv;
                patternUv *= 2;

                float pattern = snoise(float3(patternUv, _Time.y * 0.2)) / 2 + 0.5;


                float3 color = float3(1, 1, 1);

                if (smallCircles > 0.5 && bigCircles > 0.5)
                {
                    color = HSVtoRGB(
                        float3(
                            lerp(0.4, 10, pattern),
                            0.6,
                            1
                            // lerp(0.6, 1, pattern)
                        )
                    );
                    color = pow(color, 2.2);
                }

                fixed4 outputColor = fixed4(color, 1);
                UNITY_APPLY_FOG(i.fogCoord, outputColor);
                return outputColor;
            }
            ENDCG
        }
    }
}
