@echo off
haxe compile.hxml
cd bin
neko HaxeContracts.n
pause
