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
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	/**
	 * Displays control cursors within the TransformTool instance. 
	 * ControlCursor instances are non-interactive controls that display the 
	 * cursors of other controls.  You would generally place a ControlCursor
	 * instance at the end of a controls list in a control set so that it
	 * will appear on top of other controls. If not using a ControlCursor
	 * control, you will need to manage cursors manually using the 
	 * TransformTool.CURSOR_CHANGED event if you want cursors to appear for
	 * the Transform Tool.
	 * @author Trevor McCauley
	 */
	public class ControlCursor extends Sprite {
		
		/**
		 * A reference to the TransformTool instance the control was placed,
		 * defined in the ADDED_TO_STAGE event.  The control must be a direct
		 * child of a TransformTool instance for it to be recognized.
		 */
		public function get tool():TransformTool {
			return _tool;
		}
		public function set tool(value:TransformTool):void {
			if (value == _tool){
				return;
			}
			
			if (_tool){
				_tool.removeEventListener(TransformTool.CURSOR_CHANGED, cursorChanged);
				_tool.removeEventListener(TransformTool.TARGET_CHANGED, targetChanged);
			}
			_tool = value;
			if (_tool){
				_tool.addEventListener(TransformTool.CURSOR_CHANGED, cursorChanged);
				_tool.addEventListener(TransformTool.TARGET_CHANGED, targetChanged);
			}
		}
		private var _tool:TransformTool;
		
		/**
		 * An offset from the mouse position to display cursor objects. The
		 * default offset places the cursor to the lower right of a standard
		 * cursor. If TransformTool.cursorHidesMouse is true, you will likely
		 * want to change this to (0,0) so that cursors are centered on the
		 * mouse position when used.
		 */
		public function get offset():Point {
			return _offset;
		}
		public function set offset(value:Point):void {
			_offset = value;
		}
		private var _offset:Point = new Point(20, 28);
		
		/**
		 * The current cursor being displayed by this control. Do not confuse
		 * this with the cursor property used by other controls that determine
		 * what cursor is used when those controls are interacted with. The
		 * value of this cursor changes as the Transform Tool is supplied new
		 * cursors and dispatches TransformTool.CURSOR_CHANGED events.
		 */
		protected function get cursor():DisplayObject {
			return _cursor;
		}
		protected function set cursor(value:DisplayObject):void {
			if (value == _cursor){
				return;
			}
			
			cleanupCursor();
			_cursor = value;
			setupCursor();
		}
		private var _cursor:DisplayObject;
		
		/**
		 * Setup steps when defining a new cursor value. You may need to 
		 * override this method to control the order of operations when
		 * adding content to the set cursor setter. This is called after
		 * a new cursor value is set.
		 */
		protected function setupCursor():void {
			
			if (_cursor){
				addChild(_cursor);
				setupActiveMouse();
				
				var cursorEvent:MouseEvent = _tool.cursorEvent as MouseEvent;
				if (cursorEvent){
					activeMouseMove(cursorEvent);
				}
				
			}else{
				cleanupActiveMouse();
			}
		}
		
		/**
		 * Cleanup steps when defining a new cursor value. You may need to 
		 * override this method to control the order of operations when
		 * adding content to the set cursor setter.  This is called before
		 * a new cursor value is set.
		 */
		protected function cleanupCursor():void {
			if (_cursor && cursor.parent == this){
				removeChild(_cursor);
			}
		}
		
		/**
		 * The object from which mouse events are consumed. This would normally
		 * be the stage instance, but root may be used if stage is not allowed.
		 */
		protected var activeTarget:IEventDispatcher;
		
		/**
		 * Determines whether or not mouse positions are being tracked.
		 */
		protected var mouseActive:Boolean = false;
		
		/**
		 * Constructor for creating new ControlCursor instances.
		 * @param	offset An offset from the mouse position to display cursor
		 * objects. If not provided, or null, the default is used.
		 */
		public function ControlCursor(offset:Point = null){
			super();
			mouseEnabled = false;
			if (offset) this.offset = offset;
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		
		/**
		 * Handler for the Event.ADDED_TO_STAGE event. By default, this
		 * is used to define the tool reference.
		 */
		protected function addedToStage(event:Event):void {
			this.tool = parent as TransformTool;
		}
		
		/**
		 * Handler for the Event.REMOVED_FROM_STAGE event. By default, 
		 * this is used to clear the tool reference.
		 */
		protected function removedFromStage(event:Event):void {
			this.tool = null;
			cleanupActiveMouse();
		}
		
		/**
		 * Handler for the TransformTool.TARGET_CHANGED event. 
		 */
		protected function targetChanged(event:Event):void {
			cleanupActiveMouse();
			cursor = null;
			cursorChanged(event);
			
			var targetEvent:MouseEvent = _tool.targetEvent as MouseEvent;
			if (targetEvent){
				activeMouseMove(targetEvent);
			}
		}
		
		/**
		 * Handler for the TransformTool.CURSOR_CHANGED event. When the
		 * cursor changes in the tool, the cursor used by the current
		 * ControlCursor is updated, adding the new cursor instance
		 * to the display list and setting up listeners to have it follow
		 * the position of the mouse.
		 */
		protected function cursorChanged(event:Event):void {
			cursor = _tool.cursor;
		}
		
		/**
		 * Handler for the MouseEvent.MOUSE_MOVE event. MOUSE_MOVE is used to
		 * track the location of the mouse on the screen.
		 */
		protected function activeMouseMove(event:MouseEvent):void {
			var position:Point;
			
			// get the position of the mouse
			// either from the tool event mouse
			// (pre-transformed mouse) or from the
			// event itself
			if (event == _tool.targetEvent && _tool.targetEventMouse){
				position = _tool.targetEventMouse;
			}else{
				position = new Point(event.stageX, event.stageY);
			}
			
			position = _tool.globalToLocal(position);
			if (_offset){
				position.x += _offset.x;
				position.y += _offset.y;
			}
			
			x = position.x;
			y = position.y;
			
			event.updateAfterEvent();
		}
		
		/**
		 * Intializes variables and listeners for tracking the mouse location.
		 */
		protected function setupActiveMouse():void {
			if (mouseActive){
				return;
			}
			
			activeTarget = null;
			if (stage && loaderInfo && loaderInfo.parentAllowsChild){
				activeTarget = stage;
			}else if (root){
				activeTarget = root;
			}
			if (activeTarget){
				mouseActive = true;
				// priority increased for the cursor to make sure
				// the cursor finds the original mouse location
				// prior to target transforms since event locations
				// change as the event target changes
				activeTarget.addEventListener(MouseEvent.MOUSE_MOVE, activeMouseMove, false, 1);
			}
		}
		
		/**
		 * Clears variables and listeners for tracking the mouse location.
		 */
		protected function cleanupActiveMouse():void {
			if (activeTarget){
				activeTarget.removeEventListener(MouseEvent.MOUSE_MOVE, activeMouseMove, false);
				activeTarget = null;
			}
			mouseActive = false;
		}
	}
}