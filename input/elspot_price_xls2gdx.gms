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

*Definition
Set
  tsIso                "Date stamp in ISO8601 format"
  t                    "Model time steps" / t000000 * t100000 /
;
Parameters
 elspotIso(tsIso)      "Elspot Prices (EUR/MWh) with ISO date-stamp"
 elspotIsoBB(t,tsIso)  "Elspot Prices (EUR/MWh) with backbone timestep and ISO date"
 elspotBB(t)           "Elspot Prices (EUR/MWh) with backbone timestep"
;

*User Settings
$set outFileName elspot_prices_2015
$set readSheet elspot_day-ahead_prices

*Read from Excel
$onEcho > howToRead.txt
set=tsIso          rng=%readSheet%!K8771:K17530 rDim=1 values=noData
par=elspotIso      rng=%readSheet%!K8771:P17530 rDim=1
$offEcho
$call gdxxrw input\data\elspot-prices_hourly_eur.xlsx squeeze=n output=input\data\%outFileName%.gdx @howToRead.txt trace=3'
$gdxIn input\data\%outFileName%
$load tsIso elspotIso
$gdxIn

Loop((t,tsIso)$(ord(t)=ord(tsIso)),
elspotIsoBB(t,tsIso)=elspotIso(tsIso);
);
elspotBB(t)=sum(tsIso,elspotIsoBB(t,tsIso));

execute_unloaddi "input\data\%outFileName%.gdx" elspotIsoBB, elspotBB;





