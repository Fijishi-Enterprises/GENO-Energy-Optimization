Title Running scenario: "backbone TradeRES model - invest and schedule"

:: investment run

:: preparing additional input data files
copy .\input\TradeRES\4d_postProcess_invest.gms .\input\TradeRES\4d_postProcess.gms
del .\input\TradeRES\invest_results.inc
copy .\input\TradeRES\changes-invest.inc .\input\TradeRES\changes.inc
copy .\input\TradeRES\cplex_invest.opt .\cplex.opt

:: running backbone in invest mode
for /F "tokens=3" %%A in ('reg query "HKEY_CURRENT_USER\gams.location"') DO (%%A\gams.exe Backbone.gms --input_dir=./input/TradeRES --init_file=investInit.gms --debug=1 -lo=2 --penalty=4000 --resultsVer2x=True)
::C:\GAMS\win64\24.1\gams.exe Backbone.gms --input_dir=./input/TradeRES --init_file=investInit.gms --debug=1 -lo=2 --penalty=4000 --resultsVer2x=True
::<insert your GAMS call here> Backbone.gms --input_dir=./input/TradeRES --init_file=investInit.gms --debug=1 -lo=2 --penalty=4000 --resultsVer2x=True
:: For VTT users: alternative way to call Backbone when using Hassle (please set your GAMS version in the path below)
::CALL "C:\Program Files\VTT\HASSLE\hassle.exe" C:\GAMS\44\gams.exe %~dp0Backbone.gms --input_dir=./input/TradeRES --init_file=investInit.gms --debug=1 -lo=2 --penalty=4000 --resultsVer2x=True

:: copying summary of invest results to TradeRES folder
copy .\output\invest_results.inc .\input\TradeRES\invest_results.inc
copy .\output\debug.gdx .\output\debug-invest.gdx
copy .\output\results.gdx .\output\results-invest.gdx
copy .\Backbone.log .\output\log-invest.log
copy .\Backbone.lst .\output\lst-invest.lst


:: schedule run

: preparing additional input data files
del .\input\TradeRES\4d_postProcess.gms
del .\input\TradeRES\changes.inc
copy .\input\TradeRES\changes-schedule.inc .\input\TradeRES\changes.inc
copy .\input\TradeRES\cplex_schedule.opt .\cplex.opt

:: running backbone in schedule mode
for /F "tokens=3" %%A in ('reg query "HKEY_CURRENT_USER\gams.location"') DO (%%A\gams.exe Backbone.gms --input_dir=./input/TradeRES --init_file=scheduleInit.gms --debug=1 -lo=2 --penalty=4000 --resultsVer2x=True)
::C:\GAMS\win64\24.1\gams.exe Backbone.gms --input_dir=./input/TradeRES --init_file=scheduleInit.gms --debug=1 -lo=2 --penalty=4000 --resultsVer2x=True
::<insert your GAMS call here> Backbone.gms --input_dir=./input/TradeRES --init_file=scheduleInit.gms --debug=1 -lo=2 --penalty=4000 --resultsVer2x=True
:: For VTT users: alternative way to call Backbone when using Hassle (please set your GAMS version in the path below)
::CALL "C:\Program Files\VTT\HASSLE\hassle.exe" C:\GAMS\44\gams.exe %~dp0Backbone.gms --input_dir=./input/TradeRES --init_file=scheduleInit.gms --debug=1 -lo=2 --penalty=4000 --resultsVer2x=True

:: removing additional input data 
del .\input\TradeRES\changes.inc

::cmd
