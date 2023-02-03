defmodule Prettiex.Check do
  alias Prettiex.Check.{
    Meta,
    Definition,
    Sequence,
    Alternative,
    All,
    Reduce,
    Pattern
  }

  @pattern %Spark.Dsl.Entity{
    name: :pattern,
    target: Pattern,
    args: [],
    schema: [
      form: [type: :quoted, required: true],
      skip?: [type: :boolean, default: false]
    ]
  }

  @sequence %Spark.Dsl.Entity{
    name: :sequence,
    describe: "Matches if all patterns match in order",
    examples: [
      # TODO(drgmr): add an example
    ],
    target: Sequence,
    entities: [patterns: @pattern]
  }

  @alternative %Spark.Dsl.Entity{
    name: :alternative,
    describe: "Matches if all patterns match in order",
    examples: [
      # TODO(drgmr): add an example
    ],
    target: Alternative,
    args: [],
    schema: [
      pattern: [
        type: :string,
        required: true,
        doc: "Patterns to be matched on, in sequence"
      ]
    ]
  }

  @all %Spark.Dsl.Entity{
    name: :all,
    describe: "Matches if all patterns match in order",
    examples: [
      # TODO(drgmr): add an example
    ],
    target: All,
    entities: [patterns: @pattern]
  }

  @reduce %Spark.Dsl.Entity{
    name: :reduce,
    describe: "Matches if all patterns match in order",
    examples: [
      # TODO(drgmr): add an example
    ],
    target: Reduce,
    args: [],
    schema: [
      pattern: [
        type: {:list, :quoted},
        required: true,
        doc: "foo"
      ]
    ]
  }

  @definition %Spark.Dsl.Entity{
    name: :definition,
    target: Definition,
    entities: [
      sequence: @sequence,
      alternative: @alternative,
      all: @all,
      reduce: @reduce
    ]
  }

  @meta %Spark.Dsl.Entity{
    name: :meta,
    describe: "Data that identifies and describes a Check",
    examples: [
      # TODO(drgmr): add an example
    ],
    target: Meta,
    args: [],
    schema: [
      name: [
        type: :string,
        required: true,
        doc: "The check's name"
      ],
      message: [
        type: :string,
        required: true,
        doc: "A message to be displayed if the check matches something"
      ],
      description: [
        type: :string,
        required: true,
        doc: "A detailed description of the issue found"
      ]
    ]
  }

  @check %Spark.Dsl.Section{
    name: :check,
    entities: [@meta, @definition]
  }

  use Spark.Dsl.Extension,
    sections: [@check]
end
