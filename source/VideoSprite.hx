
#if web
import openfl.net.NetConnection;
import openfl.net.NetStream;
import openfl.events.NetStatusEvent;
import openfl.media.Video;
#else
import openfl.events.Event;
import vlc.VlcBitmap;
#end
import openfl.display.BitmapData;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;

/**
 *  Displays a MP4 video as a flixel sprite, a modification of FlxVideo from Poly Engine
 */
class VideoSprite extends FlxSprite {
	#if VIDEOS_ALLOWED
	public var finishCallback:Void->Void = null;
	public var wasAdded:Bool = false; // lua
	public var muted:Bool=false;
	public var volume(default, set):Float=1;
	#if desktop
	public var vlcBitmap:VlcBitmap;
    #elseif web
    public var player:Video;
	#end
		
	function set_volume(value:Float)
	{
		if (value>1) {
			value=1;
		}
		else if(value<0) {
			value=0;
		}
		volume=value;
		return volume;
	}

	public function new(name:String, X:Float, Y:Float) {
		super(X,Y);
		antialiasing = ClientPrefs.globalAntialiasing;

		#if web
		player = new Video();
		player.x = 0;
		player.y = 0;
		var netConnect = new NetConnection();
		netConnect.connect(null);
		var netStream = new NetStream(netConnect);
		netStream.client = {
			onMetaData: function() {
				player.attachNetStream(netStream);
				player.width = 720;
				player.height = 1280;
			}
		};
		netConnect.addEventListener(NetStatusEvent.NET_STATUS, function(event:NetStatusEvent) {
			if(event.info.code == "NetStream.Play.Complete") {
				netStream.dispose();
				if(finishCallback != null) finishCallback();
			}
		});
		netStream.play(name);

		#elseif desktop
		
		vlcBitmap = new VlcBitmap();
		vlcBitmap.set_height(720);
		vlcBitmap.set_width(1280);

		vlcBitmap.onComplete = onVLCComplete;
		vlcBitmap.onError = onVLCError;

		FlxG.stage.addEventListener(Event.ENTER_FRAME, fixVolume);
		vlcBitmap.repeat = -1;
		vlcBitmap.inWindow = false;
		vlcBitmap.fullscreen = false;
		fixVolume(null);

		vlcBitmap.play(checkFile(name));
		#end
		//create new canvas for the MP4
		pixels = new BitmapData(1280, 720, false, 0xFF000000);
	}
    
    override public function draw()
    {
        #if web
		if(player!=null)
			pixels.draw(player);
        #elseif desktop
		if(vlcBitmap!=null)
			pixels.draw(vlcBitmap);
		#end
		
        super.draw();
    }

	#if desktop
	function checkFile(fileName:String):String
	{
		var pDir = "";
		var appDir = "file:///" + Sys.getCwd() + "/";

		if (fileName.indexOf(":") == -1) // Not a path
			pDir = appDir;
		else if (fileName.indexOf("file://") == -1 || fileName.indexOf("http") == -1) // C:, D: etc? ..missing "file:///" ?
			pDir = "file:///";

		return pDir + fileName;
	}
	
	public function resume() {
		if(vlcBitmap != null) {
			vlcBitmap.resume();
		}
	}
	
	public function pause() {
		if(vlcBitmap != null) {
			vlcBitmap.pause();
		}
	}

	function fixVolume(e:Event)
	{
		// shitty volume fix
		vlcBitmap.volume = 0;
		if(!FlxG.sound.muted && FlxG.sound.volume > 0.01 && !muted) { //Kind of fixes the volume being too low when you decrease it
			vlcBitmap.volume = (FlxG.sound.volume * 0.5 + 0.5) * volume;
		}
	}

	public function onVLCComplete()
	{
		vlcBitmap.stop();

		// Clean player, just in case!
		vlcBitmap.dispose();

		if (finishCallback != null)
		{
			finishCallback();
		}
	}

	
	function onVLCError()
		{
			trace("An error has occured while trying to load the video.\nPlease, check if the file you're loading exists.");
			if (finishCallback != null) {
				finishCallback();
			}
		}
	#end
	#end
}
