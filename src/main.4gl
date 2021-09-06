IMPORT os
IMPORT util
IMPORT FGL fgldialog

CONSTANT C_CFG_FILE = "ros.cfg"
CONSTANT C_CFG_SERVER = "generodemos.dynu.net"
CONSTANT C_CFG_GASALIAS = "z"
CONSTANT C_CFG_APP = "mobDemo"

DEFINE m_isMobile BOOLEAN = FALSE
DEFINE m_cfgPath STRING
DEFINE m_logFile STRING
DEFINE m_log STRING
DEFINE m_url STRING
DEFINE m_dbname STRING
DEFINE m_ip STRING
MAIN
	DEFINE l_res  STRING
	DEFINE l_cli  STRING

	LET l_cli = ui.interface.getFrontEndName()||" "||ui.Interface.getFrontEndVersion()
	IF l_cli.subString(1, 2) = "GM" THEN
		LET m_isMobile = TRUE
	END IF
	CALL logIt(SFMT( "Client: %1 isMobile: %2", l_cli, m_isMobile))
	CALL logIt(SFMT("FGLPROFILE: %1", fgl_getEnv("FGLPROFILE")))
	CALL getCFGPath()

	IF m_isMobile THEN
		CALL ui.Interface.frontCall("mobile", "connectivity", [], l_res)
		CALL logIt(SFMT( "connectivity res: %1", l_res))
		IF l_res = "NONE" THEN
			CALL fgldialog.fgl_winMessage("Error", "No network detected, check your wifi settings", "exclamation")
			CALL exitProgram(1)
		END IF
	END IF
	LET m_dbname = "d1234"
	LET m_ip = "test"
	LET m_url = SFMT("https://%1/%2/ua/r/%3", C_CFG_SERVER, C_CFG_GASALIAS, C_CFG_APP )

	IF m_url IS NULL OR m_url.getLength() < 2 THEN
		CALL fgldialog.fgl_winMessage("Error", SFMT("Invalid App URL: %1", m_url), "exclamation")
		CALL exitProgram(1)
	END IF
	LET m_url = m_url.append("?Arg=" || m_dbname || "&Arg=" || m_ip)
	TRY
		LET l_res = "failed"
		IF m_isMobile THEN
			CALL logIt( SFMT("runOnServer Url: %1", m_url ) )
			CALL ui.interface.frontcall("mobile", "runOnServer", [m_url], [l_res])
		ELSE
			CALL logIt( SFMT("launchUrl Url: %1", m_url ) )
			CALL ui.Interface.frontCAll("standard", "launchUrl", [m_url], [l_res])
		END IF
	CATCH
		CALL fgldialog.fgl_winMessage(
				"Error", SFMT("Run on Server failed:%1\n\nURL: %2\nRes: %3", err_get(STATUS), m_url, l_res),
				"exclamation")
		CALL logIt( SFMT("Failed, Result: %1", l_res ))
		CALL exitProgram(1)
		--CALL ui.Interface.frontCAll("standard", "launchUrl", [m_cfg.app_url], [l_res])
	END TRY
	CALL logIt( SFMT("Result: %1", l_res ))
	IF l_res != "ok" THEN
		CALL fgldialog.fgl_winMessage("Done", SFMT("Done\nURL: %1\nRes: %2", m_url, l_res), "exclamation")
	END IF
	CALL exitProgram(0)
END MAIN
--------------------------------------------------------------------------------------------------------------
FUNCTION getCFGPath() RETURNS()

-- Get Permission for reading/writing the config file.
	IF m_isMobile THEN
		CALL setPermission("READ_PRIVILEGED_PHONE_STATE")
		CALL setPermission("READ_EXTERNAL_STORAGE")
		CALL setPermission("WRITE_EXTERNAL_STORAGE")
		CALL setPermission("MANAGE_EXTERNAL_STORAGE")
		CALL setPermission("ACCESS_MEDIA_LOCATION")
		CALL setPermission("ACCESS_CAMERA")
	END IF

	CASE -- find the Downloads folder.
		WHEN os.path.exists("/storage/sdcard0/download")
			LET m_cfgPath = "/storage/sdcard0/download"
		WHEN os.path.exists("/sdcard/Download")
			LET m_cfgPath = "/sdcard/Download"
		WHEN os.path.exists("/storage/emulated/Download")
			LET m_cfgPath = "/storage/emulated/Download"
	END CASE
	IF m_cfgPath IS NULL THEN
		CALL fgldialog.fgl_winMessage("Error", "Can't find the Download folder", "exclamation")
		CALL exitProgram(1)
	END IF
	LET m_cfgPath = os.path.join(m_cfgPath, C_CFG_FILE)
END FUNCTION
--------------------------------------------------------------------------------------------------------------
FUNCTION setPermission(l_perm STRING) RETURNS ()
	DEFINE l_result STRING
	LET l_result = SFMT("android.permission.%1", l_perm)
	CALL logIt( SFMT("Ask for: %1", l_result ) )
	TRY
	CALL ui.Interface.frontCall("android", "askForPermission", [l_result], [l_result])
	CALL logIt( SFMT("Result of ask for %1: %2", l_perm, l_result ) )
	CATCH
		CALL logIt( SFMT("Failed %1: %2", STATUS, ERR_GET(STATUS) ) )
	END TRY
END FUNCTION
--------------------------------------------------------------------------------------------------------------
FUNCTION logIt( l_mess STRING ) RETURNS ()
	LET l_mess = CURRENT,":",l_mess
	DISPLAY l_mess
	LET m_log = m_log.append(l_mess||"\n")
END FUNCTION
--------------------------------------------------------------------------------------------------------------
FUNCTION exitProgram( l_stat SMALLINT ) RETURNS ()
	DEFINE c base.Channel
	IF m_logFile IS NOT NULL THEN
		LET c = base.Channel.create()
		TRY
			CALL c.openFile(m_logFile,"w+")
			CALL c.writeLine( m_log )
			CALL c.close()
			DISPLAY "Log written to: ",m_logFile
		CATCH
			CALL logIt(SFMT("Failed to write log '%1' %2:%3", m_logFile,STATUS, ERR_GET(STATUS)))
			CALL fgldialog.fgl_winMessage("Error",m_log,"exclamation")
		END TRY
	END IF
	EXIT PROGRAM l_stat
END FUNCTION