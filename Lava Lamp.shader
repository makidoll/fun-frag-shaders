Shader "Maki/Lava Lamp" {
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

			#include "noiseSimplex.cginc"

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
			};

			struct fragOut {
				float4 color: SV_Target;
				//float depth: SV_Blobdepth;
			};

			v2f vert (appdata v) {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}

			float3 HSVtoRGB(float3 hsv) {
				// thx shaderforge <3~
				return (lerp(float3(1,1,1),saturate(3.0*abs(1.0-2.0*frac(hsv.r+float3(0.0,-1.0/3.0,1.0/3.0)))-1),hsv.g)*hsv.b);
			}

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
				return f;
			}
			ENDCG
		}
	}
}
