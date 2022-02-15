# 0.0.4 (15 February 2022)

- adds `BarCode` subclass of `RecordId`, to look up bibliographic records by
  item barcode. Note that since barcodes have no consistent format, `BarCode`
  objects need to be constructed deliberately with `BarCode#new`, not with
  `RecordId#parse`.

# 0.0.3 (3 February 2022)

- use `local_field_996` instead of `other_system_number` when making SRU queries
  for Millennium records
- accept leading upper-case B in bib numbers 

# 0.0.2 (26 January 2022)

- update to [berkeley_library-marc](https://github.com/BerkeleyLibrary/marc) 0.3.1

# 0.0.1 (25 January 2022)

- initial public release
