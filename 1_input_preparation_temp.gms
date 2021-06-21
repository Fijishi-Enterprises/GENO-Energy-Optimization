* Convert Excel input
$if set input_file_excel $call 'gdxxrw Input="%input_file_excel%" Output="%input_dir%/inputData.gdx" Index=INDEX!'
$ife %system.errorlevel%>0 $abort gdxxrw failed!
