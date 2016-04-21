package {

import com.furusystems.dconsole2.DConsole;
import com.furusystems.dconsole2.plugins.StatsOutputUtil;
import com.furusystems.logging.slf4as.Logging;

import flash.desktop.NativeApplication;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageDisplayState;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.filesystem.File;
import flash.net.Socket;
import flash.utils.setTimeout;

import utils.ErrorLogger;

[SWF(width="800", height="600", backgroundColor="#FFFFFF", frameRate="60")]
public class Main extends Sprite {

	public function Main() {
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		stage.addEventListener( Event.RESIZE, onStageResize );
		init();
	}

	private function init():void {
		// setup an error logger, just in case.
		ErrorLogger.logFile = File.desktopDirectory.resolvePath( "error_logs.txt" );

		addChild( DConsole.view );
		DConsole.registerPlugins( StatsOutputUtil );
		DConsole.show();
		DConsole.setMagicSequence( [] );
		DConsole.clear();
		// -- map some commands.

		Logging.root.info( "So, this is how it works... \ntype \"cmd\" on the input (press TAB to focus) to have an idea of the commands" );

		// type "cmd" to have an idea of what's available.
		// fs > toggles fullscren.
		// exit > quit the app
		// ... etc
		createCmd( ["exit","quit"], exit, "quit the app; exit | quit") ;
		createCmd( ["fs","fullscreen"], toggleFullscreen, "toggles the fullscreen; fs | fullscreen" );
		createCmd( ["exec","open"], openFile, "executes a file; open | exec \"filepath\"" );
		createCmd( ["connect","socketConnect"], connectSocket, "creates a TCP socket connection in $host(localhost):$port; connect|socketConnect port(int) ?host(string)" );
		createCmd( ["close","socketClose"], closeSocket, "closes the current connected socket; close | socketClose" );
		createCmd( ["send","socketSend"], socketSendMessage, "sends a utf message to the server; send | socketSend [\"message\"]" );
	}

	//===================================================================================================================================================
	//
	//      ------  socket stuffs
	//
	//===================================================================================================================================================

	private var socket:Socket;

	public function closeSocket():void {
		if ( !socket ) {
			error( "No sockets availble" );
			return;
		}
		if ( !socket.connected ) {
			info( "Socket is currently NOT connected." );
			return;
		}
		socket.close();
		info( "...closing the socket" );
		// force the close, if the server doesnt close the session.
		setTimeout( onSocketClose, 500, null );
	}

	public function connectSocket( port:int = 0, host:String = "127.0.0.1" ):void {
		if ( port <= 0 ) {
			error( "socketConnect requires a valid [port](Int) ?host(String)" );
			return;
		}
		if ( socket && socket.localPort == port && socket.connected ) {
			info( "socket already connected" );
			return;
		}
		socket = new Socket();
		socket.addEventListener( Event.CONNECT, onSocketConnect, false, 0, true );
		socket.addEventListener( Event.CLOSE, onSocketClose, false, 0, true );
		socket.addEventListener( IOErrorEvent.IO_ERROR, onSocketError, false, 0, true );
		socket.addEventListener( ProgressEvent.SOCKET_DATA, onServerData, false, 0, true );
		socket.addEventListener( SecurityErrorEvent.SECURITY_ERROR, trace, false, 0, true );
		try {
			socket.connect( host, port );
		} catch( e:Error ){
			// there's an error on connection, dispose the socket
			fatal( "Socket connect() error = " + e.message + "\n");
			socket.close() ;
			disposeSocket() ;
		}
		info( "creating a new socket connection on " + host + ":" + port );
	}

	private function onServerData( event:ProgressEvent ):void {
		var read:String = socket.readUTFBytes( socket.bytesAvailable );
		// in a real world scenario, we have to analyze the data
		// to make sense out of it.
		info( "Server data recieved=", read );
	}

	private function onSocketError( event:IOErrorEvent ):void {
		error( "Socket Error=" + event.toString() );
		error( "... disposing socket.") ;
		if( socket.connected )
			socket.close() ;
		setTimeout( onSocketClose, 500, null );
//		disposeSocket() ;
	}

	private function onSocketClose( event:Event ):void {
		debug( "Socket closed." );
		disposeSocket();
	}

	private function onSocketConnect( event:Event ):void {
		info( "Socket connected!\nYou can send a message now: [ send|socketSend \"hiserver\" ]" );
//		socketSendMessage( "hiserver" ) ;
	}

	private function socketSendMessage( message:String = "" ):void {
		if( !message ){
			error( "socketSend requires an argument with the message") ;
			return ;
		}
		// Check if Dennis' server requires an EOF key or something at the end of the string
		// to dinstinguish the packets. (like charCode(0) NULL.
		if ( !socket || !socket.connected ) {
			error( "socketSendMessage() requires an existent/connected socket.\nUse connect|socketConnect to create a new connection." );
			return;
		}
		socket.writeUTFBytes( message );
		socket.flush();
	}

	private function disposeSocket():void {
		// leave the socket for GC...
		if ( !socket ) return;
		socket.removeEventListener( Event.CONNECT, onSocketConnect );
		socket.removeEventListener( Event.CLOSE, onSocketClose );
		socket.removeEventListener( IOErrorEvent.IO_ERROR, onSocketError );
		socket.removeEventListener( ProgressEvent.SOCKET_DATA, onServerData );
		socket.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, trace );
		socket = null;
	}

	//===================================================================================================================================================
	//
	//      ------  app execution
	//
	//===================================================================================================================================================

	public function openFile( appPath:String = "" ):void {
		if ( !appPath ) {
			error( "open requires a filepath as a parameter" );
			return;
		}
		if ( appPath.indexOf( File.separator ) == -1 ) {
			error( "open invalid filepath" );
			return;
		}

		var file:File = new File();
		file.nativePath = appPath;
		if ( !file.exists ) {
			error( "File '" + appPath + "' doesn't exists" );
			return;
		}
		info( "Executing program... " );
		setTimeout( function () {
			file.openWithDefaultApplication();
		}, 500 );
	}

	private function exit():void {
		debug( "Quitting app in 1 sec." );
		setTimeout( function () {
			NativeApplication.nativeApplication.exit();
		}, 1000 );
	}

	private function toggleFullscreen():void {
		if ( stage.displayState != StageDisplayState.NORMAL ) {
			stage.displayState = StageDisplayState.NORMAL;
			debug( "Normal screen mode" );
		} else {
			stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			debug( "Fullscreen mode" );
		}
	}

	private function onStageResize( event:Event ):void {
		debug( "Stage resize=" + stage.stageWidth + "x" + stage.stageHeight );
	}


	//===================================================================================================================================================
	//
	//      ------  UTILS
	//
	//===================================================================================================================================================

	// factory/utility to create several commands for the same callback.
	private function createCmd( exec:*, fun:Function, description:String ): void {
		var arr:Array = exec as Array ;
		if( exec is String ) arr = [exec] ;
		for each( var cmd:String in arr ) DConsole.createCommand( cmd, fun, "APP", description );
	}

	// --- LOG methods for the console.

	private function warn( ...args ):void {
		Logging.root.warn.apply( this, args );
	}

	private function fatal( ...args ):void {
		Logging.root.fatal.apply( this, args );
	}

	private function error( ...args ):void {
		Logging.root.error.apply( this, args );
	}

	private function debug( ...args ):void {
		Logging.root.debug.apply( this, args );
	}

	private function info( ...args ):void {
		Logging.root.info.apply( this, args );
	}

}
}
