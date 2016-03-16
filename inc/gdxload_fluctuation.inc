* Argument tells variableGen generator type
$setargs type

$ifthen exist 'input/scenarios_%type%.gdx'
    $$gdxin 'input/scenarios_%type%.gdx'
$endif
