/*
Copyright (c) 2010 Trevor McCauley

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 
*/
package com.senocular.display.transform {
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Base class for controls using UV positioning. UV positioning uses
	 * percentages to position a control within the coordinate space of
	 * the target object. U values represent position in the x axis. V values
	 * represent position in the y axis. A U of 0 indicates a position at the 
	 * far left of a target object's bounding box and 1 at the far right. For
	 * V, 0 is the top and 1 is the bottom.
	 * @author Trevor McCauley
	 */
	public class ControlUV extends ControlInteractive {
		
		/**
		 * The U value in the UV positioning used by the
		 * Control object. This representes a percentage
		 * along the width of the target used in determining
		 * the x location of the control. A value of 0 
		 * positions the control at the left edge of the target
		 * while a value of 1 positions at the right edge.
		 */
		public function get u():Number {
			return _u;
		}
		public function set u(value:Number):void {
			_u = isNaN(value) ? 0 : value;
		}
		private var _u:Number;
		
		/**
		 * The V value in the UV positioning used by the
		 * Control object. This representes a percentage
		 * along the height of the target used in determining
		 * the y location of the control. A value of 0 
		 * positions the control at the top edge of the target
		 * while a value of 1 positions at the bottom edge.
		 */
		public function get v():Number {
			return _v;
		}
		public function set v(value:Number):void {
			_v = isNaN(value) ? 0 : value;
		}
		private var _v:Number;
		
		/**
		 * A pixel-based offset (not percentage) for additional 
		 * positioning for the control on top of UV positioning.
		 */
		public function get offset():Point {
			return _offset;
		}
		public function set offset(value:Point):void {
			_offset = value;
		}
		private var _offset:Point;
		
		/**
		 * Constructor for creating new ControlUV instances.
		 * @param	u The U value for positioning the control in the x axis.
		 * @param	v The V value for positioning the control in the y axis.
		 * @param	cursor The cursor to be used while interacting with the
		 * control instance. 
		 */
		public function ControlUV(u:Number = 0, v:Number = 0, cursor:Cursor = null){
			super(cursor);
			this.u = u;
			this.v = v;
		}
		
		/**
		 * Returns the position of the control within the coordinate space of 
		 * the Transform Tool for the current target object given values for
		 * UV and offsets.  If the control is not within a TransformTool
		 * instance, or the Transform Tool does not have a target, a Point with
		 * the locations (0,0) is returned.
		 * @param	u The U value for positioning the control in the x axis. If
		 * not specified, the u value of this instance is used.
		 * @param	v The V value for positioning the control in the y axis. If
		 * not specified, the v value of this instance is used.
		 * @param	offset A pixel-based offset for positioning in the x axis. 
		 * If not specified, the offset value of this instance is used.
		 * @return A Point object indicating the position of the control.
		 */
		public function getUVPosition(u:Number = NaN, v:Number = NaN, offset:Point = null):Point {
			
			var tool:TransformTool = this.tool;
			if (tool == null || tool.target == null){
				return new Point(0, 0);
			}
			
			// use this instance's values if not
			// provided in the argument list
			if (isNaN(u)){
				u = _u;
			}
			if (isNaN(v)){
				v = _v;
			}
			if (offset == null){
				offset = _offset;
			}
			
			// transform the local positions into tool
			// positions
			var position:Point = getLocalUVPosition(u, v, tool.target);
			position = tool.calculatedMatrix.transformPoint(position);
			
			// apply offset
			if (offset){
				var angle:Number;
				if (!isNaN(offset.x)){
					angle = tool.getRotationX();
					position.x += offset.x * Math.cos(angle);
					position.y += offset.x * Math.sin(angle);
				}
				if (!isNaN(offset.y)){
					angle = tool.getRotationY();
					position.x += offset.y * Math.sin(angle);
					position.y += offset.y * Math.cos(angle);
				}
			}
			
			return position;
		}
		
		/**
		 * Returns the UV position within the local coordinate space of a
		 * target DisplayObject instance.
		 * @param	u The U value for positioning the control in the x axis.
		 * @param	v The V value for positioning the control in the y axis.
		 * @param	target A DisplayObject to find a UV position in.
		 * @return A Point indicating the position within 
		 */
		public function getLocalUVPosition(u:Number, v:Number, target:DisplayObject):Point {
			if (target == null){
				return new Point(0, 0);
			}
			
			var bounds:Rectangle = target.getBounds(target);
			return new Point(bounds.left + bounds.width * u, bounds.top + bounds.height * v);
		}
		
		/**
		 * Sets the position of the control to the current location returned
		 * by getUVPosition.
		 */
		protected function setPosition():void {
			var position:Point = getUVPosition();
			x = position.x;
			y = position.y;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function redraw(event:Event):void {
			super.redraw(event);
			setPosition();
		}
	}
}