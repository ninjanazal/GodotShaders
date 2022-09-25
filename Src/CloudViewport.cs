using Godot;
using System;

namespace GoShaders
{
#if TOOLS
	[Tool]
#endif
	public class CloudViewport : MeshInstance
	{
		private uint _noiseLayer = 5;

		private Godot.RandomNumberGenerator _rnad = new RandomNumberGenerator();
		private OpenSimplexNoise _noise;
		private Texture3D _texture3D;

		private ShaderMaterial _material;
		public override void _EnterTree()
		{
			_texture3D = new Texture3D();
			_texture3D.Create(5, 5, _noiseLayer, Image.Format.L8, 0);

			_noise = new OpenSimplexNoise();
			for (int i = 0; i < _noiseLayer; i++) {
				_rnad.Randomize();
				_noise.Seed = (int)_rnad.Randi();
				_noise.Octaves = 4;
				_noise.Period = 20.0f;
				_noise.Persistence = 0.8f;
				_texture3D.SetLayerData(_noise.GetImage(5, 5), i);
			}

			_material = (ShaderMaterial)GetActiveMaterial(0);
			//_material.SetShaderParam("shapeNoise", _texture3D);

		}
		public void UpdateBounds((Vector3, Vector3) bounds)
		{
			_material.SetShaderParam("boundsMin", bounds.Item1);
			_material.SetShaderParam("boundsMax", bounds.Item2);
		}

	}
}
