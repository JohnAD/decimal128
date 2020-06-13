# CONTRIBUTING

Contributions are very welcome!

## SENDING A PR

Simply send a pull request (PR) to the repo and I will review it.

I *will* review all PRs. But I might not accept all of them. 

So, if the PR is large and involved, I recommend starting a work-in-progress PR before
you begin coding. Simply create a empty (or nearly empty) PR with a title prefixed
with `[WIP]`. I will get involved in a conversation with you in the PR's discussion thread.

## CODING STYLE

Please following Nim's general convention for coding style. This can be found here:

  https://nim-lang.org/docs/nep1.html

A few notable exceptions:

* The max line length is 132 not 80. This encourages descriptive identifiers and makes
  for cleaner formatting IMO.
* In unit tests, line length limits MAY be ignored completely as long as the resulting code is not misleading.

Additional coding style rules:

* If you wish to visually separate two blocks of code in a procedure, use empty comments (#) you MUST NOT use empty lines.
* You MUST visually separate procedures with 2 empty lines.
* You MAY visually separate DSL with single empty lines.
* If a source file is really long; break it up into sections with a section header like:
  ```
      code here


      # #################################################
      #
      # BLAH BLAH SECTION
      #
      # #################################################


      more code here
  ```
  Notice the two empty lines before/after.
* You MUST NOT start a comment with two hash symbols (`##`) unless it is part of documentation.
* You MUST NOT start a comment with hash-bang (`#!`) unless you are doing it as a directive to my doc generator.

## DOCNIMBLE

I'm using a privately-written poorly-documented doc-generator tool called `docnimble`, so don't worry about updating
the docs. The tool looks for `##` and `#!` comments  to automatically generate the content.

Or start a `WIP` PR and I'll explain how my tool is used. I probably should document that thing some day.
