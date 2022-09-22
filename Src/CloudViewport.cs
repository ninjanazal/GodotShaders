using Godot;
using System;

namespace GoShaders
{
#if TOOLS
	[Tool]
#endif
	public class CloudViewport : MeshInstance
	{
		private ShaderMaterial _material;
		public override void _EnterTree()
		{
			_material = (ShaderMaterial)GetActiveMaterial(0);
			_material.SetShaderParam("onEditor", 1 - (2 * Convert.ToInt16(Engine.EditorHint)));
		}
		public void UpdateBounds((Vector3, Vector3) bounds)
		{
			GD.Print("Updating bounds");
			_material.SetShaderParam("boundsMin", bounds.Item1);
			_material.SetShaderParam("boundsMax", bounds.Item2);
		}

	}
}
