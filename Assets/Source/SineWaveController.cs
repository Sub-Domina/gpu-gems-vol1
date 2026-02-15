using UnityEngine;

public class SineWaveController : MonoBehaviour
{
    private static int wavelengthId = Shader.PropertyToID("_Wavelength");
    private static int phaseConstantId = Shader.PropertyToID("_PhaseConstant");
    private static int simulationTimeId = Shader.PropertyToID("_SimulationTime");
    private static int directionId = Shader.PropertyToID("_Direction");

    [SerializeField] private Material material;
    [SerializeField] private float speed;
    [SerializeField] private float wavelength;
    [SerializeField, Range(0f, 360f)] private float rotation;

    private void Update()
    {
        material.SetFloat(wavelengthId, wavelength);
        material.SetFloat(phaseConstantId, speed * 2f / wavelength);
        material.SetFloat(simulationTimeId, Time.time);
        material.SetVector(directionId, GetDirection(rotation));
    }

    private Vector2 GetDirection(float degrees)
    {
        float radians = Mathf.Deg2Rad * degrees;
        float sine = Mathf.Sin(radians);
        float cosine = Mathf.Cos(radians);
        return new Vector2(-sine, cosine);
    }
}
