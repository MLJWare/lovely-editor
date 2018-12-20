# Controls

* right click to get a context sensitive menu.

* When holding shift;
  * left mouse button to drag a single view,
  * middle mouse button to drag all non-anchored views around, and
  * right mouse button to toggle whether a view is anchored.

* The behavior of the mouse wheel depends on whether you're currently dragging a view:
  * if no view is being dragged, it allows you to zoom in/out on all non-anchored views,
  * otherwise, you scale the view being dragged.

As for undo/redo;
* you undo using ctrl+z, and
* you redo using ctrl+shift+z.(edited)
(Undo/redo only works on Pixel Frames, and only if they own the data, i.e. not if it's receiving it from a connection/link/wire.)

To make connections, hold shift, then click on an output (pins on the right side of a view), and drag it to an input (pins on the left side of a view).

If you get lost, you can use shift+home to reset the offset to the original position, and you can use shift+enter to reset the scale to 1.