# BerkeleyLibrary::Alma

[![Build Status](https://github.com/BerkeleyLibrary/alma/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/BerkeleyLibrary/alma/actions/workflows/build.yml)
[![Gem Version](https://img.shields.io/gem/v/berkeley_library-alma.svg)](https://rubygems.org/gems/berkeley_library-alma)

A utility gem for working with Alma / Primo.

## Configuration

The `BerkeleyLibrary::Alma::Config` class includes the options below. These
can be read automatically from a Rails configuration
(`Rails.application.config.alma_sru_host = "..."`, etc.) or set directly
(`BerkeleyLibrary::Alma::Config.alma_sru_host = "..."`).

Alternatively, `BerkeleyLibrary::Alma::Config.default!` will set the
options to either:

1. the value of the corresponding environment variable, if set, or
2. the default value for the UC Berkeley Library.

| Option                  | Environment variable        | Purpose                                                                                                                       | Berkeley default                  |
| ---                     | ---                         | ---                                                                                                                           | ---                               |
| `alma_sru_host`         | `LIT_ALMA_SRU_HOST`         | the Alma SRU hostname                                                                                                         | `berkeley.alma.exlibrisgroup.com` |
| `alma_institution_code` | `LIT_ALMA_INSTITUTION_CODE` | the Alma institution code                                                                                                     | `search.library.berkeley.edu`     |
| `alma_primo_host`       | `LIT_ALMA_PRIMO_HOST`       | the Alma Primo host                                                                                                           | `01UCS_BER`                       |
| `alma_permalink_key`    | `LIT_ALMA_PERMALINK_KEY`    | the Alma [permalink key](https://knowledge.exlibrisgroup.com/Primo/Knowledge_Articles/What_is_the_key_in_short_permalinks%3F) | `iqob43`                          |

## Retrieving Alma records

The [`RecordId`](lib/berkeley_library/alma/record_id.rb) class encapsulates 
an ID that can be used to look up records in Alma via 
[SRU](https://developers.exlibrisgroup.com/alma/integrations/sru/).
This can be either an Alma MMS ID:

```ruby
mms_id_str = '991054360089706532'
record_id = BerkeleyLibrary::Alma::RecordId.parse(mms_id_str)
# => #<BerkeleyLibrary::Alma::MMSID:0x0000000138949830 @institution="6532", @mms_id="991054360089706532", @type_prefix="99", @unique_part="105436008970">
```

Or a Millennium bib number:

```ruby
bib_number_str = 'b11082434'
record_id = BerkeleyLibrary::Alma::RecordId.parse(bib_number_str)
# => #<BerkeleyLibrary::Alma::BibNumber:0x0000000118815038 @check_str="9", @digit_str="11082434">
```

Given a `RecordId` object, you can get the SRU query URI for the corresponding MARC record:

```ruby
record_id.marc_uri
# => #<URI::HTTPS https://berkeley.alma.exlibrisgroup.com/view/sru/01UCS_BER?version=1.2&operation=searchRetrieve&query=alma.mms_id%3D991054360089706532> 
```

Or the MARC XML as a string:

```ruby
marc_xml_str = record_id.get_marc_xml 
# => "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><searchRetrieveResponse>...</searchRetrieveResponse>"
```

Or just a [ruby-marc](https://github.com/ruby-marc/ruby-marc) `MARC::Record` object:

```ruby
marc_record = record_id.get_marc_record
# => #<MARC::Record:0x0000000138b45490
```

#### Calculating the check digit for a Millennium bib

You can also use `RecordId` to verify or calculate the check digit for a Millennium bib.

(Check digit calculation is based on the algorithm described in 
"[Recipe: Computing the Millennium checkdigit](http://liwong.blogspot.com/2018/04/recipe-computing-millennium-checkdigit.html)"
by Lisa Wong of the McHenry Library, UC Santa Cruz.

##### Calculating the check digit

The check digit will be appended to bib numbers without one,
or with the wildcard check digit `a`.

```ruby
bib_number_str = 'b11082434'
record_id = BerkeleyLibrary::Alma::RecordId.parse(bib_number_str)
# => #<BerkeleyLibrary::Alma::BibNumber:0x0000000118815038 @check_str="9", @digit_str="11082434">
record_id.check_str
# => "9"
record_id.full_bib
# => "b110824349" 

bib_number_str = 'b11082434a'
record_id = BerkeleyLibrary::Alma::RecordId.parse(bib_number_str)
# => #<BerkeleyLibrary::Alma::BibNumber:0x0000000118815038 @check_str="9", @digit_str="11082434">
```

##### Verifying the check digit

The `RecordId#parse` method will raise an error if passed a bib with a bad
check digit.

```ruby
bib_number_str = 'b110824341' # wrong check digit; should be 9, not 2
# bib_number.rb:78:in `ensure_check_digit': 110824341 check digit invalid: expected 9, got 1 (ArgumentError)
# 	from /Users/david/Work/BerkeleyLibrary/alma/lib/berkeley_library/alma/bib_number.rb:68:in `split_bib'
# 	from /Users/david/Work/BerkeleyLibrary/alma/lib/berkeley_library/alma/bib_number.rb:27:in `initialize'
# 	from /Users/david/Work/BerkeleyLibrary/alma/lib/berkeley_library/alma/record_id.rb:35:in `new'
# 	from /Users/david/Work/BerkeleyLibrary/alma/lib/berkeley_library/alma/record_id.rb:35:in `parse'
```

## Scripts

### `alma-mms-lookup`: Control field 001 record ID lookup

The `alma-mms-lookup` script takes one or more record IDs (either Millennium bib
numbers or Alma MMS IDs) and attempts to read the corresponding MARC records via
[SRU](https://developers.exlibrisgroup.com/alma/integrations/sru/) and extract
the canonical MMS ID for the record from the 001 control field.

#### Local execution

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

#### Execution via Docker

To look up a single ID:

```sh
echo b11082434 | docker compose run gem bin/alma-mms-lookup 
```

To look up a list of IDs given in a file `record-ids.txt`:

```sh
docker compose run gem bin/alma-mms-lookup < record-ids.txt
```

#### Output format

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
