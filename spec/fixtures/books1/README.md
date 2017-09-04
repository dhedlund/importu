Contains three records that are compatible with the `BookImporter`. They
should all be created successfully on import.

The following anomalies exist in the data:

| Record | Field         | Formats  | Value           | Description |
| 1      | release\_date | _all_    | "Feb 1, 2008"   | should detect date format |
| 1      | pages         | _all_    | "0448"          | leading 0 should parse as decimal not octal |
| 2      | release\_date | _all_    | "1 May, 2013"   | should detect date format |
| 2      | pages         | json     | 188             | should handle value already being an integer |
| 3      | _all_         | _all_    | "  value  "     | should trim surrounding whitespace |
| 3      | release\_date | _all_    | "  2006-7-26  " | should handle missing leading '0' in date |
