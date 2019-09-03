using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class ShadowMapCamera : MonoBehaviour {
    public Shader shader;
    private Camera c;
    private void OnEnable() {
        c = GetComponent<Camera>();
        c.SetReplacementShader(shader, "");
        Shader.SetGlobalTexture("ShadowMapTexture", c.targetTexture);
    }

    private void Update() {
        Matrix4x4 worldToView = c.worldToCameraMatrix;
        Matrix4x4 projection = GL.GetGPUProjectionMatrix(c.projectionMatrix, false);
        Matrix4x4 SHADOW_MAP_VP = projection * worldToView;
        Shader.SetGlobalMatrix("SHADOW_MAP_VP", SHADOW_MAP_VP);
        Shader.SetGlobalVector("worldLightVector", transform.forward);
    }
}
