### Usage

`ruby abbrv.rb ~/dev/pet/abbrv/language.json`

### Features

* Arbitrary length shortcuts.
* TODO: Cancel shortcuts with Escape.
* TODO: Context dependent shortcuts.

### Chores

* Extract parser.
  - Parse using Parsec.
  - Validate the language file using the parser.
* Write tests.
* Try to run in Docker.
* Rewrite in Haskell?

### Available Actions

* Close current window.
* Focus or open an application.
* Focus or open a project.
* Type text.
