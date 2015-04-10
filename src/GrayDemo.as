package
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.errors.IllegalOperationError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	/**
	 * 灰度demo
	 * @author kzj
	 * @time 2015-04-09
	 */	
	[SWF(backgroundColor="#F0F0F0", width="500", height="400", frameRate="60")]
	public class GrayDemo extends Sprite
	{
		private static var _demo:GrayDemo;
		private var _stage3D:Stage3D;
		private var _context3D:Context3D;
		private var _bmp:Bitmap;
		private var _vb:VertexBuffer3D;
		private var _ib:IndexBuffer3D;
		private var _texture:Texture;
		private var _pm:Program3D;
		public function GrayDemo()
		{
			if( _demo == null )
				init();
			else
				this.addEventListener( Event.ADDED_TO_STAGE, init );
		}
		
		/**
		 * 初始化数据 
		 * @param evt 事件对象
		 * @author kzj
		 * @time 2015-04-09
		 */		
		private function init( evt:Event = null ):void
		{
			_demo = this;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.stage.align = StageAlign.TOP_LEFT;
			this.removeEventListener( Event.REMOVED_FROM_STAGE, init );
			
			initStage3D();
			initRes();
		}

		/**
		 * 初始化资源 
		 * @author kzj
		 * @time 2015.04.09
		 */		
		private function initRes():void
		{
			var url:URLRequest = new URLRequest( "icon.png" );
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.addEventListener( Event.COMPLETE, onUrlLoaderComplete );
			urlLoader.addEventListener( ProgressEvent.PROGRESS, onProgress );
			urlLoader.addEventListener( ErrorEvent.ERROR, onError );
			urlLoader.load( url );
		}
		
		/**
		 * 加载出错 
		 * @param evt 事件对象
		 * @author kzj
		 * @time 2015.04.09
		 */		
		private function onError( evt:ErrorEvent ):void
		{
			trace( evt.text );
		}
		
		/**
		 * 使用urlLoader加载图片 
		 * @param evt 事件对象
		 * @author kzj
		 * @time 2015.04.09
		 */		
		private function onUrlLoaderComplete( evt:Event ):void
		{
			var data:ByteArray = ( evt.target as URLLoader ).data;
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onLoaderComplete );
			loader.contentLoaderInfo.addEventListener( ProgressEvent.PROGRESS, onProgress );
			loader.contentLoaderInfo.addEventListener( ErrorEvent.ERROR, onError );
			loader.contentLoaderInfo.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onError );
			loader.loadBytes( data );
		}
		
		/**
		 * 显示进度加载 
		 * @param evt
		 * 
		 */		
		private function onProgress( evt:ProgressEvent ):void
		{
			trace( "加载进度： " + evt.bytesLoaded + " / " + evt.bytesTotal );
		}
		
		/**
		 * 使用Loader解析加载完成 
		 * @param evt 事件对象
		 * @author kzj
		 * @time 2015.04.09
		 */		
		private function onLoaderComplete( evt:Event ):void
		{
			_bmp = ( evt.target as LoaderInfo ).content as Bitmap;
			_bmp.x = 303;
			this.addChild( _bmp );
			
			testGrayImage();
		}
		
		/**
		 * 初始化3d通道 
		 * @author kzj
		 * @time 2015.04.09
		 */		
		private function initStage3D():void
		{
			var stage3DList:Vector.<Stage3D> = this.stage.stage3Ds;
			if( stage3DList.length < 1 )
			{
				throw new Error( "no hardware accelerate" );
				return;
			}
			
			this._stage3D = stage3DList[0];
			this._stage3D.addEventListener( Event.CONTEXT3D_CREATE, onContext3DCreate );
			this._stage3D.requestContext3D( Context3DRenderMode.AUTO );
		}
		
		/**
		 * 创建3D环境成功 
		 * @param evt 事件对象
		 * @author kzj
		 * @time 2015.04.09
		 */		
		private function onContext3DCreate( evt:Event ):void
		{
			_context3D = this._stage3D.context3D;
			trace( _context3D.driverInfo );
			
			_context3D.configureBackBuffer( 300, 300, 0 );
		}
		
		/**
		 * 测试灰度图片 
		 * @author kzj
		 * @time 2015.04.09
		 */		
		private function testGrayImage():void
		{
			initData();
			
			initAGAL();
			
			draw();
		}
		
		/**
		 * 画出3d通道图片 
		 * @author kzj
		 * @time 2015.04.09
		 */		
		private function draw():void
		{
			this._context3D.setTextureAt( 0, this._texture );
			this._context3D.setProgram( this._pm );
			this._context3D.setVertexBufferAt( 0, this._vb, 0, Context3DVertexBufferFormat.FLOAT_2 );
			this._context3D.setVertexBufferAt( 1, this._vb, 2, Context3DVertexBufferFormat.FLOAT_2 );
			this._context3D.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 1, new <Number>[ 0.3, 0.59, 0.11, 0 ] );
			
			fresh();
		}
		
		/**
		 * 刷新画面 
		 * @param evt 事件对象
		 * @author kzj
		 * @time 2015.04.09
		 */		
		private function fresh( evt:Event = null ):void
		{
			this._context3D.clear( 0, 0, 0, 0 );
			this._context3D.drawTriangles( this._ib );
			this._context3D.present();
		}
		
		/**
		 * 初始化agal 
		 * @author kzj
		 * @time 2015.04.09
		 */		
		private function initAGAL():void
		{
			//顶点汇编代码
			var vagalcode:String = "mov op, va0\n" +
								   "mov v0, va1";
			var vagal:AGALMiniAssembler = new AGALMiniAssembler();
			vagal.assemble( Context3DProgramType.VERTEX, vagalcode );
			
			//着色器汇编代码
			var fagalcode:String = "tex ft0, v0, fs0 <2d, linear, nomip>\n" +
								   "mul ft1.x, ft0.x, fc1.x\n" + 
								   "mul ft1.y, ft0.y, fc1.y\n" + 
								   "mul ft1.z, ft0.z, fc1.z\n" + 
								   "add ft1.w, ft1.x, ft1.y\n" + 
								   "add ft1.w, ft1.w, ft1.z\n" +
								   "mov ft0.x, ft1.w\n" +
								   "mov ft0.y, ft1.w\n" +
								   "mov ft0.z, ft1.w\n" +
								   "mov oc, ft0";
			var fagal:AGALMiniAssembler = new AGALMiniAssembler();
			fagal.assemble( Context3DProgramType.FRAGMENT, fagalcode );
			
			//上传agal
			this._pm = this._context3D.createProgram();
			this._pm.upload( vagal.agalcode, fagal.agalcode );
		}
		
		/**
		 * 初始化数据 
		 * @author kzj
		 * @time 2015.04.09
		 */		
		private function initData():void
		{
			//上传顶点数据
			var vbData:Vector.<Number> = new <Number>[
				// x, y, u, v
				0, 0, 0, 1,
				0, 1, 0, 0,
				1, 1, 1, 0,
				1, 0, 1, 1
			]; //顶点数据
			this._vb = this._context3D.createVertexBuffer( vbData.length / 4, 4 );
			this._vb.uploadFromVector( vbData, 0, 4 );
			
			//上传顶点渲染顺序
			var ibData:Vector.<uint> = new <uint>[
				// 顶点索引
				0, 1, 3,
				1, 2, 3
			];
			this._ib = this._context3D.createIndexBuffer( ibData.length );
			this._ib.uploadFromVector( ibData, 0, ibData.length );
			
			//上传纹理
			this._texture = this._context3D.createTexture( 64, 64, Context3DTextureFormat.BGRA, true );
			this._texture.uploadFromBitmapData( this._bmp.bitmapData );
		}
	}
}