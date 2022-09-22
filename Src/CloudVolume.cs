using Godot;
using System;

namespace GoShaders
{
#if TOOLS
	[Tool]
#endif
	public class CloudVolume : Spatial
	{
		private (Vector3, Vector3) _bounds;
		private BoxShape _cloudVolumeShape;

		private CloudViewport _cloudView;

		public override void _Ready()
		{
			_cloudView = GetNode<CloudViewport>("%CamView");
			_cloudVolumeShape = (BoxShape)GetChild<CollisionShape>(0).Shape;
			GetBounds();
			_cloudView.UpdateBounds(_bounds);
		}
		public override void _PhysicsProcess(float delta)
		{
			var oldBounds = _bounds;
			GetBounds();
			if (oldBounds != _bounds)
			{
				_cloudView.UpdateBounds(_bounds);
			}
		}
		private void GetBounds()
		{
			_bounds.Item1 = GlobalTransform.origin +
				(GlobalTransform.basis.x * _cloudVolumeShape.Extents.x) +
				(-GlobalTransform.basis.y * _cloudVolumeShape.Extents.y) +
				(-GlobalTransform.basis.z * _cloudVolumeShape.Extents.z);
			_bounds.Item2 = GlobalTransform.origin +
				(-GlobalTransform.basis.x * _cloudVolumeShape.Extents.x) +
				(GlobalTransform.basis.y * _cloudVolumeShape.Extents.y) +
				(GlobalTransform.basis.z * _cloudVolumeShape.Extents.z);
		}
	}
}