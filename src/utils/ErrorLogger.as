/**
 * Code by Rodrigo López Peker on 12/10/15 11:15 AM.
 *
 */
package utils {

import flash.display.LoaderInfo;
import flash.events.ErrorEvent;
import flash.events.UncaughtErrorEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.getTimer;

public class ErrorLogger {

	public static var logFile:File = null;

	public function ErrorLogger() {
	}

	public static function init( loader:LoaderInfo ):void {
		loader.uncaughtErrorEvents.addEventListener( UncaughtErrorEvent.UNCAUGHT_ERROR, handleUncaughtError );
		// device info here.
	}

	private static function handleUncaughtError( event:UncaughtErrorEvent ):void {
		event.preventDefault();
		var msg:String = "[UNCAUGHT] ";
		if ( event.error is Error ) {
			log( msg + event.error.name, event.error.getStackTrace() );
		} else if ( event.error is ErrorEvent ) {
			log( msg + "code=" + ErrorEvent( event.error ).errorID + " message=" + ErrorEvent( event.error ).text );
		} else {
			log( msg + " str=" + event.error.toString() );
		}
	}

	private static var _fs:FileStream = new FileStream();
	private static var ERROR_LOG_SEPARATION:String = "----------------------------------";
	private static var _logInitTime:Number;
	private static var _logDateTime:Number;
	private static var _logDate:Date;

	public static function log( ...args ):void {
		if ( !_logDate ) {
			_logDate = new Date();
			_logDateTime = _logDate.time;
			_logInitTime = getTimer();
		}
		trace( "ERROR:", args );
		// flush to disk
		if ( logFile ) {
			var msg:String = getCurrentTime() + args.join( " " ) + "\n\n" + ERROR_LOG_SEPARATION + "\n\n";
			_fs.open( logFile, FileMode.APPEND );
			_fs.writeUTFBytes( msg );
			_fs.close();
		}
	}


	private static function getCurrentTime():String {
		var ct:Number = _logDateTime + ( getTimer() - _logInitTime );
		_logDate.setTime( ct );
		var currentTime:String = "time "
				+ timeToValidString( _logDate.getHours() )
				+ ":"
				+ timeToValidString( _logDate.getMinutes() )
				+ ":"
				+ timeToValidString( _logDate.getSeconds() )
				+ "."
				+ timeToValidString( _logDate.getMilliseconds() ) + " :: ";
		return currentTime;
	}

	private static function timeToValidString( timeValue:Number ):String {
		return timeValue > 9 ? timeValue.toString() : "0" + timeValue.toString();
	}

}
}
