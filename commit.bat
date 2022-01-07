@ECHO OFF 
ECHO Subiendo a GitHub
call git add .
call git commit -m "batch: Actualizar documentos"
call git push origin master
pause
