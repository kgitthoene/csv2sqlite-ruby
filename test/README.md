# Sample data conversion

Two files from this source were used as test data: [GitHub datablist/sample-csv-files](https://github.com/datablist/sample-csv-files).

Create a [SQLite database](https://www.sqlite.org/) with this command:

```
ruby ../csv2sqlite.rb -o 10000.sqlite T:Customers customers-10000.csv T:People people-10000.csv -H
```
