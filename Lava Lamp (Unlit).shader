Shader "Maki/Lava Lamp (Unlit)" {
	Properties {
		_BlobScale ("Blob Scale", Range (0.1, 8)) = 1
		_BlobDepth ("Blob Depth", Range (2, 16)) = 4
		_BlobSaturation ("Blob Saturation", Range(0,1)) = 0.8
		_BlobValue ("Blob Value", Range(0,1)) = 0.4
		_BlobMoveSpeed ("Blob Movement Speed", Float) = 4

		_HueSpeed ("Hue Speed", Float) = 1
		_HueScale ("Hue Scale", Float) = 2
		[HDR]_Background ("Background", Color) = (0,0,0,1)
	}
	SubShader {
		Pass {
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			uniform float _BlobScale;
			uniform float _BlobDepth;
			uniform float _BlobSaturation;
			uniform float _BlobValue;
			uniform float _BlobMoveSpeed;

			uniform float _HueSpeed;
			uniform float _HueScale;
			uniform float4 _Background;

			struct appdata {
				float4 vertex: POSITION;
				float2 uv: TEXCOORD0;
			};

			struct v2f {
				float4 vertex: SV_POSITION;
				float4 posWorld: TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct fragOut {
				float4 color: SV_Target;
				//float depth: SV_Blobdepth;
				UNITY_FOG_COORDS(1)
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert (appdata v) {
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f, o)
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			float3 HSVtoRGB(float3 hsv) {
				// thx shaderforge <3~
				return (lerp(float3(1,1,1),saturate(3.0*abs(1.0-2.0*frac(hsv.r+float3(0.0,-1.0/3.0,1.0/3.0)))-1),hsv.g)*hsv.b);
			}

			// https://forum.unity.com/threads/2d-3d-4d-optimised-perlin-noise-cg-hlsl-library-cginc.218372
			// http://ctrl-alt-test.fr/minifier/index
			#define NOISE_SIMPLEX_1_DIV_289 0.00346020761245674740484429065744f
			float3 mod289(float3 x){return x-floor(x*NOISE_SIMPLEX_1_DIV_289)*289.;}float4 mod289(float4 x){return x-floor(x*NOISE_SIMPLEX_1_DIV_289)*289.;}float4 taylorInvSqrt(float4 r){return 1.79284-.853735*r;}float4 permute(float4 x){return mod289(x*x*34.+x);}float snoise(float3 v){const float2 C=float2(.166667,.333333);const float4 D=float4(0.,.5,1.,2.);float3 i=floor(v+dot(v,C.ggg)),x0=v-i+dot(i,C.rrr),g=step(x0.gbr,x0.rgb),l=1-g,i1=min(g.rgb,l.brg),i2=max(g.rgb,l.brg),x1=x0-i1+C.rrr,x2=x0-i2+C.ggg,x3=x0-D.ggg;i=mod289(i);float4 p=permute(permute(permute(i.b+float4(0.,i1.b,i2.b,1.))+i.g+float4(0.,i1.g,i2.g,1.))+i.r+float4(0.,i1.r,i2.r,1.));float n_=.142857;float3 ns=n_*D.agb-D.rbr;float4 j=p-49.*floor(p*ns.b*ns.b),x_=floor(j*ns.b),y_=floor(j-7.*x_),x=x_*ns.r+ns.gggg,y=y_*ns.r+ns.gggg,h=1.-abs(x)-abs(y),b0=float4(x.rg,y.rg),b1=float4(x.ba,y.ba),s0=floor(b0)*2.+1.,s1=floor(b1)*2.+1.,sh=-step(h,0.),a0=b0.rbga+s0.rbga*sh.rrgg,a1=b1.rbga+s1.rbga*sh.bbaa;float3 p0=float3(a0.rg,h.r),p1=float3(a0.ba,h.g),p2=float3(a1.rg,h.b),p3=float3(a1.ba,h.a);float4 norm=taylorInvSqrt(float4(dot(p0,p0),dot(p1,p1),dot(p2,p2),dot(p3,p3)));p0*=norm.r;p1*=norm.g;p2*=norm.b;p3*=norm.a;float4 m=max(.6-float4(dot(x0,x0),dot(x1,x1),dot(x2,x2),dot(x3,x3)),0.);m=m*m;return 42.*dot(m*m,float4(dot(p0,x0),dot(p1,x1),dot(p2,x2),dot(p3,x3)));}

			void raymarch (float3 rayOrigin, float3 rayDir, out float4 color) {
				color = _Background;

				float3 position = float3(0,_Time.x*_BlobMoveSpeed,0)-(mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz);

				float rayStep = 0.04*_BlobScale;
				float3 rayPos = rayOrigin+position;
				for (float i=0; i<_BlobDepth; i+=rayStep) {
					rayPos += rayDir*rayStep;

					float dist = snoise(rayPos*_BlobScale);
					float c = length((rayOrigin-rayPos)+position);

					//if (dist>0.5 && c>1) {
					if (dist>0.5) {
						float3 col = HSVtoRGB(float3( (
								(-rayPos.y*_HueScale*0.1) + ((0.2+_Time.x)*_HueSpeed*3)
							)%1,
							_BlobSaturation, _BlobValue
						));

						c = _BlobDepth-c;
						color = float4(lerp(_Background, col, c), 1);
						break;
					}
				}

				//float4 clipPos = mul(UNITY_MATRIX_VP, float4(rayPos, 1.0));
				//clipDepth = clipPos.z / clipPos.w;
			}

			fragOut frag(v2f i) {
				float3 rayOrigin = i.posWorld.xyz;
				float3 rayDir = normalize(rayOrigin-_WorldSpaceCameraPos);
				float4 color;
				//float clipDepth;
				raymarch(rayOrigin, rayDir, color);

				fragOut f;
				//f.depth = clipDepth;
				f.color = color;
				UNITY_APPLY_FOG(i.fogCoord, color);
				return f;
			}
			ENDCG
		}
	}
}
