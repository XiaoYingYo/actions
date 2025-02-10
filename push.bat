title push
set batPath=%~dp0
set currentDirectory=%batPath:~0,-1%
set driveLetter=%currentDirectory:~0,1%
cd %driveLetter%:
cd "%currentDirectory%"
chcp 65001

git status && git add . && git commit --allow-empty-message -m "" && git -c diff.mnemonicprefix=false -c core.quotepath=false --no-optional-locks push -v --set-upstream origin main:main