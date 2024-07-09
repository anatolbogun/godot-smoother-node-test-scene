# godot-smoother-node-test-scene
A simple Godot 4 project to test `_physics_process` smoothing interpolation via the [Godot Smoother Node](https://github.com/anatolbogun/godot-smoother-node).

This includes a simple 2d and 3d scene. The 2d scene is loosely based on [this Godot 3 tutorial](https://www.youtube.com/watch?v=Mc13Z2gboEk), ported to Godot 4 (but I approached a few things differently).

Simply add the `Smoother` node to a scene to interpolate node movements. See the above linked project for more details.

## Important Note!
Since Godot 4.3 Beta 1 you can find built-in physics interpolation for 2D in `Project settings > Physics > Common > Physics Interpolation`.
Physics interpolation for 3D is being worked on and should make it into a future release.
See the related [release notes](https://godotengine.org/article/dev-snapshot-godot-4-3-beta-1/#2d-physics-interpolation).

If you can use a Godot version with built-in physics interpolation, I _highly recommend_ using that and disabling this Smoother node or deleting it from your project.

This node was ever only intended as an interim solution until this is added natively to the engine. The built-in physics interpolation
also has better support for all node types such as `RigidBody2D` (which this node cannot handle).

Once native physics interpolation moves into stable builds, this Node will be deprecated, unless any pre-native-interpolation Godot 4 versions absolutely need an important fix.

--------------------------------

![godot-smoother-node-comparison](https://user-images.githubusercontent.com/7110246/209794022-6850cb5b-8be8-4fa8-a81f-7da4763b731b.gif)

Above: Not smoothed vs. smoothed.
