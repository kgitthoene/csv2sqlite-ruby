# csv2sqlite-ruby

Convert [CSV files](https://en.wikipedia.org/wiki/Comma-separated_values) to a [SQLite database](https://www.sqlite.org/) using a [Ruby](https://www.ruby-lang.org/) command line program.

```
Usage: csv2sqlite.rb [-dvqyCH] [-c CONFIG] [--pidfile PIDFILE] [-s SEPARATOR] -o OUTPUT [T:TABLENAME] CSV-FILE [[T:TABLENAME] CSV-FILE ...]
    -d, --debug                      Enable debugging.
    -v, --verbose                    Talk more.
    -q, --quiet                      Talk nothing.
    -y, --overwrite                  Overwrite output files.
    -C, --write-sample-config-file   Writes a sample config file.
    -H, --header                     First line of csv contains header. (Default: true)
    -c, --config CONFIG              Config file. (Default: 'config.yaml')
        --pidfile PIDFILE            File for process-id. (Default: Not set. Not written.)
    -s, --column-separator SEPARATOR CSV separator for columns. (Default: ',')
    -o, --output OUTPUT              Write to this database.
    -h, -?, --help                   Display this screen.

CSV files and table names:
  Ahead each CSV file you may define the table name for the csv data.
    T:TABLENAME defines the name of a table, without the leading 'T:'.
  Without table names the cleaned name of the CSV file is taken.
```

## Installation

Clone this repository:

```
$ git clone https://github.com/kgitthoene/csv2sqlite-ruby.git
```

Check if you have to install required Ruby Gems:

```
$ cd csv2sqlite-ruby
$ bundler install
```

If you copy or move the script to another location, don't forget to copy or move the `lib` subdirectory into the same target directory.

### Installation Requirements

Yes, of course, Ruby must be installed.
See: [Ruby Installation](https://www.ruby-lang.org/en/documentation/installation/).

I suggest to use **rbenv**: [https://www.ruby-lang.org/en/documentation/installation/#rbenv](https://www.ruby-lang.org/en/documentation/installation/#rbenv)

Rbenv Website: [https://github.com/rbenv/rbenv](https://github.com/rbenv/rbenv#readme).

## CSV Column Separator

The default value for a CSV file is the comma (`,`).
The program can't guess a separator.
If it is a character other than the comma, then specify it with the `-s` / `--column-separator` option.

Example: `ruby csv2sqlite.rb -s ";"` ...

## Table Names

Table names are taken by default from the name of the CSV file, extension removed and converted to an acceptable SQLite table name.

Example: The file name `customers-10000.csv` becomes the table name `customers-10000`.

To determine the table name yourself, write it before the CSV file name, starting with a `T:`.
The `T:` is NOT part of the resulting table name.
Therefore, CSV files starting with `T:` cannot be imported.

Example: `ruby csv2sqlite.rb T:Customer customers-10000.csv` ...

## Resulting Database

The SQLite database file that will be created must be specified using the `-o` / `--output` parameter.

Example: `ruby csv2sqlite.rb -o 10000.sqlite` ...

An existing database file will not be overwritten until you set the overwrite option: `-y` / `--overwrite`.

Example: `ruby csv2sqlite.rb -o 10000.sqlite -y` ...

## CSV Data with Header

If the CSV data contains the names of the columns in the first row, these can become the column names of the resulting table in the database.

This can be enabled with the `-H` / `--header` option.
The column names from the CSV file are then converted into acceptable column names for the table.

Example: `ruby csv2sqlite.rb -H` ...

By default the column names in the database table start with `A`, `B`, `C` and so on ...

## Full Example

You'll find a complete example in the [test](test) directory.
