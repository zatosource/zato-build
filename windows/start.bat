@ECHO OFF

CD C:\PROGRA~1\BOOT2D~1\

ECHO 'initializing...'
boot2docker.exe init

ECHO 'starting...'
CMD /K boot2docker.exe start

ECHO 'IP address of docker VM:'
CMD /K boot2docker.exe ip

ECHO 'setting environment variables ...'
CMD /K boot2docker.exe shellinit

ECHO 'You can now use `docker` directly, or `boot2docker ssh` to log into the VM.'

CD
CMD /K C:\PROGRA~2\Git\bin\bash.exe --login -i