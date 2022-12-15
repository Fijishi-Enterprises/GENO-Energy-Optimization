* Add sets and parameters from inFile2.gdx to inFile1.gdx and create indata_merged
* Not currently working the add_to_gdx.gms can not handle variables correctly, nor can it handle set increments.

$onecho > prog1.gms
Set i /i1*i3/;
Parameter pi(i) /#i 2/;
Variables v1(i) /#i.l 2, #i.lo 1, #i.up 7/;
$offecho
$call gams prog1.gms gdx=indata1.gdx
$onecho > prog2.gms
Set j /j1*j3/;
Parameter pj(j) /#j 3/;
Set i /i2*i4/;
Parameter pi(i) /#i 3/;
Variables v1(i) /#i.l 3, #i.lo 2, #i.up 8/;
Variables v2(i) /#i.l 3, #i.lo 2, #i.up 8/;
$offecho
$call gams prog2.gms gdx=indata2.gdx

$if not set inFile1  $set inFile1  indata1.gdx
$if not set inFile2  $set inFile2  indata2.gdx
$if not set outFile1 $set outFile1 input_merged.gdx
$log Input files: %inFile1% , %inFile2%

$onEmbeddedCode Python:
import gamstransfer as gt
import pandas as pd
m1 = gt.Container(r"%inFile1%")
m2 = gt.Container(r"%inFile2%")

for s in m2.data:
    if s in m1:  # merge parameters that exist in both inFile1.gdx and inFile2.gdx
        if type(m2[s]) == gt.Parameter:
            df = pd.concat([m1[s].records, m2[s].records]).drop_duplicates(list(m1[s].records.columns[:-1]), keep='last')
            m1[s].setRecords(df)
        if type(m2[s]) == gt.Variable:
            df = pd.concat([m1[s].records, m2[s].records]).drop_duplicates(list(m1[s].records.columns[:-1]), keep='last')
            m1[s].setRecords(df)
    else:  # add sets and parameters that exist only in inFile2.gdx
        dom_names = [s if isinstance(s, str) else s.name for s in m2[s].domain]
        if isinstance(m2[s], gt.Set):
            m1.addSet(s, dom_names, records=m2[s].records, description=m2[s].description)
        elif isinstance(m2[s], gt.Parameter):
            m1.addParameter(s, dom_names, records=m2[s].records, description=m2[s].description)
        elif isinstance(m2[s], gt.Variable):
            m1.addVariable(s, dom_names, records=m2[s].records, description=m2[s].description)
m1.write(r"%outFile1%")
$offEmbeddedCode
$log Output file: %outFile1%

