$ontext
Convert electricty prices from Excel to GDX

Usage:
1. Select excel range to read: see Excel and take for example a full year
2. Choose outFileName
3. Execute to create GDX

Source:
https://transparency.entsoe.eu/transmission-domain/r2/dayAheadPrices/show?name=&defaultValue=false&viewType=TABLE&areaType=BZN&atch=false&dateTime.dateTime=01.01.2022+00:00|UTC|DAY&biddingZone.values=CTY|10YFI-1--------U!BZN|10YFI-1--------U&resolution.values=PT60M&dateTime.timezone=UTC&dateTime.timezone_input=UTC#
Previous source: https://www.nordpoolgroup.com/historical-market-data/

2022-11-23 Toni Lastusilta (VTT)
$offtext

$if not exist %GAMS.curDir%Backbone.gms $abort GAMS Project or curDir command line parameter must point to Backbone.gms location
* e.g. in GAMS STUDIO use command line parameter curDir=<C:\...\Backbone.gms> without the file reference Backbone.gms
$if not set input_dir $setglobal input_dir 'input'


*Definition
Set
  tsIso                "Date stamp in ISO8601 format"
  t                    "Model time steps" / t000001 * t100000 /
;
Parameters
 elspotIso(tsIso)      "Elspot Prices (EUR/MWh) with ISO date-stamp"
 elspotIsoBB(t,tsIso)  "Elspot Prices (EUR/MWh) with backbone timestep and ISO date"
 elspotBB(t)           "Elspot Prices (EUR/MWh) with backbone timestep"
;

*User Settings
$if not set year $set year 2021
*Settings
$set outFileName elspot_prices_%year%
$set readSheet elspot_day-ahead_prices

*Read from Excel
$onEcho > howToRead2015.txt
set=tsIso          rng=%readSheet%!K8771:K17530 rDim=1 values=noData
par=elspotIso      rng=%readSheet%!K8771:P17530 rDim=1
$offEcho
$onEcho > howToRead2016.txt
set=tsIso          rng=%readSheet%!K17531:K26314 rDim=1 values=noData
par=elspotIso      rng=%readSheet%!K17531:P26314 rDim=1
$offEcho
$onEcho > howToRead2017.txt
set=tsIso          rng=%readSheet%!K26315:K35074 rDim=1 values=noData
par=elspotIso      rng=%readSheet%!K26315:P35074 rDim=1
$offEcho
$onEcho > howToRead2018.txt
set=tsIso          rng=%readSheet%!K35075:K43834 rDim=1 values=noData
par=elspotIso      rng=%readSheet%!K35075:P43834 rDim=1
$offEcho
$onEcho > howToRead2019.txt
set=tsIso          rng=%readSheet%!K43835:K52594 rDim=1 values=noData
par=elspotIso      rng=%readSheet%!K43835:P52594 rDim=1
$offEcho
$onEcho > howToRead2020.txt
set=tsIso          rng=%readSheet%!K52595:K61378 rDim=1 values=noData
par=elspotIso      rng=%readSheet%!K52595:P61378 rDim=1
$offEcho
$onEcho > howToRead2021.txt
set=tsIso          rng=%readSheet%!K61379:K70138 rDim=1 values=noData
par=elspotIso      rng=%readSheet%!K61379:P70138 rDim=1
$offEcho

$call gdxxrw %input_dir%\data\elspot-prices_hourly_eur.xlsx squeeze=n output=%input_dir%\data\%outFileName%.gdx @howToRead%year%.txt trace=3'
$gdxIn %input_dir%\data\%outFileName%
$load tsIso elspotIso
$gdxIn

Loop((t,tsIso)$(ord(t)=ord(tsIso)),
elspotIsoBB(t,tsIso)=elspotIso(tsIso);
);
elspotBB(t)=sum(tsIso,elspotIsoBB(t,tsIso));

execute_unloaddi "%input_dir%\data\%outFileName%.gdx" elspotIsoBB, elspotBB;
execute 'cp "%input_dir%\data\%outFileName%.gdx" "%input_dir%\%year%\%outFileName%.gdx"'





