# BerkeleyLibrary::Alma

A utility gem for working with Alma / Primo.

## `alma-mms-lookup`: Control field 001 record ID lookup

The `alma-mms-lookup` script takes one or more record IDs (either Millennium bib
numbers or Alma MMS IDs) and attempts to read the corresponding MARC records via
[SRU](https://developers.exlibrisgroup.com/alma/integrations/sru/) and extract
the canonical MMS ID for the record from the 001 control field.

### Local execution

If you clone this repository and run `bundle install` from the project root,
you can run the `bin/alma-mms-lookup` script directly. Note that this requires
Ruby 3.x to be installed. (Alternatively, you can use Docker; see below.)

To look up a single ID:

```sh
echo b11082434 | bin/alma-mms-lookup
```

To look up a list of IDs given in a file `record-ids.txt`:

```sh
bin/alma-mms-lookup < record-ids.txt
```

### Execution via Docker

To look up a single ID:

```sh
echo b11082434 | docker compose run gem bin/alma-mms-lookup 
```

To look up a list of IDs given in a file `record-ids.txt`:

```sh
docker compose run gem bin/alma-mms-lookup < record-ids.txt
```

### Output format

The output is tab-separated, in the form

```none
<original bib number>	<bib number with check digit>	<MMS ID from 001>
```

or

```none
<orignal MMS id>	<original MMS ID again>	<MMS ID from 001>
```

e.g.:

```none
b11082434	b110824349	991038544199706532
991038544199706532	991038544199706532	991038544199706532
```

Any IDs that cannot be retrieved or parsed are left blank:

```sh
echo 'b11082434
b1234
991038544199706532
9912348245906531
b110824349' | bin/alma-mms-lookup
```

produces:

```none
b11082434	b110824349	991038544199706532
b1234		
991038544199706532	991038544199706532	991038544199706532
[2022-01-03T14:17:09.060-08:00] WARN: GET https://berkeley.alma.exlibrisgroup.com/view/sru/01UCS_BER?version=1.2&operation=searchRetrieve&query=alma.mms_id%3D9912348245906531 did not return a MARC record
9912348245906531	9912348245906531
b110824349	b110824349	991038544199706532
```

Note that warning messages are written to STDOUT, so you may need to filter them
with `grep`:

```sh
echo 'b11082434
b1234
991038544199706532
9912348245906531
b110824349' | bin/alma-mms-lookup | grep -v WARN
```

produces:

```none
b11082434	b110824349	991038544199706532
b1234		
991038544199706532	991038544199706532	991038544199706532
9912348245906531	9912348245906531	
b110824349	b110824349	991038544199706532
```