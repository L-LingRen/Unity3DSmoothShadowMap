Shader "Hidden/ShadowMap" {
    Properties {
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        /**/
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f {
                float4 vertex : POSITION;
                float2 depth: TEXCOORD1;
            };

            float3 worldLightVector;

            v2f vert(appdata_base v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.depth = o.vertex.zw;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                //discard;
                float depth = i.depth.x / i.depth.y;
                return EncodeFloatRGBA(depth);
            }
            ENDCG
        }

        /*
        */
        // 单独平滑明暗边界，可和上述Pass合并。
        Pass {
            //ZTest Always
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geo

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2g {
                float4 vertex : POSITION;
				float4 normal : NORMAL;
                int    isVisible : TEXCOORD0;
            };

            struct g2f {
                float4 vertex : SV_POSITION;
                float depth : TEXCOORD0;
            };

            struct SilhouetteVertex {
                float3 position;
                float3 normal;
            };

            float3 worldLightVector;

            SilhouetteVertex computeSilhouetteVertex(v2g point1, v2g point2, float3 viewDir) {                
                float3 V1 = point1.vertex.xyz;
                float3 V2 = point2.vertex.xyz;

                float3 N1 = point1.normal.xyz;
                float3 N2 = point2.normal.xyz;

                float3 T1 = (V2 - V1) - dot(V2 - V1, N1) * N1;
                float3 T2 = (V2 - V1) - dot(V2 - V1, N2) * N2;

                float3 D = viewDir;

                SilhouetteVertex result;
                //计算出平行光的u0，并保存在result.w中。 
                float u0 = dot(D, N1) / (dot(D, N1) - dot(D, N2));
                //计算出S(u)和N(u) u=u0的结果，并保存在result中。
                result.position = (2 * V1 - 2 * V2 + T1 + T2) * u0 * u0 * u0 - (3 * V1 - 3 * V2 + 2 * T1 + T2) * u0 * u0 + T1 * u0 + V1;
				result.normal = normalize((1 - u0) * N1 + u0 * N2);

                return result;
            }

            v2g vert (appdata v) {
                v2g o;
                o.vertex = mul(unity_ObjectToWorld, v.vertex);
				o.normal = float4(mul((float3x3)unity_ObjectToWorld, v.normal), 0);
				o.isVisible = step(0, dot(worldLightVector, o.normal.xyz));
                return o;
            }

            [maxvertexcount(6)]
            void geo(triangle v2g input[3], inout TriangleStream<g2f> stream) {
                g2f o;

                int vertexFlag1 = input[0].isVisible;
                int vertexFlag2 = input[1].isVisible;
                int vertexFlag3 = input[2].isVisible;
                int flag = vertexFlag1 + vertexFlag2 + vertexFlag3;

                if (flag == 0 || flag == 3) {
                    return;
                }

                SilhouetteVertex S1, S2;
                if (vertexFlag1 == 1 && vertexFlag2 == 0 && vertexFlag3 == 1) {
                    S1 = computeSilhouetteVertex(input[1], input[2], worldLightVector);
                    S2 = computeSilhouetteVertex(input[1], input[0], worldLightVector);
                } else if (vertexFlag1 == 0 && vertexFlag2 == 1 && vertexFlag3 == 0) {
                    S1 = computeSilhouetteVertex(input[1], input[0], worldLightVector);
                    S2 = computeSilhouetteVertex(input[1], input[2], worldLightVector);
                } else if (vertexFlag1 == 1 && vertexFlag2 == 1 && vertexFlag3 == 0) {
                    S1 = computeSilhouetteVertex(input[2], input[0], worldLightVector);
                    S2 = computeSilhouetteVertex(input[2], input[1], worldLightVector);
                } else if (vertexFlag1 == 0 && vertexFlag2 == 0 && vertexFlag3 == 1) {
                    S1 = computeSilhouetteVertex(input[2], input[1], worldLightVector);
                    S2 = computeSilhouetteVertex(input[2], input[0], worldLightVector);
                } else if (vertexFlag1 == 0 && vertexFlag2 == 1 && vertexFlag3 == 1) {
                    S1 = computeSilhouetteVertex(input[0], input[1], worldLightVector);
                    S2 = computeSilhouetteVertex(input[0], input[2], worldLightVector);
                } else {
                    S1 = computeSilhouetteVertex(input[0], input[2], worldLightVector);
                    S2 = computeSilhouetteVertex(input[0], input[1], worldLightVector);
                }

                float outDiff = 0.002;
                float inDiff = 0.005;

                float4 v0 = float4(S1.position - S1.normal * inDiff, 1);
                float4 v1 = float4(S1.position + S1.normal * outDiff, 1);
                float4 v2 = float4(S2.position - S2.normal * inDiff, 1);
                float4 v3 = float4(S2.position + S2.normal * outDiff, 1);

                v0 = mul(UNITY_MATRIX_VP, v0);
                v1 = mul(UNITY_MATRIX_VP, v1);
                v2 = mul(UNITY_MATRIX_VP, v2);
                v3 = mul(UNITY_MATRIX_VP, v3);

                v0 /= v0.w;
                v1 /= v1.w;
                v2 /= v2.w;
                v3 /= v3.w;

                float v0z = v0.z;
                float v1z = v1.z;
                float v2z = v2.z;
                float v3z = v3.z;

                v0.z += 0.005;
                v1.z += 0.005;
                v2.z += 0.005;
                v3.z += 0.005;

                o.vertex = v3;
                o.depth = v3z;
                stream.Append(o);
                o.vertex = v2;
                o.depth = v2z;
                stream.Append(o);
                o.vertex = v0;
                o.depth = v0z;
                stream.Append(o);
                stream.RestartStrip();

                o.vertex = v0;
                o.depth = v0z;
                stream.Append(o);
                o.vertex = v1;
                o.depth = v1z;
                stream.Append(o);
                o.vertex = v3;
                o.depth = v3z;
                stream.Append(o);
                stream.RestartStrip();
            }

            fixed4 frag(g2f i) : SV_Target{
                return EncodeFloatRGBA(i.depth);
            }
            ENDCG
        }
    }
}
