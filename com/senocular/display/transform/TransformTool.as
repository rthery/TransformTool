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
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventPhase;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	
	// TODO: event metadata
	// TODO: position restrictions?
	// TODO: what happens when fitToTarget (or others?) gets called while dragging?
	
	/**
	 * A tool used for transforming display objects visually on the screen.
	 * TransformTool instances are placed in a display object container along
	 * with the objects it will transform.
	 * @author Trevor McCauley
	 * @version 2010.12.07
	 */
	public class TransformTool extends Sprite {
		
		/**
		 * Transform method for transforming a target object by updating
		 * DisplayObject.transform.matrix.
		 */
		public static const TRANSFORM_MATRIX:String = "matrix";
		
		/**
		 * Transform method for transforming a target object by updating
		 * properties such as DisplayObject.width, DisplayObject.height and
		 * DisplayObject.rotation.
		 */
		public static const TRANSFORM_PROPERTIES:String = "properties";
		
		/**
		 * Event constant for cursorChanged event types.
		 */
		public static const CURSOR_CHANGED:String = "cursorChanged";
		
		/**
		 * Event constant for targetChanged event types.
		 */
		public static const TARGET_CHANGED:String = "targetChanged";
		
		/**
		 * Event constant for transformChanged event types.
		 */
		public static const TRANSFORM_CHANGED:String = "transformChanged";
		
		/**
		 * Event constant for targetTransformed event types.
		 */
		public static const TARGET_TRANSFORMED:String = "targetTransformed";
		
		/**
		 * Event constant for redraw event types.
		 */
		public static const REDRAW:String = "redraw";
		
		/**
		 * Event constant for restrict event types.
		 */
		public static const RESTRICT:String = "restrict";
		
		/**
		 * Event constant for commit event types.
		 */
		public static const COMMIT:String = "commit";
		
		/**
		 * The cursor to be displayed by the Transform Tool.  Cursors are 
		 * generally defined in and set by controls. Using the ControlCursor
		 * control, the cursor can be seen in the TransformTool instance
		 * itself. Otherwise, cursors will have to be manually displayed by
		 * listening for the CURSOR_CHANGED event.
		 */
		public function get cursor():DisplayObject {
			return _cursor;
		}
		public function set cursor(value:DisplayObject):void {
			setCursor(value, null);
		}
		
		/**
		 * Sets the cursor for the transform tool with a respective cursor
		 * event that identifies the event that caused the change in the cursor.
		 * @param	value The cursor display object to be used for the current
		 * Transform Tool cursor. 
		 * @param	cursorEvent The event that invoked the change in the cursor.
		 */
		public function setCursor(value:DisplayObject, cursorEvent:Event = null):void {
			_cursorEvent = value ? cursorEvent : null;
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
			if (_cursorHidesMouse){
				if (_cursor == null){
					Mouse.show();
				}else{
					Mouse.hide();
				}
			}
			
			dispatchEvent( new Event(CURSOR_CHANGED) );
		}
		
		/**
		 * Cleanup steps when defining a new cursor value. You may need to 
		 * override this method to control the order of operations when
		 * adding content to the set cursor setter.  This is called before
		 * a new cursor value is set.
		 */
		protected function cleanupCursor():void {
			// do nothing; may be overridden
		}
		
		/**
		 * The event that invoked a change in the cursor.
		 */
		public function get cursorEvent():Event { return _cursorEvent; }
		protected var _cursorEvent:Event;
		
		/**
		 * When true, the native mouse cursor will be hidden with
		 * Mouse.hide() when the cursor is non-null.
		 */
		public function get cursorHidesMouse():Boolean { return _cursorHidesMouse; }
		public function set cursorHidesMouse(value:Boolean):void { _cursorHidesMouse = value; }
		private var _cursorHidesMouse:Boolean = false;
		
		/**
		 * The registration manager used to keep track of registration
		 * points in target objects.  When using multiple instances of
		 * TransformTool, you may want to have each instance use the same
		 * registration manager so that each Transform Tool uses the same 
		 * registration points for objects.
		 * @throws ArgumentError The specified value is null.
		 */
		public function get registrationManager():RegistrationManager {
			return _registrationManager;
		}
		public function set registrationManager(value:RegistrationManager):void {
			if (value){
				if (value != _registrationManager){
					_registrationManager = value;
					retrieveRegistration();
				}
			}else{
				throw new ArgumentError("Parameter registrationManager cannot be null");
			}
		}
		private var _registrationManager:RegistrationManager;
		
		/**
		 * The current location of the registration point in the context
		 * of the target object's coordinate space.  This value will always
		 * be a Point instance.  When there is no target, the value will be
		 * (0, 0). The registration manager uses this value to store
		 * registration points for objects.
		 */
		public function get localRegistration():Point {
			return _localRegistration;
		}
		private var _localRegistration:Point = new Point(0, 0);
		
		/**
		 * The minimum width along the transformed x axis that a target
		 * object is allowed to have.  If both a minWidth and minScaleX
		 * are specified, the value resulting in the highest value will
		 * be used.
		 */
		public function get minWidth():Number { return _minWidth; }
		public function set minWidth(value:Number):void { _minWidth = value; }
		private var _minWidth:Number;
		
		/**
		 * The maximum width along the transformed x axis that a target
		 * object is allowed to have.  If both a maxWidth and maxScaleX
		 * are specified, the value resulting in the smallest value will
		 * be used.
		 */
		public function get maxWidth():Number { return _maxWidth; }
		public function set maxWidth(value:Number):void { _maxWidth = value; }
		private var _maxWidth:Number;
		
		/**
		 * The minimum height along the transformed y axis that a target
		 * object is allowed to have.  If both a minHeight and minScaleY
		 * are specified, the value resulting in the highest value will
		 * be used.
		 */
		public function get minHeight():Number { return _minHeight; }
		public function set minHeight(value:Number):void { _minHeight = value; }
		private var _minHeight:Number;
		
		/**
		 * The maximum height along the transformed y axis that a target
		 * object is allowed to have.  If both a maxHeight and maxScaleY
		 * are specified, the value resulting in the smallest value will
		 * be used.
		 */
		public function get maxHeight():Number { return _maxHeight; }
		public function set maxHeight(value:Number):void { _maxHeight = value; }
		private var _maxHeight:Number;
		
		/**
		 * The minimum scale along the transformed x axis that a target
		 * object is allowed to have.  If both a minWidth and minScaleX
		 * are specified, the value resulting in the highest value will
		 * be used.
		 */
		public function get minScaleX():Number { return _minScaleX; }
		public function set minScaleX(value:Number):void { _minScaleX = value; }
		private var _minScaleX:Number;
		
		/**
		 * The maximum scale along the transformed x axis that a target
		 * object is allowed to have.  If both a maxWidth and maxScaleX
		 * are specified, the value resulting in the smallest value will
		 * be used.
		 */
		public function get maxScaleX():Number { return _maxScaleX; }
		public function set maxScaleX(value:Number):void { _maxScaleX = value; }
		private var _maxScaleX:Number;
		
		/**
		 * The minimum scale along the transformed y axis that a target
		 * object is allowed to have.  If both a minHeight and minScaleY
		 * are specified, the value resulting in the highest value will
		 * be used.
		 */
		public function get minScaleY():Number { return _minScaleY; }
		public function set minScaleY(value:Number):void { _minScaleY = value; }
		private var _minScaleY:Number;
		
		/**
		 * The maximum scale along the transformed y axis that a target
		 * object is allowed to have.  If both a maxHeight and maxScaleY
		 * are specified, the value resulting in the smallest value will
		 * be used.
		 */
		public function get maxScaleY():Number { return _maxScaleY; }
		public function set maxScaleY(value:Number):void { _maxScaleY = value; }
		private var _maxScaleY:Number;
		
		/**
		 * Determines whether or not transforming is allowed to result in 
		 * negative scales.  When true, negative scaling is allowed and a
		 * transformed target object can be mirrored along its x and/or y
		 * axes.  When false, negative scaling is not allowed and scale for
		 * both axes will always be positive.
		 */
		public function get negativeScaling():Boolean { return _negativeScaling; }
		public function set negativeScaling(value:Boolean):void { _negativeScaling = value; }
		private var _negativeScaling:Boolean = true;
		
		/**
		 * The minimum rotation allowed for a transformed target object.
		 * Ranges between minRotation and maxRotation depend on which value
		 * of the two is greater.
		 */
		public function get minRotation():Number { return _minRotation; }
		public function set minRotation(value:Number):void { _minRotation = value; }
		private var _minRotation:Number;
		
		/**
		 * The maximum rotation allowed for a transformed target object.
		 * Ranges between minRotation and maxRotation depend on which value
		 * of the two is greater.
		 */
		public function get maxRotation():Number { return _maxRotation; }
		public function set maxRotation(value:Number):void { _maxRotation = value; }
		private var _maxRotation:Number;
		
		/**
		 * A reference point (metric) indicating the location of the
		 * registration point within the TransformTool coordinate space.
		 */
		public var registration:Point = new Point();
		
		/**
		 * A reference point (metric) indicating the location of the local
		 * top left corner of the target object in the TransformTool 
		 * coordinate space.
		 */
		public var topLeft:Point = new Point();
		
		/**
		 * A reference point (metric) indicating the location of the local 
		 * top right corner of the target object in the TransformTool 
		 * coordinate space.
		 */
		public var topRight:Point = new Point();
		
		/**
		 * A reference point (metric) indicating the location of the local
		 * bottom left corner of the target object in the TransformTool 
		 * coordinate space.
		 */
		public var bottomLeft:Point = new Point();
		
		/**
		 * A reference point (metric) indicating the location of the local
		 * bottom right corner of the target object in the TransformTool 
		 * coordinate space.
		 */
		public var bottomRight:Point = new Point();
		
		/**
		 * Target display object to be transformed by the TransformTool.
		 */
		public function get target():DisplayObject {
			return _target;
		}
		public function set target(value:DisplayObject):void {
			setTarget(value, null);
		}
		public function setTarget(value:DisplayObject, targetEvent:Event = null):void {
			
			// define persistent target event and a mouse point
			// which remembers the stage mouse at the point
			// in time this call is first made (it may change
			// within the mouse event if the target moves)
			_targetEvent = value ? targetEvent : null;
			var targetMouseEvent:MouseEvent = _targetEvent as MouseEvent;
			if (targetMouseEvent){
				_targetEventMouse = new Point(targetMouseEvent.stageX, targetMouseEvent.stageY);
			}else{
				_targetEventMouse = null;
			}
			
			// checked after target event is set; the
			// mouse can be changed even if the target
			// stays the same
			if (value == _target){
				return;
			}
			
			cleanupTarget();
			_target = value;
			setupTarget();
		}
		private var _target:DisplayObject;
		
		protected function setupTarget():void {
			
			// get the new registration for the new target
			retrieveRegistration();
			
			if (_target){
				
				// tool is hidden unless
				// a target is available
				visible = true;
				
				if (_autoRaise){
					raise();
				}
				
				fitToTarget();
				
			}else{
				visible = false;
			}
			
			dispatchEvent( new Event(TARGET_CHANGED) );
		}
		
		/**
		 * Cleanup steps when defining a new target value. You may need to 
		 * override this method to control the order of operations when
		 * adding content to the set target setter.  This is called before
		 * a new target value is set.
		 */
		protected function cleanupTarget():void {
			if (_target){
				// update the saved registration point for 
				// the old target so it can be referenced
				// when the tool is reassigned to it later
				saveRegistration();
			}
		}
		
		/**
		 * A saved reference to the event that selected the
		 * target when TransformTool.select was used. This allows
		 * controls to use that event to perform appropriate actions
		 * during selection, such as starting a drag (move) operation
		 * on the target.
		 */
		public function get targetEvent():Event { return _targetEvent; }
		protected var _targetEvent:Event;
		
		public function get targetEventMouse():Point { return _targetEventMouse; }
		protected var _targetEventMouse:Point;
		
		/**
		 * A representation of the TransformTool's display list in 
		 * array form. Control sets are assigned to this property.
		 */
		public function get controls():Array {
			var value:Array = []; // objects in display list
			
			// loop through display list one child at a time
			// adding them to the return value array
			var i:int = numChildren;
			while(i--){
				value[i] = getChildAt(i);
			}
			
			return value;
		}
		public function set controls(value:Array):void {
			var child:DisplayObject; // child to be added
			var childrenOffset:int = 0; // number of invalid children in array
			
			// loop through array adding a display list child
			// for each child in the value array
			var i:int, n:int = value ? value.length : 0;
			for (i=0; i<n; i++){
				
				// when a valid child is found
				child = value[i] as DisplayObject;
				if (child){
					
					// check the parent as it may already exist
					// within this display list
					if (child.parent == this){
						
						// if already in the display list, set
						// the sorting value to match it's position
						// in the array
						setChildIndex(child, i - childrenOffset);
					}else{
						
						// if not already in the display list
						// add the child to it at the location
						// matching it's position in the array
						addChildAt(child, i - childrenOffset);
					}
				}else{
					
					// count of invalid children. when an invalid
					// child is found, this offset is used to
					// offset the position of other children
					// added to the display list since the spot
					// the invalid child would have taken is no
					// longer being used
					childrenOffset++;
				}
			}
			
			// remove any children from the end of the
			// display list that would have been left over
			// from the original display list layout
			var end:int = n - childrenOffset;
			while (numChildren > end){
				removeChildAt(end);
			}
		}
		
		/**
		 * The "committed" matrix transformation of a target
		 * object.  This is the matrix on which other transformations
		 * are based.  This is set when the target is set and when
		 * is committed with methods like commitTarget().  When 
		 * preTransform and postTransform are applied, they're applied
		 * to the baseMatrix value to resolve the calculatedMatrix.
		 */
		public function get baseMatrix():Matrix { return _baseMatrix; }
		protected var _baseMatrix:Matrix = new Matrix();
		
		public function get preTransform():Matrix { return _preTransform; }
		protected var _preTransform:Matrix = new Matrix();
		
		public function get postTransform():Matrix { return _postTransform; }
		protected var _postTransform:Matrix = new Matrix();
		
		/**
		 * The current transformation matrix of the Transform Tool. This
		 * is updated when the target is defined and when 
		 * calculateTransform is called.  Controls will automatically call
		 * calculateTransform when used, updating the calculatedMatrix
		 * during transformations.
		 */
		public function get calculatedMatrix():Matrix { return _calculatedMatrix; }
		protected var _calculatedMatrix:Matrix = new Matrix();
		
		
		/**
		 * Determines the method by which tool transformations 
		 * are applied to the target display object.
		 */
		public function get transformMethod():String { return _transformMethod; }
		public function set transformMethod(value:String):void { _transformMethod = value; }
		private var _transformMethod:String = TRANSFORM_MATRIX;
		
		/**
		 * When true, the target is visually transformed with the tool
		 * between target commits as the user changes the transform with 
		 * interactive controls.  If false, target objects are only updated
		 * when the target is committed which (typically) occurs only after 
		 * interaction with a control has completed.
		 */
		public function get livePreview():Boolean { return _livePreview; }
		public function set livePreview(value:Boolean):void { _livePreview = value; }
		private var _livePreview:Boolean = true;
		
		/**
		 * When true, the targets will raise to the top of their
		 * display lists, though not above the Transform Tool, when 
		 * assigned as targets of the tool.
		 */
		public function get autoRaise():Boolean { return _autoRaise; }
		public function set autoRaise(value:Boolean):void { _autoRaise = value; }
		private var _autoRaise:Boolean = false;
		
		/**
		 * Indicates that a transform control has assumed control
		 * of the tool for interaction.  Other controls would check
		 * this value to see if it is able to interact with the
		 * tool without interference from other controls.
		 */
		public function get isActive():Boolean { return _isActive; }
		public function set isActive(value:Boolean):void { _isActive = value; }
		private var _isActive:Boolean = false;
		
		/**
		 * Constructor for new TransformTool instances.
		 * @param	controls An array of controls to be added to the display
		 * list.
		 * @param	registrationManager The registration manager to use for
		 * target objects assigned to this TransformTool instance. If one is
		 * not specified, one is created automatically.
		 */
		public function TransformTool(controls:Array = null, registrationManager:RegistrationManager = null){
			visible = false;
			
			if (controls != null){
				this.controls = controls;
			}
			
			if (registrationManager != null){
				this.registrationManager = registrationManager;
			}else{
				this.registrationManager = new RegistrationManager();
			}
		}
		
		/**
		 * Helper selection handler for selecting target objects. Set this
		 * handler as the listener for a MouseEvent.MOUSE_DOWN event of an
		 * object or a container of objects to have targets automatically set
		 * to the Transform Tool when clicked.  This event handler uses either
		 * Event.target or Event.currentTarget as TransformTool.target
		 * depending on which is in the same display object container as the
		 * Transform Tool itself.  
		 * It is not required that you use this event handler. It is only a 
		 * helper function that can optionally be used to help ease 
		 * development.
		 */
		public function select(event:Event):void {
			// the selected object will either be the
			// event target or current target. The current
			// target is checked first followed by target.
			// The parent of the target must match the
			// parent of the tool to be selected this way.
			
			if (event.currentTarget != this 
			&& event.currentTarget.parent == parent){
				
				setTarget(event.currentTarget as DisplayObject, event);
				
			}else if (event.target != this 
			&& event.target.parent == parent){
				
				setTarget(event.target as DisplayObject, event);
				
			}
		}
		
		/**
		 * Helper selection handler for deselecting target objects. Set this
		 * handler as the listener for an event that would cause the
		 * deselection of a target object.
		 * It is not required that you use this event handler. It is only a 
		 * helper function that can optionally be used to help ease 
		 * development.
		 */
		public function deselect(event:Event):void {
			if (_target != null && event.eventPhase == EventPhase.AT_TARGET){
				setTarget(null, null);
			}
		}
		
		/**
		 * Fits the Transform Tool to match the current state of the target.
		 * Use this when the target object is transformed outside of the
		 * Transform Tool.
		 */
		public function fitToTarget():void {
			if (_target == null){
				return;
			}
			
			resetTransformModifiers();
			calculateTransform(false);
			update();
		}
		
		/**
		 * Moves the Transform Tool and the target object to the tops
		 * of their respective parent display lists.  This is automatically
		 * called when a target is set and autoRaise is true.
		 */
		public function raise():void {
			var container:DisplayObjectContainer;					
			
			// raise target first
			if (_target){
				container = _target.parent;
				if (container){
					container.setChildIndex(_target, container.numChildren - 1);
				}
			}
			
			// raise the tool second
			// to go above the target
			container = this.parent;
			if (container){
				container.setChildIndex(this, container.numChildren - 1);
			}
		}
		
		/**
		 * Calculates the value of calculatedMatrix by applying the values of
		 * preTransform and postTransform to the baseMatrix.  The value of
		 * calculatedMatrix is used when transforms are being applied to the
		 * tool and its target object.
		 * @param	reset When true, the preTransform and postTransform
		 * modifiers will be reset to their identity matrix after the
		 * calculation is complete.
		 * @param enforceNegativeScaling When false, scale restrictions that 
		 * use negativeScaling to restrict calculatedMatrix are ignored.
		 */
		public function calculateTransform(reset:Boolean = true, enforceNegativeScaling:Boolean = true):void {
			
			// to compare with the new matrix to see if
			// a change has occurred
			var originalMatrix:Matrix = _calculatedMatrix.clone();
			
			// our final transform starts with the preTransform
			// followed by the base transform of the last commit point
			_calculatedMatrix.identity();
			_calculatedMatrix.concat(_preTransform);
			_calculatedMatrix.concat(_baseMatrix);
			
			// next, the post transform is concatenated on top
			// of the previous result, but for the post transform,
			// translation (x,y) values are not transformed. They're
			// saved with the respective post transform offset, then 
			// reassigned after concatenating the post transformation
			var tx:Number = _calculatedMatrix.tx + _postTransform.tx;
			var ty:Number = _calculatedMatrix.ty + _postTransform.ty;
			
			// finally, concatenate post transform on to final
			_calculatedMatrix.concat(_postTransform);
			
			// reassign saved tx and ty values with the 
			// included registration offset
			_calculatedMatrix.tx = tx;
			_calculatedMatrix.ty = ty;
			
			// apply restrictions before 
			// offsetting the registration
			restrict(enforceNegativeScaling);
			
			// registration handling is done after
			// all transforms; the tool has to re-position
			// itself so that the new position of the
			// registration point now matches the old
			applyRegistrationOffset();
			
			if (reset){
				resetTransformModifiers(false);
			}
			
			if (!matrixEquals(originalMatrix, _calculatedMatrix)){
				dispatchEvent( new Event(TRANSFORM_CHANGED) );
			}
		}
		
		/**
		 * Resets the registration point to its default location relative
		 * to the (0,0) position in the target object's local coordinate
		 * space.
		 */
		public function resetRegistration():void {
			// reset local values
			_localRegistration.x = 0;
			_localRegistration.y = 0;
			
			// update the registration manager
			saveRegistration();
			
			// the only metric that need updating as
			// as result of local registration changing
			registration = _calculatedMatrix.transformPoint(_localRegistration);
		}
		
		/**
		 * Resets the transformation of the target object to it's
		 * unmodified state.
		 */
		public function resetTransform():void {
			resetTransformModifiers(false);
			normalizeBase();
			
			// counter base transform with an inverted
			// post transform.  This will transform the
			// target to the identity (reset) transform.
			_postTransform.identity();
			_postTransform.concat(_baseMatrix);
			_postTransform.invert();
			
			// do not transform position
			_postTransform.tx = 0;
			_postTransform.ty = 0;
			
			// calc transform to apply updated base
			// to final transform as well as handle
			// restrictions etc.  For restrictions
			// negative scaling is off to make sure
			// the transform can be properly reset and
			// is not restricted in that manner
			
			calculateTransform(true, false);
		}
		
		/**
		 * Performs a full update of the Transform Tool. This includes:
		 * updating the metrics, updating the target (with optional
		 * commit) and updating the controls.
		 * @param	commit When true, the target is updated with a call
		 * to commitTarget. When false, updateTarget is used.
		 */
		public function update(commit:Boolean = true):void {
			updateMetrics();
			
			if (commit){ 
				commitTarget();
			}else{
				updateTarget();
			}
			
			updateControls();
		}
		
		/**
		 * Dispatches an update event (REDRAW) allowing controls
		 * within the tool to update themselves to match the
		 * current calculatedMatrix transform.
		 */
		public function updateControls():void {
			dispatchEvent( new Event(REDRAW) );
		}
		
		/**
		 * Applies the calculatedMatrix transform to the target
		 * object. Updates are only applied here if livePreview
		 * is true. For non-livePreview updates, commitTarget is
		 * required.
		 */
		public function updateTarget():void {
			if (_livePreview){
				if (applyTransformToTarget()){
					dispatchEvent( new Event(TARGET_TRANSFORMED) );
				}
			}
		}
		
		/**
		 * Applies the calculatedMatrix transform to the target
		 * object and commits the target to the transformation.
		 * This will reset all transformation modifiers
		 * (preTransform and postTransform) and set the baseMatrix
		 * to the updated transform of the target.
		 */
		public function commitTarget():void {
			
			// do not commit the target if the tool is currently
			// active, meaning a control is currently being dragged
			// and transforming the tool and target based on an
			// expected, previous commit
			if (!_isActive){
				
				var transformed:Boolean = applyTransformToTarget();
				resetTransformModifiers();
				if (transformed){
					dispatchEvent( new Event(TARGET_TRANSFORMED) );
				}
				
				dispatchEvent( new Event(COMMIT) );
			}
		}
		
		protected function validateTargetMatrix():Boolean {
			// no target fails validation
			if (_target == null){
				return false;
			}
			
			// make sure the target has a 2D matrix
			if (_target.transform.matrix == null){
				_target.transform.matrix = new Matrix(1, 0, 0, 1, _target.x, _target.y);
			}
			
			// target passes validation
			// whether or not a new 2D matrix was 
			// created for it
			return true;
		}
		
		/**
		 * Updates references used to identify points of interest in the
		 * Transform Tool. These include points like the registration point,
		 * topLeft, bottomRight, etc. Metrics should be updated when the
		 * calculatedMatrix is updated and controls need to be redrawn as
		 * many controls use these properties to position themselves.
		 */
		public function updateMetrics():void {
			var bounds:Rectangle = _target.getBounds(_target);
			
			retrieveRegistration();
			registration = _calculatedMatrix.transformPoint(_localRegistration);
			
			var referencePoint:Point = new Point(bounds.left, bounds.top);
			topLeft = _calculatedMatrix.transformPoint(referencePoint);
			
			referencePoint.x = bounds.right;
			topRight = _calculatedMatrix.transformPoint(referencePoint);
			
			referencePoint.y = bounds.bottom;
			bottomRight = _calculatedMatrix.transformPoint(referencePoint);
			
			referencePoint.x = bounds.left;
			bottomLeft = _calculatedMatrix.transformPoint(referencePoint);
		}
		
		/**
		 * Applies the transform defined by calculatedMatrix to the target
		 * object.  How this is applied depends on the value of 
		 * transformMethod.
		 * @return True if the target object was changed, false if not.
		 */
		protected function applyTransformToTarget():Boolean {
			
			// if the target transform already matches the
			// calculated tansform of the tool, don't update
			if (!validateTargetMatrix() || matrixEquals(_target.transform.matrix, _calculatedMatrix)){
				return false;
			}
			
			switch (_transformMethod){
				
				case TRANSFORM_MATRIX:{
					
					// assign adjusted matrix directly to
					// the matrix of the target instance
					_target.transform.matrix = _calculatedMatrix;
					break;
				}
				
				case TRANSFORM_PROPERTIES:{
				
					// get the internal boundaries of the target instance
					// this is used to set the appropriate size
					var bounds:Rectangle = _target.getBounds(_target);
					
					if (bounds.width == 0 || bounds.height == 0){
						// cannot set the size of an object with no content
						// doing so can corrupt the object's dimensions
						return false;
					}
					
					// first, any rotation needs to be removed so that
					// applications of width and height are accurate
					_target.rotation = 0;
					
					// get necessary transform data from the matrix
					// this is limited to size and rotation. Skew
					// transforms cannot be applied through 
					// non-matrix properties
					var ratioX:Number = Math.sqrt(_calculatedMatrix.a*_calculatedMatrix.a + _calculatedMatrix.b*_calculatedMatrix.b);
					var ratioY:Number = Math.sqrt(_calculatedMatrix.c*_calculatedMatrix.c + _calculatedMatrix.d*_calculatedMatrix.d);
					var angle:Number = Math.atan2(_calculatedMatrix.b, _calculatedMatrix.a);
					
					// assign width and height followed by rotation and position
					_target.width = bounds.width * ratioX;
					_target.height = bounds.height * ratioY;
					_target.rotation = angle * (180/Math.PI);
					_target.x = _calculatedMatrix.tx;
					_target.y = _calculatedMatrix.ty;
					break;
				}
				
				default:{
					// unrecognized transform type
					// do nothing
					return false;
					break;
				}
			}
			
			return true;
		}
		
		/**
		 * Resets the values of preTransform, postTransform, and optionally
		 * baseMatrix to their defaults. The pre and post transforms are set
		 * to their identity matrices.  The baseMatrix is set to the transform
		 * matrix of the target object.
		 * @param	resetBase When true, baseMatrix is reset along with
		 * preTransform and postTransform.
		 */
		protected function resetTransformModifiers(resetBase:Boolean = true):void {
			_preTransform.identity();
			_postTransform.identity();
			
			if (resetBase){
				_baseMatrix.identity();
				
				if (validateTargetMatrix()){
					
					_baseMatrix.concat( _target.transform.matrix );
					
					// flip the transform (if inverted and mirroring is
					// not permitted) around the axis that would be more
					// appropriate to flip around - the one which would
					// get the transform getting closest to right-side-up
					if (!_negativeScaling && !isPositiveScale(_baseMatrix)){
						var baseRotation:Number = Math.atan2(_baseMatrix.a + _baseMatrix.c, _baseMatrix.d + _baseMatrix.b);
						if (baseRotation < -(3*Math.PI/4) || baseRotation > (Math.PI/4)){
							_calculatedMatrix.c = -_calculatedMatrix.c;
							_calculatedMatrix.d = -_calculatedMatrix.d;
						}else{
							_calculatedMatrix.a = -_calculatedMatrix.a;
							_calculatedMatrix.b = -_calculatedMatrix.b;
						}
					}
				}
			}
		}
		
		/**
		 * For zero-scale transformations, this function will reset
		 * the base scale to represent a positive value represented
		 * by the amount value.  This would be needed if transformations 
		 * expect a non-zero scale, for example if scaling the existing
		 * scale which, if zero, would not scale at all.
		 * @param amount The amount by which the base transformation
		 * is normalized in scale.  This amount is a pixel value based
		 * on the internal bounds of the target object.
		 * @return True if the base transform was normalized at all, 
		 * false if no changes were made.
		 */
		public function normalizeBase(amount:Number = 1):Boolean {
			if (_target == null){
				return false;
			}
			
			var changed:Boolean = false;
			
			var bounds:Rectangle = _target.getBounds(_target);
			if (bounds.width != 0 && bounds.height != 0){
				
				if (_baseMatrix.a == 0 && _baseMatrix.b == 0){
					_baseMatrix.a = amount/bounds.width;
					changed = true;
				}
				
				if (_baseMatrix.d == 0 && _baseMatrix.c == 0){
					_baseMatrix.d = amount/bounds.height;
					changed = true;
				}
			}
			
			return changed;
		}
		
		/**
		 * Retrieves the current registration point from the registration
		 * manager assigning it to localRegistration.
		 */
		protected function retrieveRegistration():void {
			var saved:Point = _registrationManager.getRegistration(_target);
			if (saved != null){
				_localRegistration.x = saved.x;
				_localRegistration.y = saved.y;
			}else{
				_localRegistration.x = 0;
				_localRegistration.y = 0;
			}
		}
		
		/**
		 * Saves the current registration point value in localRegistration to
		 * the registration manager.
		 */
		public function saveRegistration():void {
			_registrationManager.setRegistration(_target, _localRegistration);
		}
		
		/**
		 * Adds registration offset to transformation matrix. This
		 * assumes deriveFinalTransform has already been called.
		 */
		protected function applyRegistrationOffset():void {
			
			// update localRegistration from the registration manager
			retrieveRegistration();
			
			if (_localRegistration.x != 0 || _localRegistration.y != 0){
				
				// the registration offset is the change in x and y
				// of the pseudo registration point since the 
				// transformation occurred.  At this point, the final
				// transform should all ready be calculated
				var reg:Point = _baseMatrix.deltaTransformPoint(_localRegistration);
				var regOffset:Point = _calculatedMatrix.deltaTransformPoint(_localRegistration);
				regOffset = reg.subtract(regOffset);
				_calculatedMatrix.translate(regOffset.x, regOffset.y);
			}
		}
		
		// RESTRICTIONS
		
		/**
		 * Goes under the assumption that scaling is handled by
		 * the preTransform and rotation is handled by the
		 * postTransform matrices.
		 */
		protected function restrict(enforceNegativeScaling:Boolean = true):void {
			
			// dispatch a cancelable RESTRICT event.
			// if the event is canceled, don't perform
			// the restict operations. Controls may do
			// this if they want to implement restrictions
			// on their own and not have interference
			// from the normal tool operations
			var restrictEvent:Event = new Event(RESTRICT, false, true);
			dispatchEvent(restrictEvent);
			if (restrictEvent.isDefaultPrevented()){
				return;
			}
			
			restrictScale(enforceNegativeScaling);
			restrictRotation();
		}
		
		/**
		 * Applies restrictions to scaling.
		 * @param	enforceNegativeScaling When false, the value of negativeScaling
		 * is not enforced when restricting scale. This should be set to false when
		 * rotating a the Transform Tool since rotation can result in what could be
		 * considered a negative scale.
		 */
		public function restrictScale(enforceNegativeScaling:Boolean = true):void {
			var bounds:Rectangle = _target.getBounds(_target);
			
			// cannot scale an object with no size
			if (bounds.width == 0 || bounds.height == 0){
				return;
			}
			
			// find the values of min and max to use for
			// scale.  Since these can come from either
			// width/height or scaleX/scaleY, both are
			// first checked for a value and then, if both
			// are set, the smallest variation is used.
			// if neither are set, the value will be
			// defined as NaN.
			
			var minX:Number;
			if (isNaN(_minWidth)){
				minX = _minScaleX;
			}else{
				if (isNaN(_minScaleX)){
					minX = _minWidth/bounds.width;
				}else{
					minX = Math.max(_minScaleX, _minWidth/bounds.width);
				}
			}
			
			var maxX:Number;
			if (isNaN(_maxWidth)){
				maxX = _maxScaleX;
			}else{
				if (isNaN(_maxScaleX)){
					maxX = _maxWidth/bounds.width;
				}else{
					maxX = Math.min(_maxScaleX, _maxWidth/bounds.width);
				}
			}
			
			var minY:Number;
			if (isNaN(_minHeight)){
				minY = _minScaleY;
			}else{
				if (isNaN(_minScaleY)){
					minY = _minHeight/bounds.height;
				}else{
					minY = Math.max(_minScaleY, _minHeight/bounds.height);
				}
			}
			
			var maxY:Number;
			if (isNaN(_maxHeight)){
				maxY = _maxScaleY;
			}else{
				if (isNaN(_maxScaleY)){
					maxY = _maxHeight/bounds.height;
				}else{
					maxY = Math.min(_maxScaleY, _maxHeight/bounds.height);
				}
			}
			
			// make sure each limit is positive
			if (minX < 0) minX = -minX;
			if (maxX < 0) maxX = -maxX;
			if (minY < 0) minY = -minY;
			if (maxY < 0) maxY = -maxY;
			
			var currScaleX:Number = Math.sqrt(_calculatedMatrix.a*_calculatedMatrix.a + _calculatedMatrix.b*_calculatedMatrix.b);
			var currScaleY:Number = Math.sqrt(_calculatedMatrix.c*_calculatedMatrix.c + _calculatedMatrix.d*_calculatedMatrix.d);
			
			// if negative scaling is not allowed
			// we need to figure out if the current scale
			// in either direction is going into the
			// negatives or not.  To do this, the angle
			// of each axis is compared against the base
			// transform angles
			if (enforceNegativeScaling && !_negativeScaling){
				var currAngleX:Number = Math.atan2(_calculatedMatrix.b, _calculatedMatrix.a);
				var baseAngleX:Number = Math.atan2(_baseMatrix.b, _baseMatrix.a);
				if (currScaleX != 0 && Math.abs(baseAngleX - currAngleX) > Math.PI/2){
					currScaleX = -currScaleX;
				}
				var currAngleY:Number = Math.atan2(_calculatedMatrix.c, _calculatedMatrix.d);
				var baseAngleY:Number = Math.atan2(_baseMatrix.c, _baseMatrix.d);
				if (currScaleY != 0 && Math.abs(baseAngleY - currAngleY) > Math.PI/2){
					currScaleY = -currScaleY;
				}
			}
			
			
			var scale:Number; // limited scale; NaN if not scaling
			var angle:Number; // angle of scale when basing on base
			
			if (!isNaN(minX) && currScaleX < minX){
				scale = minX;
			}else if (!isNaN(maxX) && currScaleX > maxX){
				scale = maxX;
			}else{
				scale = Number.NaN;
			}
			
			if (!isNaN(scale)){
				if (currScaleX){
					scale = (scale/currScaleX);
					_calculatedMatrix.a *= scale;
					_calculatedMatrix.b *= scale;
				}else{
					angle = Math.atan2(_baseMatrix.b, _baseMatrix.a);
					_calculatedMatrix.a = scale * Math.cos(angle);
					_calculatedMatrix.b = scale * Math.sin(angle);
				}
			}
			
			if (!isNaN(minY) && currScaleY < minY){
				scale = minY;
			}else if (!isNaN(maxY) && currScaleY > maxY){
				scale = maxY;
			}else{
				scale = Number.NaN;
			}
			
			if (!isNaN(scale)){
				if (currScaleY){
					scale = (scale/currScaleY);
					_calculatedMatrix.c *= scale;
					_calculatedMatrix.d *= scale;
				}else{
					angle = Math.atan2(_baseMatrix.c, _baseMatrix.d);
					_calculatedMatrix.c = scale * Math.sin(angle);
					_calculatedMatrix.d = scale * Math.cos(angle);
				}
			}
			
			// undo any negative scaling
			if (enforceNegativeScaling && !_negativeScaling && !isPositiveScale(_calculatedMatrix)){
				
				// flip the final transform around the axis 
				// to best match the base
				var baseX:Number = _baseMatrix.a + _baseMatrix.c;
				var toolX:Number = _calculatedMatrix.a + _calculatedMatrix.c;
				if ((toolX < 0 && baseX >= 0) || (toolX >= 0 && baseX < 0)){
					_calculatedMatrix.a = -_calculatedMatrix.a;
					_calculatedMatrix.b = -_calculatedMatrix.b;
				}else{
					_calculatedMatrix.c = -_calculatedMatrix.c;
					_calculatedMatrix.d = -_calculatedMatrix.d;
				}
			}
		}
		
		/**
		 * Applies restrictions to rotation.
		 */
		public function restrictRotation():void {
			// both min and max rotation need to be set
			// in order to restrict rotation
			
			if (!isNaN(_minRotation) && !isNaN(_maxRotation)){
				var min:Number = _minRotation * (Math.PI/180);
				var max:Number = _maxRotation * (Math.PI/180);
				
				var angle:Number = Math.atan2(_calculatedMatrix.b, _calculatedMatrix.a);
				
				// restrict to a single rotation value
				if (min == max){
					if (angle != min){
						setRotation(min);
					}
					
				// restricting to a range
				}else if (min < max){
					if (angle < min){
						setRotation(min);
					}else if (angle > max){
						setRotation(max);
					}
				}else if (angle < min && angle > max){
					if (Math.abs(angle - min) > Math.abs(angle - max)){
						setRotation(max);
					}else{
						setRotation(min);
					}
				}
			}
		}
		
		// HELPER FUNCTIONS
		
		/**
		 * Determines if a matrix is scaled positively or not.
		 * @param	matrix The matrix to determine if it is positively scaled.
		 * If not specified, calculatedMatrix is used.
		 * @return Returns true if the matrix is positively scaled, false if 
		 * not.
		 */
		public function isPositiveScale(matrix:Matrix = null):Boolean {
			if (matrix == null) matrix = _calculatedMatrix;
			return Boolean(matrix.a*matrix.d - matrix.c*matrix.b > 0);
		}
		
		/**
		 * Compares two matrices to see if they're equal.
		 * @param	m1 A matrix to be compared with another matrix.
		 * @param	m2 The matrix to be compared with the first matrix.
		 * If this value is not provided calculatedMatrix is used.
		 * @return True if the matrices match, false if not.
		 */
		public function matrixEquals(m1:Matrix, m2:Matrix = null):Boolean {
			if (m2 == null) m2 = _calculatedMatrix;
			if (m1.a != m2.a
			||  m1.d != m2.d
			||  m1.b != m2.b
			||  m1.c != m2.c
			||  m1.tx != m2.tx
			||  m1.ty != m2.ty){
				return false;
			}
			return true;
		}
		
		/**
		 * Returns the rotation of target object based on the current value
		 * of calculatedMatrix. A matrix's general rotation is based on the 
		 * rotation of its x axis.  
		 * @param	matrix The matrix from which to find a rotation. If not
		 * specified, calculatedMatrix is used.
		 * @return The rotation of a matrix in radians.
		 */
		public function getRotation():Number {
			return getRotationX(null);
		}
		
		/**
		 * Returns the rotation of a matrix on its x axis.
		 * @param	matrix The matrix from which to find a rotation. If not
		 * specified, calculatedMatrix is used.
		 * @return The rotation of a matrix along it's x axis in radians.
		 */
		public function getRotationX(matrix:Matrix = null):Number {
			if (matrix == null) matrix = _calculatedMatrix;
			return Math.atan2(matrix.b, matrix.a);
		}
		
		/**
		 * Returns the rotation of a matrix on its y axis.
		 * @param	matrix The matrix from which to find a rotation. If not
		 * specified, calculatedMatrix is used.
		 * @return The rotation of a matrix along it's y axis in radians.
		 */
		public function getRotationY(matrix:Matrix = null):Number {
			if (matrix == null) matrix = _calculatedMatrix;
			return Math.atan2(matrix.c, matrix.d);
		}
		
		/**
		 * Sets the rotation of a matrix. The rotation set is based on the x 
		 * axis. 
		 * @param	value A new rotation value in radians.
		 * @param	matrix The matrix on which to set a rotation. If not
		 * specified, calculatedMatrix is used.
		 */
		public function setRotation(value:Number, matrix:Matrix = null):void {
			if (isNaN(value)) return;
			if (matrix == null) matrix = _calculatedMatrix;
			
			var tx:Number = matrix.tx;
			var ty:Number = matrix.ty;
			var angle:Number = Math.atan2(matrix.b, matrix.a);
			matrix.rotate(value - angle);
			matrix.tx = tx;
			matrix.ty = ty;
		}
		
		/**
		 * Returns the scale of a matrix along its x axis.
		 * @param	matrix The matrix from which to get the scale. If not
		 * specified, calculatedMatrix is used.
		 * @return The scale of a matrix along its x axis.
		 */
		public function getScaleX(matrix:Matrix = null):Number {
			if (matrix == null) matrix = _calculatedMatrix;
			return Math.sqrt(_calculatedMatrix.a*_calculatedMatrix.a + _calculatedMatrix.b*_calculatedMatrix.b);
		}
		
		/**
		 * Sets the scale of a matrix along its x axis.
		 * @param	matrix The matrix for which to set a scale. If not
		 * specified, calculatedMatrix is used.
		 */
		public function setScaleX(value:Number, matrix:Matrix = null):void {
			if (isNaN(value)) return;
			if (matrix == null) matrix = _calculatedMatrix;
			
			var angle:Number = Math.atan2(matrix.b, matrix.a);
			matrix.a = value * Math.cos(angle);
			matrix.b = value * Math.sin(angle);
		}
		
		/**
		 * Returns the scale of a matrix along its y axis.
		 * @param	matrix The matrix from which to get the scale. If not
		 * specified, calculatedMatrix is used.
		 * @return The scale of a matrix along its y axis.
		 */
		public function getScaleY(matrix:Matrix = null):Number {
			if (matrix == null) matrix = _calculatedMatrix;
			return Math.sqrt(_calculatedMatrix.c*_calculatedMatrix.c + _calculatedMatrix.d*_calculatedMatrix.d);
		}
		
		/**
		 * Sets the scale of a matrix along its y axis.
		 * @param	matrix The matrix for which to set a scale. If not
		 * specified, calculatedMatrix is used.
		 */
		public function setScaleY(value:Number, matrix:Matrix = null):void {
			if (isNaN(value)) return;
			if (matrix == null) matrix = _calculatedMatrix;
			
			var angle:Number = Math.atan2(matrix.c, matrix.d);
			matrix.c = value * Math.sin(angle);
			matrix.d = value * Math.cos(angle);
		}
		
		/**
		 * Returns the width of the target object based on its size within
		 * its transformed x axis and the current value of calculatedMatrix.
		 * This is different from the normal width reported by DisplayObject
		 * which is based on the width of the object within its parent's
		 * coordinate space. If no target exists 0 is returned.
		 * @return The height of the target object.
		 */
		public function getWidth():Number {
			if (_target == null){
				return 0;
			}
			
			var bounds:Rectangle = _target.getBounds(_target);
			return bounds.width * getScaleX(_calculatedMatrix);
		}
		
		/**
		 * Sets the width of calculatedMatrix based on the size of the 
		 * current target. If target is null or the value passed is not a
		 * number, calculatedMatrix is unchanged.
		 * @param	value The height value for the target object.
		 */
		public function setWidth(value:Number):void {
			if (_target == null || isNaN(value)){
				return;
			}
			
			var bounds:Rectangle = _target.getBounds(_target);
			var ratio:Number = Math.abs(value)/bounds.width;
			ratio /= getScaleX(_calculatedMatrix);
			calculatedMatrix.a *= ratio;
			calculatedMatrix.b *= ratio;
		}
		
		/**
		 * Returns the height of the target object based on its size within
		 * its transformed y axis and the current value of calculatedMatrix.
		 * This is different from the normal height reported by DisplayObject
		 * which is based on the height of the object within its parent's
		 * coordinate space. If no target exists 0 is returned.
		 * @return The height of the target object.
		 */
		public function getHeight():Number {
			if (_target == null){
				return 0;
			}
			
			var bounds:Rectangle = _target.getBounds(_target);
			return bounds.height * getScaleY(_calculatedMatrix);
		}
		
		/**
		 * Sets the height of calculatedMatrix based on the size of the 
		 * current target. If target is null or the value passed is not a
		 * number, calculatedMatrix is unchanged.
		 * @param	value The height value for the target object.
		 */
		public function setHeight(value:Number):void {
			if (_target == null || isNaN(value)){
				return;
			}
			
			var bounds:Rectangle = _target.getBounds(_target);
			var ratio:Number = Math.abs(value)/bounds.height;
			ratio /= getScaleY(_calculatedMatrix);
			calculatedMatrix.c *= ratio;
			calculatedMatrix.d *= ratio;
		}
	}
}