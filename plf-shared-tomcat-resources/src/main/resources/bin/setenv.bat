@REM
@REM Copyright (C) 2003-2013 eXo Platform SAS.
@REM
@REM This is free software; you can redistribute it and/or modify it
@REM under the terms of the GNU Lesser General Public License as
@REM published by the Free Software Foundation; either version 3 of
@REM the License, or (at your option) any later version.
@REM
@REM This software is distributed in the hope that it will be useful,
@REM but WITHOUT ANY WARRANTY; without even the implied warranty of
@REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
@REM Lesser General Public License for more details.
@REM
@REM You should have received a copy of the GNU Lesser General Public
@REM License along with this software; if not, write to the Free
@REM Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
@REM 02110-1301 USA, or see the FSF site: http://www.fsf.org.
@REM

@echo off

REM ---------------------------------------------------------------------------
REM            /!\     DON'T MODIFY THIS FILE      /!\
REM ---------------------------------------------------------------------------

REM ---------------------------------------------------------------------------
REM Settings customisation
REM ---------------------------------------------------------------------------
REM You have 2 ways to customize your installation settings :
REM 1- Rename the file setenv-customize.sample.bat to setenv-customize.bat and uncomment/change values
REM 2- Use system environment variables of your system or local shell (Get the list in setenv-customize.sample.bat)
REM ---------------------------------------------------------------------------

rem Get standard Java environment variables
if exist "%CATALINA_HOME%\bin\setclasspath.bat" goto okSetclasspath
echo Cannot find "%CATALINA_HOME%\bin\setclasspath.bat"
echo This file is needed to run this program
goto end
:okSetclasspath
call "%CATALINA_HOME%\bin\setclasspath.bat" %1
if errorlevel 1 goto end

rem Get standard environment variables
if not exist "%CATALINA_BASE%\bin\setenv-customize.bat" goto setEnvCustomize
call "%CATALINA_BASE%\bin\setenv-customize.bat"

:setEnvCustomize
REM We validate that Command extensions are available
VERIFY other 2>nul
SETLOCAL enableextensions
IF ERRORLEVEL 1 (
  ECHO Unable to enable extensions
  exit 1
)
ENDLOCAL

REM ---------------------------------------------------------------------------
REM Default EXO PLATFORM configuration
REM ---------------------------------------------------------------------------
IF NOT DEFINED EXO_PROFILES SET EXO_PROFILES=default
IF NOT DEFINED EXO_DEBUG SET EXO_DEBUG=false
IF NOT DEFINED EXO_DEBUG_PORT SET EXO_DEBUG_PORT=8000
IF NOT DEFINED EXO_DEV SET EXO_DEV=false
IF NOT DEFINED EXO_ASSETS_VERSION SET EXO_ASSETS_VERSION=${project.version}
IF NOT DEFINED EXO_JCR_SESSION_TRACKING SET EXO_JCR_SESSION_TRACKING=false
IF NOT DEFINED EXO_DATA_DIR SET EXO_DATA_DIR=%CATALINA_BASE%\gatein\data

REM ---------------------------------------------------------------------------
REM Default Logs configuration
REM ---------------------------------------------------------------------------
REM Default configuration for logs (using logback framework - http://logback.qos.ch/manual/configuration.html )
IF NOT DEFINED EXO_LOGS_LOGBACK_CONFIG_FILE SET EXO_LOGS_LOGBACK_CONFIG_FILE=%CATALINA_BASE%\conf\logback.xml
IF NOT DEFINED EXO_LOGS_DISPLAY_CONSOLE SET EXO_LOGS_DISPLAY_CONSOLE=false
IF NOT DEFINED EXO_LOGS_COLORIZED_CONSOLE SET EXO_LOGS_COLORIZED_CONSOLE=

REM ---------------------------------------------------------------------------
REM Default JVM configuration
REM ---------------------------------------------------------------------------
IF NOT DEFINED EXO_JVM_USER_LANGUAGE SET EXO_JVM_USER_LANGUAGE=en
IF NOT DEFINED EXO_JVM_USER_REGION SET EXO_JVM_USER_REGION=US
IF NOT DEFINED EXO_JVM_SIZE_MAX SET EXO_JVM_SIZE_MAX=2g
IF NOT DEFINED EXO_JVM_SIZE_MIN SET EXO_JVM_SIZE_MIN=512m
IF NOT DEFINED EXO_JVM_PERMSIZE_MAX SET EXO_JVM_PERMSIZE_MAX=256m
IF NOT DEFINED EXO_JVM_PERMSIZE_MIN SET EXO_JVM_PERMSIZE_MIN=128m

REM ---------------------------------------------------------------------------
REM Default Tomcat configuration
REM ---------------------------------------------------------------------------
REM Global Tomcat settings
IF NOT DEFINED EXO_TOMCAT_UNPACK_WARS SET EXO_TOMCAT_UNPACK_WARS=%EXO_DEV%

REM ---------------------------------------------------------------------------
REM Export the needed system properties for server.xml
REM ---------------------------------------------------------------------------
SET JAVA_OPTS=%JAVA_OPTS% -DEXO_TOMCAT_UNPACK_WARS=%EXO_TOMCAT_UNPACK_WARS% -DEXO_DEV=%EXO_DEV%

REM ---------------------------------------------------------------------------
REM Logs customization (Managed by slf4J\logback instead of tomcat-juli & co)
REM ---------------------------------------------------------------------------
REM Deactivate j.u.l
SET LOGGING_MANAGER=-Dnop
REM Add additional bootstrap entries for logging purpose using SLF4J+Logback
REM SLF4J deps
SET CLASSPATH=%CLASSPATH%;%CATALINA_HOME%\lib\slf4j-api-${org.slf4j.version}.jar
SET CLASSPATH=%CLASSPATH%;%CATALINA_HOME%\lib\jul-to-slf4j-${org.slf4j.version}.jar
REM LogBack deps
SET CLASSPATH=%CLASSPATH%;%CATALINA_HOME%\lib\logback-core-${ch.qas.logback.version}.jar
SET CLASSPATH=%CLASSPATH%;%CATALINA_HOME%\lib\logback-classic-${ch.qas.logback.version}.jar
REM Janino deps (used by logback for conditional processing in the config file)
SET CLASSPATH=%CLASSPATH%;%CATALINA_HOME%\lib\janino-${org.codehaus.janino.version}.jar
SET CLASSPATH=%CLASSPATH%;%CATALINA_HOME%\lib\commons-compiler-${org.codehaus.janino.version}.jar
REM Jansi deps for colorized output on windows
SET CLASSPATH=%CLASSPATH%;%CATALINA_HOME%\lib\jansi-${org.fusesource.jansi.version}.jar

REM ---------------------------------------------------------------------------
REM Compute the CATALINA_OPTS
REM ---------------------------------------------------------------------------
IF /I %EXO_DEBUG% EQU true (
  SET CATALINA_OPTS=%CATALINA_OPTS% -agentlib:jdwp=transport=dt_socket,address=%EXO_DEBUG_PORT%,server=y,suspend=n
)
IF /I %EXO_DEV% EQU true (
  SET CATALINA_OPTS=%CATALINA_OPTS% -Dorg.exoplatform.container.configuration.debug
  SET CATALINA_OPTS=%CATALINA_OPTS% -Dexo.product.developing=true
  SET EXO_JCR_SESSION_TRACKING=true
)
REM JCR session leak detector
SET CATALINA_OPTS=%CATALINA_OPTS% -Dexo.jcr.session.tracking.active=%EXO_JCR_SESSION_TRACKING%
REM JVM Memory settings
SET CATALINA_OPTS=%CATALINA_OPTS% -Xms%EXO_JVM_SIZE_MIN% -Xmx%EXO_JVM_SIZE_MAX% -XX:MaxPermSize=%EXO_JVM_PERMSIZE_MAX%
REM Default user locale defined at JVM level
SET CATALINA_OPTS=%CATALINA_OPTS% -Duser.language=%EXO_JVM_USER_LANGUAGE% -Duser.region=%EXO_JVM_USER_REGION%
REM Network settings
SET CATALINA_OPTS=%CATALINA_OPTS% -Djava.net.preferIPv4Stack=true
REM Platform profiles
SET CATALINA_OPTS=%CATALINA_OPTS% -Dexo.profiles=%EXO_PROFILES%
REM Platform paths
SET CATALINA_OPTS=%CATALINA_OPTS% -Dexo.conf.dir.name="gatein\conf"
SET CATALINA_OPTS=%CATALINA_OPTS% -Dexo.conf.dir="%CATALINA_BASE%\gatein\conf"
SET CATALINA_OPTS=%CATALINA_OPTS% -Dgatein.conf.dir="%CATALINA_BASE%\gatein\conf"
SET CATALINA_OPTS=%CATALINA_OPTS% -Dgatein.data.dir="%EXO_DATA_DIR%"
SET CATALINA_OPTS=%CATALINA_OPTS% -Djava.security.auth.login.config="%CATALINA_BASE%\conf\jaas.conf"
REM JAVA_HOME is computed by setclasspath.bat if required
if not exist "%JAVA_HOME%\bin\javac.exe" goto noJavac
REM We have a JDK
SET CATALINA_OPTS=%CATALINA_OPTS% -Djre.lib="%JAVA_HOME%\jre\lib"
SET CATALINA_OPTS=%CATALINA_OPTS% -Djavasrc="%JAVA_HOME%\src.zip"
goto okJavac
:noJavac
REM We have a JRE
SET CATALINA_OPTS=%CATALINA_OPTS% -Djre.lib="%JAVA_HOME%\lib"
:okJavac
REM Assets version
SET CATALINA_OPTS=%CATALINA_OPTS% -Dgatein.assets.version=%EXO_ASSETS_VERSION%
REM Logback configuration file
SET CATALINA_OPTS=%CATALINA_OPTS% -Dlogback.configurationFile="%EXO_LOGS_LOGBACK_CONFIG_FILE%"
REM Define the XML Parser
SET CATALINA_OPTS=%CATALINA_OPTS% -Djavax.xml.stream.XMLOutputFactory=com.sun.xml.internal.stream.XMLOutputFactoryImpl -Djavax.xml.stream.XMLInputFactory=com.sun.xml.internal.stream.XMLInputFactoryImpl -Djavax.xml.stream.XMLEventFactory=com.sun.xml.internal.stream.events.XMLEventsFactoryImpl

REM Set the window name
SET TITLE=eXo Platform ${project.version}

:end