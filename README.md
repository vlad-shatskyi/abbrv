### Usage

`ruby abbrv.rb ~/dev/pet/abbrv/language.json`

### Features

* Arbitrary length shortcuts.
* TODO: Cancel shortcuts with Escape.
* TODO: Context dependent shortcuts.
* TODO: Chrome-specific actions.
  - Focus or launch website.
* TODO: Actions on current line of text.

### Available Actions

* Close current window.
* Focus or open an application.
* Focus or open a project.
* Open a website.
* Type text.

### Bugs

* Shortcuts don't work in gedit.

### Chores

* Extract parser.
  - Parse using Parsec.
  - Validate the language file using the parser.
* Write tests.
* Try to run in Docker.
* Rewrite in Haskell?
* Rewrite OSD to display a line of text in the system title bar.
