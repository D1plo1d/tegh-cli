; -- Example1.iss --
; Demonstrates copying 3 files and creating an icon.

; SEE THE DOCUMENTATION FOR DETAILS ON CREATING .ISS SCRIPT FILES!

[Setup]
AppName=Tegh     
LicenseFile="..\LICENSE"              
AppVersion=0.3.0
DefaultDirName={pf}\Tegh
DefaultGroupName=Tegh
Compression=lzma2
SolidCompression=yes
OutputDir= ./

[Files]
Source: ..\*; DestDir: {app}; Flags: recursesubdirs 

[Icons]
Name: "{group}\Tegh"; Filename: "{app}\bin\tegh.bat"; WorkingDir: "{app}"
