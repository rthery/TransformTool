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
	
	import flash.events.Event;
	
	/**
	 * Draws a border around the local coordinate space of the target object.
	 * ControlBorder styling does not support fill styles.
	 * @author Trevor McCauley
	 */
	public class ControlBorder extends Control {
		
		/**
		 * Constructor for creating new ControlBorder instances.
		 */
		public function ControlBorder(){
			mouseEnabled = false;
			super();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function draw():void {
			super.draw();
			redraw(null);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function redraw(event:Event):void {
			super.redraw(event);
			
			var tool:TransformTool = this.tool;
			if (tool == null){
				return;
			}
			
			with (graphics){
				clear();
				lineStyle(this.lineThickness, this.lineColor, this.lineAlpha);
				moveTo(tool.topLeft.x, tool.topLeft.y);
				lineTo(tool.topRight.x, tool.topRight.y);
				lineTo(tool.bottomRight.x, tool.bottomRight.y);
				lineTo(tool.bottomLeft.x, tool.bottomLeft.y);
				lineTo(tool.topLeft.x, tool.topLeft.y);
			}
		}
	}
}