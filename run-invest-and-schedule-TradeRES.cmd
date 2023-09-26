Title Running scenario: "backbone TradeRES model - invest and schedule"

:: investment run
:: convert input excel to input gdx
::C:\GAMS\win64\24.1\gdxxrw Input="./input/TradeRES/InputData_traderes_run3.xlsx" Output="./input/TradeRES/inputData.gdx" CheckDate Index=INDEX!

:: preparing additional input data files
copy .\input\TradeRES\4d_postProcess_invest.gms .\input\TradeRES\4d_postProcess.gms
del .\input\TradeRES\invest_results.inc
copy .\input\TradeRES\changes-invest.inc .\input\TradeRES\changes.inc
copy .\input\TradeRES\cplex_invest.opt .\cplex.opt

:: running backbone in invest mode
for /F "tokens=3" %%A in ('reg query "HKEY_CURRENT_USER\gams.location"') DO (%%A\gams.exe Backbone.gms --input_dir=./input/TradeRES --init_file=investInit.gms --debug=1 -lo=2 --penalty=4000)


:: copying summary of invest results to TradeRES folder
copy .\output\invest_results.inc .\input\TradeRES\invest_results.inc
copy .\output\debug.gdx .\output\debug-invest.gdx
copy .\output\result.gdx .\output\result-invest.gdx
copy .\Backbone.log .\output\log-invest.log
copy .\Backbone.lst .\output\lst-invest.lst


:: schedule run
:: using the same input gdx, no need to convert it again
:: preparing additional input data files
del .\input\TradeRES\4d_postProcess.gms
del .\input\TradeRES\changes.inc
copy .\input\TradeRES\changes-schedule.inc .\input\TradeRES\changes.inc
copy .\input\TradeRES\cplex_schedule.opt .\cplex.opt


:: running backbone in schedule mode
for /F "tokens=3" %%A in ('reg query "HKEY_CURRENT_USER\gams.location"') DO (%%A\gams.exe Backbone.gms --input_dir=./input/TradeRES --init_file=scheduleInit.gms --debug=1 -lo=2 --penalty=4000)

:: copying result files to demo1 folder
::copy .\output\results.gdx .\output\results-investAndSchedule.gdx
::copy .\output\debug.gdx .\output\debug-investAndSchedule.gdx


:: removing additional input data 
del .\input\TradeRES\changes.inc

::cmd