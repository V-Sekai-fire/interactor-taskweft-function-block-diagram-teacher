# interactor-taskweft-function-block-diagram-teacher

A teacher model that answers only in IEC 61131-3 Function Block Diagrams, with the compiler-labelled corpus that trains it.

## What it is for

A grammar admits only the diagram subset `taskweft-fbd-compiler` parses, the compiler and a sandbox label every candidate, and a frozen judge scores the rest. Constructed rows are ordinary training data; generated rows carry their model, checkpoint, prompt and grammar hash and are stored apart from them. RFD 2236 owns the design.

## Building and running

```sh
pixi run write-rows
mix test
```

`write-rows` builds the training corpus; the pixi tasks name the other corpus families and the publish steps.

## Licence

MIT. See [LICENSE](LICENSE).
