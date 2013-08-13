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
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventPhase;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/**
	 * Base class for interactive Transform Tool controls.  This class adds
	 * to the Control class including a framework for handling user 
	 * interaction through mouse events.
	 * updates.  For non-interactive controls, use Control, though it is
	 * not required for controls to extend the Control class to be used
	 * as a control of the Transform Tool.
	 * @author Trevor McCauley
	 */
	public class ControlInteractive extends Control {
		
		/**
		 * The minimum distance to allow scaling. if the 
		 * distance between the mouse position and the 
		 * registration pont is less than this value, 
		 * scaling is not permitted.
		 */
		public const MIN_SCALE_BASE:Number = .1;
		
		/**
		 * The object from which mouse events are consumed. This would normally
		 * be the stage instance, but root may be used if stage is not allowed.
		 */
		protected var activeTarget:IEventDispatcher;
		
		/**
		 * The most recent mouse event received by the activeTarget dispatcher 
		 * when consuming mouse events.
		 */
		protected var activeMouseEvent:MouseEvent;
		
		/**
		 * Mouse location within the Transform Tool coordinate space
		 * when the control is first clicked.
		 */
		protected var mouse:Point;
		
		/**
		 * Mouse location within the target object coordinate space
		 * when the control is first clicked.
		 */
		protected var localMouse:Point;
		
		/**
		 * Offset for the mouse position.
		 */
		protected var offsetMouse:Point = new Point();
		
		/**
		 * Registration point location within the Transform Tool coordinate
		 * space when the control is first clicked. Used to derive base
		 * values.
		 */
		protected var baseRegistration:Point;
		
		/**
		 * Registration point location within the target object coordinate
		 * space when the control is first clicked. Used to derive base
		 * values.
		 */
		protected var baseLocalRegistration:Point;
		
		/**
		 * Inverted base matrix used to convert locations in the Transform
		 * Tool coordinate space into locations within the target object
		 * coordinate space.
		 */
		protected var baseLocalMatrixInverted:Matrix;
		
		/**
		 * Mouse location in x axis within the Transform Tool coordinate space
		 * when the control is first clicked.
		 */
		protected var baseX:Number;
		
		/**
		 * Mouse location in y axis within the Transform Tool coordinate space
		 * when the control is first clicked.
		 */
		protected var baseY:Number;
		
		/**
		 * Mouse location in x axis within the target object coordinate space
		 * after offsets are applied when the control is first clicked.
		 */
		protected var baseLocalX:Number;
		
		/**
		 * Mouse location in y axis within the target object coordinate space
		 * when the control is first clicked.
		 */
		protected var baseLocalY:Number;
		
		/**
		 * Mouse location in x axis within the Transform Tool coordinate space
		 * while the control is being dragged.
		 */
		protected var activeX:Number;
		
		/**
		 * Mouse location in y axis within the Transform Tool coordinate space
		 * while the control is being dragged.
		 */
		protected var activeY:Number;
		
		/**
		 * Mouse location in x axis within the target object coordinate space
		 * while the control is being dragged.
		 */
		protected var activeLocalX:Number;
		
		/**
		 * Mouse location in y axis within the target object coordinate space
		 * while the control is being dragged.
		 */
		protected var activeLocalY:Number;
		
		/**
		 * The cursor to be used when interacting with this control.
		 */
		public function get cursor():Cursor {
			return _cursor;
		}
		public function set cursor(value:Cursor):void {
			if (value == _cursor){
				return;
			}
			
			setupCursor();
			_cursor = value;
			cleanupCursor();
		}
		private var _cursor:Cursor;
		
		/**
		 * Setup steps when defining a new cursor value. You may need to 
		 * override this method to control the order of operations when
		 * adding content to the set cursor setter. This is called after
		 * a new cursor value is set.
		 */
		protected function setupCursor():void {
			if (_cursor){
				_cursor.tool = tool;
			}
		}
		
		/**
		 * Cleanup steps when defining a new cursor value. You may need to 
		 * override this method to control the order of operations when
		 * adding content to the set cursor setter.  This is called before
		 * a new cursor value is set.
		 */
		protected function cleanupCursor():void {
			if (_cursor){
				_cursor.tool = null;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function setupTool():void {
			// cursor needs to be set when tool
			// is defined but before setting
			// tool calls redraw (in setupTool)
			setupCursor();
			super.setupTool();
		}
		
		/**
		 * Constructor for creating new ControlInteractive instances.
		 * @param	cursor The cursor to be used while interacting with the
		 * control instance.
		 */
		public function ControlInteractive(cursor:Cursor = null){
			super();
			this.cursor = cursor;
			
			// default style for interactive controls 
			fillColor = 0x000000;
			lineColor = 0xFFFFFF;
			lineThickness = 2;
			
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown); // interaction...
			addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			addEventListener(MouseEvent.ROLL_OVER, rollOver);
			addEventListener(MouseEvent.ROLL_OUT, rollOut);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function removedFromStage(event:Event):void {
			cleanupActiveMouse();
			super.removedFromStage(event);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function targetChanged(event:Event):void {
			cleanupActiveMouse();
		}
		
		/**
		 * Handler for the TransformTool.RESTRICT event. This has
		 * no default behavior and is to be overriden by subclasses
		 * if needed.
		 */
		protected function restrict(event:Event):void {
			// to be overridden
		}
		
		/**
		 * @inheritDoc
		 */
		override public function redraw(event:Event):void {
			if (_cursor != null){
				_cursor.redraw(event);
			}
		}
		
		/**
		 * Handler for the MouseEvent.ROLL_OVER event for the control object.
		 * This is used to determine if the cursor needs to be changed.
		 */
		protected function rollOver(event:MouseEvent):void {
			if (_cursor != null && tool != null){
				if (!tool.isActive){
					tool.setCursor(_cursor, event);
				}
			}
		}
		
		/**
		 * Handler for the MouseEvent.ROLL_OUT event for the control object.
		 * This is used to determine if the cursor needs to be changed.
		 */
		protected function rollOut(event:MouseEvent):void {
			if (_cursor != null && tool != null){
				if (!tool.isActive && activeTarget == null){
					tool.setCursor(null);
				}
			}
		}
		
		/**
		 * Handler for the MouseEvent.ROLL_OUT event for the control object.
		 * This is used to determine if the cursor needs to be changed.
		 */
		protected function mouseDown(event:MouseEvent):void {
			activeMouseEvent = event;
			updateBaseReferences();
			
			setupActiveMouse();
		}
		
		/**
		 * Handler for the MouseEvent.MOUSE_MOVE event from the activeTarget
		 * object. This is used to update the active mouse positions.
		 */
		protected function activeMouseMove(event:MouseEvent):void {
			activeMouseEvent = event;
			updateActiveMouse();
		}
		
		/**
		 * Handler for the MouseEvent.MOUSE_UP event (capture and no capture)
		 * from the activeTarget object.
		 * This is used to cleanup mouse handlers and commit the target object.
		 * This handler handles both capture and bubble/at-target phases but 
		 * does not perform its operations in phases other than capture and
		 * at-target.
		 */
		protected function activeMouseUp(event:MouseEvent):void {
			
			// only handle events down to and including the target
			if (event.eventPhase != EventPhase.BUBBLING_PHASE){
				
				activeMouseEvent = null;
				cleanupActiveMouse();
				
				// commit after cleaning up the active mouse variables
				// specifically, TransformTool.isActive will need to 
				// be false in order for the commit for work.
				tool.commitTarget();
			}
		}
		
		/**
		 * Handler for the MouseEvent.MOUSE_UP event for the control object.
		 * This is used to set the cursor
		 */
		protected function mouseUp(event:MouseEvent):void {
			if (tool != null){
				tool.setCursor(_cursor, event);
			}
		}
		
		/**
		 * Intializes variables and listeners for tracking the mouse location.
		 */
		protected function setupActiveMouse():void {
			activeTarget = null;
			
			if (stage && loaderInfo && loaderInfo.parentAllowsChild){
				// standard, expected target
				activeTarget = stage;
				
			}else if (root){
				// since without the stage, we can't identify mouse-up-outside
				// events, we have to resort to using the rolling out of the
				// content we actually have access to getting events from 
				activeTarget = root;
				activeTarget.addEventListener(MouseEvent.ROLL_OUT, activeMouseUp);
			}
			
			if (activeTarget){
				tool.isActive = true;
				activeTarget.addEventListener(MouseEvent.MOUSE_MOVE, activeMouseMove);
				// Capture phase used here in case the interaction
				// target, or some other object within its hierarchy
				// stops propagation of the event preventing the
				// tool from recognizing the completion of its use
				activeTarget.addEventListener(MouseEvent.MOUSE_UP, activeMouseUp, true);
				activeTarget.addEventListener(MouseEvent.MOUSE_UP, activeMouseUp, false);
			}
			
			// listen for restrict event to handle restrictions properly
			tool.addEventListener(TransformTool.RESTRICT, restrict);
		}
		
		/**
		 * Clears variables and listeners for tracking the mouse location.
		 */
		protected function cleanupActiveMouse():void {
			var tool:TransformTool = this.tool;
			
			if (activeTarget){
				activeTarget.removeEventListener(MouseEvent.ROLL_OUT, activeMouseUp);
				activeTarget.removeEventListener(MouseEvent.MOUSE_MOVE, activeMouseMove);
				activeTarget.removeEventListener(MouseEvent.MOUSE_UP, activeMouseUp, true);
				activeTarget.removeEventListener(MouseEvent.MOUSE_UP, activeMouseUp, false);
				activeTarget = null;
				tool.isActive = false;
			}
			
			tool.removeEventListener(TransformTool.RESTRICT, restrict);
			
			if (tool.cursor == _cursor){
				tool.setCursor(null);
			}
		}
		
		/**
		 * Updates the values of the base references.
		 */
		protected function updateBaseReferences():void {
			var tool:TransformTool = this.tool;
			
			// make sure the base transform is at a minimum
			// size for transformations, i.e. it is not
			// 0-scaled preventing certain transformations
			// to fail
			if (tool.normalizeBase()){
				
				// if the base was updated, recalculate
				// the tool transform and update
				calculateAndUpdate();
				
			}else if (activeMouseEvent != tool.targetEvent){
				
				// the tool is also updated as a consequence
				// of starting a transformation through use
				// however no recalculation is made. Additionally
				// an update is not needed if the current event
				// is the target selection event since it would
				// have already updated the tool
				tool.update();
			}
			
			// define base transforms and registration points
			var baseLocalMatrix:Matrix = tool.baseMatrix;
			baseLocalMatrixInverted = baseLocalMatrix.clone();
			baseLocalMatrixInverted.invert();
			
			baseLocalRegistration = tool.localRegistration;
			baseRegistration = baseLocalMatrix.transformPoint(baseLocalRegistration);
			
			updateBaseMouse();
		}
		
		/**
		 * Updates base references for mouse positions. These references are
		 * used to represent the base state of mouse position when the control
		 * was first interacted with.
		 */
		protected function updateBaseMouse():void {
			updateMousePositions(activeMouseEvent);
			
			baseX = mouse.x + offsetMouse.x - baseRegistration.x;
			baseY = mouse.y + offsetMouse.y - baseRegistration.y;
			
			var localOffset:Point = baseLocalMatrixInverted.deltaTransformPoint(offsetMouse);
			baseLocalX = localMouse.x + localOffset.x - baseLocalRegistration.x;
			baseLocalY = localMouse.y + localOffset.y - baseLocalRegistration.y;
		}
		
		/**
		 * Updates active references for mouse positions. These references are
		 * used to represent the most up to date state of the mouse position
		 * as a control is being interacted with.
		 */
		protected function updateActiveMouse():void {
			updateMousePositions(activeMouseEvent);
			
			activeX = mouse.x + offsetMouse.x - baseRegistration.x;
			activeY = mouse.y + offsetMouse.y - baseRegistration.y;
			
			var localOffset:Point = baseLocalMatrixInverted.deltaTransformPoint(offsetMouse);
			activeLocalX = localMouse.x + localOffset.x - baseLocalRegistration.x;
			activeLocalY = localMouse.y + localOffset.y - baseLocalRegistration.y;
		}
		
		/**
		 * Updates mouse position references from the provided mouse
		 * event.
		 * @param	event MouseEvent from which to obtain mouse positions.
		 */
		protected function updateMousePositions(event:MouseEvent = null):void {
			var tool:TransformTool = this.tool;
			
			// if the current mouse event is the event that was
			// associated with setting the tool's target, check
			// to see if the original mouse location is available
			// to reference (pre target updates). Otherwise use the
			// mouse locations available in the event
			if (event == tool.targetEvent && tool.targetEventMouse){
				mouse = tool.targetEventMouse.clone();
			}else{
				mouse = new Point(event.stageX, event.stageY);
			}
			
			if (tool.target.parent != null){
				mouse = tool.target.parent.globalToLocal(mouse);
			}
			
			localMouse = baseLocalMatrixInverted.transformPoint(mouse);
		}
		
		/**
		 * Calls calculateTransform and update from the parent TransformTool
		 * instance.
		 * @param	commit The value of commit to be used in 
		 * TransformTool.update().
		 * @param	enforceNegativeScaling The value of enforceNegativeScaling
		 * to be used in tool.calculateTransform().
		 */
		protected function calculateAndUpdate(commit:Boolean = true, enforceNegativeScaling:Boolean = true):void {
			tool.calculateTransform(true, enforceNegativeScaling);
			tool.update(commit);
		}
		
		/**
		 * Moves the transform using the current mouse position (applied to
		 * postTransform).
		 */
		protected function move():void {
			tool.postTransform.translate(activeX - baseX, activeY - baseY);
		}
		
		/**
		 * Moves the registration point using the current mouse position.
		 */
		protected function moveRegistration():void {
			tool.localRegistration.x = localMouse.x;
			tool.localRegistration.y = localMouse.y;
			tool.saveRegistration();
		}
		
		/**
		 * Skews the transform along the x axis using the current mouse
		 * position (applied to preTransform).
		 */
		protected function skewXAxis():void {
			if (Math.abs(baseLocalY) >= MIN_SCALE_BASE){
				tool.preTransform.c = (activeLocalX - baseLocalX)/baseLocalY;
			}
		}
		
		/**
		 * Skews the transform along the y axis using the current mouse
		 * position (applied to preTransform).
		 */
		protected function skewYAxis():void {
			if (Math.abs(baseLocalX) >= MIN_SCALE_BASE){
				tool.preTransform.b = (activeLocalY - baseLocalY)/baseLocalX;
			}
		}
		
		/**
		 * Scales the transform along the  axis using the current mouse
		 * position (applied to preTransform).
		 */
		protected function scaleXAxis():void {
			if (Math.abs(baseLocalX) >= MIN_SCALE_BASE){
				tool.preTransform.scale(activeLocalX/baseLocalX, 1);
			}
		}
		
		/**
		 * Scales the transform along the y axis using the current mouse
		 * position (applied to preTransform).
		 */
		protected function scaleYAxis():void {
			if (Math.abs(baseLocalY) >= MIN_SCALE_BASE){
				tool.preTransform.scale(1, activeLocalY/baseLocalY);
			}
		}
		
		/**
		 * Scales the transform along both the x and y axes using the
		 * current mouse position (applied to preTransform).
		 */
		protected function scale():void {
			var sx:Number = (Math.abs(baseLocalX) >= MIN_SCALE_BASE) ? activeLocalX/baseLocalX : 1;
			var sy:Number = (Math.abs(baseLocalY) >= MIN_SCALE_BASE) ? activeLocalY/baseLocalY : 1;
			
			if (sx != 1 || sy != 1){
				tool.preTransform.scale(sx, sy);
			}
		}
		
		/**
		 * Scales the transform along both the x and y axes using the
		 * current mouse position in a uniform fashion (applied to 
		 * preTransform).
		 */
		protected function uniformScale():void {
			var sx:Number = (Math.abs(baseLocalX) >= MIN_SCALE_BASE) ? activeLocalX/baseLocalX : 1;
			var sy:Number = (Math.abs(baseLocalY) >= MIN_SCALE_BASE) ? activeLocalY/baseLocalY : 1;
			
			if (sx != 1 || sy != 1){
				
				// find the ratio to make the scaling
				// uniform in both the x and y axes
				var ratioX:Number = sy ? Math.abs(sx/sy) : 0;
				var ratioY:Number = sx ? Math.abs(sy/sx) : 0;
				
				// for 0 scale, scale both axises to 0
				if (ratioX == 0 || ratioY == 0){
					sx = 0;
					sy = 0;
					
				// scale mased on the smaller ratio
				}else if (ratioX > ratioY){
					sx *= ratioY;
				}else{
					sy *= ratioX;
				}
				
				tool.preTransform.scale(sx, sy);
			}
		}
		
		/**
		 * Rotates a transform using the current mouse position (applied to
		 * postTransform).
		 */
		protected function rotate():void {
			var baseAngle:Number = Math.atan2(baseY, baseX);
			var activeAngle:Number = Math.atan2(activeY, activeX);
			tool.postTransform.rotate(activeAngle - baseAngle);
		}
	}
}