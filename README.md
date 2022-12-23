# godot-smoother-node-test-scene
A simple Godot 4 project to test `_physics_process` smoothing interpolation via the [Godot Smoother Node](https://github.com/anatolbogun/godot-smoother-node).

This includes a simple 2d and 3d scene. The 2d scene is loosely based on [this Godot 3 tutorial](https://www.youtube.com/watch?v=Mc13Z2gboEk), ported to Godot 4 (but I approached a few things differently).

Simply add the `Smoother` node to a scene to interpolate node movements. See the above linked project for more details.

![godot-smoother-node-comparison](https://user-images.githubusercontent.com/7110246/209285560-20b98559-5859-4fed-818e-f16ebcce0a40.gif)
Above: Not smoothed vs. smoothed (player movements are not synced, these are 2 separate runs).
