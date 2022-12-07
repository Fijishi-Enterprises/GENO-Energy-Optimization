* Add sets and parameters from inFile2.gdx to inFile1.gdx and create indata_merged
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
    else:  # add sets and parameters that exist only in inFile2.gdx
        dom_names = [s if isinstance(s, str) else s.name for s in m2[s].domain]
        if isinstance(m2[s], gt.Set):
            m1.addSet(s, dom_names, records=m2[s].records, description=m2[s].description)
        elif isinstance(m2[s], gt.Parameter):
            m1.addParameter(s, dom_names, records=m2[s].records, description=m2[s].description)
m1.write(r"%outFile1%")
$offEmbeddedCode
$log Output file: %outFile1%

