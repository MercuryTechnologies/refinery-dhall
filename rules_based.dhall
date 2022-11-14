let Prelude =
      https://prelude.dhall-lang.org/v20.1.0/package.dhall
        sha256:26b0ef498663d269e4dc6a82b0ee289ec565d683ef4c00d0ebdd25333a5a3c98

let S = ./sampler.dhall

let
    -- | Types inferred from https://github.com/honeycombio/refinery/blob/8810c625279627f7fd0b7ca967470dd38a80712c/sample/rules.go#L284-L366
    FieldType =
      < Text : Text | Int : Integer | Double : Double | Bool : Bool >

let
    -- | https://github.com/honeycombio/refinery/blob/8810c625279627f7fd0b7ca967470dd38a80712c/sample/rules.go#L195-L258
    Operator =
      < exists
      | doesNotExist
      | notEqual : FieldType
      | equal : FieldType
      | greaterThan : FieldType
      | greaterThanEqual : FieldType
      | lessThan : FieldType
      | lessThanEqual : FieldType
      | startsWith : Text
      | contains : Text
      | doesNotContain : Text
      >

let
    -- | Some condition on a field's value somewhere in the trace or span.
    --
    -- https://github.com/honeycombio/refinery/blob/50ca88449e6ee4b6a8f413615ad357ad0e4f8a1d/config/sampler_config.go#L44-L48
    RulesBasedSamplerCondition =
      { Field : Text, Operator : Operator }

let
    -- | Type unsafe version of RulesBasedSamplerCondition
    RulesBasedSamplerConditionRendered =
      { Field : Text, Operator : Text, Value : Optional FieldType }

let RulesBasedSamplerCondition/render =
      \(rule : RulesBasedSamplerCondition) ->
        let comparison =
              \(name : Text) ->
              \(value : FieldType) ->
                { Field = rule.Field, Operator = name, Value = Some value }

        let textOperator =
              \(name : Text) ->
              \(value : Text) ->
                { Field = rule.Field
                , Operator = name
                , Value = Some (FieldType.Text value)
                }

        in  merge
              { exists =
                { Field = rule.Field
                , Operator = "exists"
                , Value = None FieldType
                }
              , doesNotExist =
                { Field = rule.Field
                , Operator = "not-exists"
                , Value = None FieldType
                }
              , notEqual = comparison "!="
              , equal = comparison "="
              , greaterThan = comparison ">"
              , greaterThanEqual = comparison ">="
              , lessThan = comparison "<"
              , lessThanEqual = comparison "<="
              , startsWith = textOperator "starts-with"
              , contains = textOperator "contains"
              , doesNotContain = textOperator "does-not-contain"
              }
              rule.Operator

let ShouldSample = < Drop | Sample : S.SampleRate >

let
    -- | https://github.com/honeycombio/refinery/blob/50ca88449e6ee4b6a8f413615ad357ad0e4f8a1d/config/sampler_config.go#L54-L58
    -- FIXME(jadel): add DynamicSampler
    RulesBasedDownstreamSampler =
      < EMADynamicSampler :
          { EMADynamicSampler :
              { Sampler : Text } //\\ S.EMADynamicSamplerConfig.Type
          }
      | TotalThroughputSampler :
          { TotalThroughputSampler :
              { Sampler : Text } //\\ S.TotalThroughputSamplerConfig.Type
          }
      >

let
    -- | "span" specifies that all the conditions must be met on one single span to
    -- sample the trace.
    --
    -- "trace" specifies that the trace will be sampled if there is at least one
    -- span matching each condition in the trace.
    --
    -- That is, with conditions (prop3 = "b", prop2 = 17), the following trace will
    -- match in "trace" scope:
    --
    -- - span1: prop1=4, prop3="b"
    -- - span2: prop2=17, prop3="a"
    --
    -- Source: https://github.com/honeycombio/refinery/blob/8810c625279627f7fd0b7ca967470dd38a80712c/sample/rules.go#L71-L85
    RuleScope =
      < span | trace >

let
    -- | https://github.com/honeycombio/refinery/blob/50ca88449e6ee4b6a8f413615ad357ad0e4f8a1d/config/sampler_config.go#L60-L67
    RulesBasedSamplerRule =
      { Type =
          { Name : Text
          , ShouldSample : ShouldSample
          , Scope : RuleScope
          , Sampler : Optional RulesBasedDownstreamSampler
          , condition : List RulesBasedSamplerCondition
          }
      , default =
        { Scope = RuleScope.trace, Sampler = None RulesBasedDownstreamSampler }
      }

let RulesBasedSamplerRuleRendered =
      { Name : Text
      , SampleRate : S.SampleRate
      , Drop : Bool
      , Scope : RuleScope
      , Sampler : Optional RulesBasedDownstreamSampler
      , condition : List RulesBasedSamplerConditionRendered
      }

let RulesBasedSamplerRule/render
    : RulesBasedSamplerRule.Type -> RulesBasedSamplerRuleRendered
    = \(rule : RulesBasedSamplerRule.Type) ->
            rule.{ Name, Scope, Sampler }
        //  { Drop =
                merge
                  { Drop = True, Sample = \(_ : S.SampleRate) -> False }
                  rule.ShouldSample
            , SampleRate =
                merge
                  { Drop = 0, Sample = \(rate : S.SampleRate) -> rate }
                  rule.ShouldSample
            , condition =
                Prelude.List.map
                  RulesBasedSamplerCondition
                  RulesBasedSamplerConditionRendered
                  RulesBasedSamplerCondition/render
                  rule.condition
            }

let RulesBasedSamplerConfig =
      { Type = { rule : List RulesBasedSamplerRule.Type }
      , default.rule = [] : List RulesBasedSamplerRule.Type
      }

let RulesBasedSamplerConfigRendered =
      { rule : List RulesBasedSamplerRuleRendered }

let RulesBasedSamplerConfig/render
    : RulesBasedSamplerConfig.Type -> RulesBasedSamplerConfigRendered
    = \(config : RulesBasedSamplerConfig.Type) ->
            config
        //  { rule =
                Prelude.List.map
                  RulesBasedSamplerRule.Type
                  RulesBasedSamplerRuleRendered
                  RulesBasedSamplerRule/render
                  config.rule
            }

in  { FieldType
    , Operator
    , ShouldSample
    , RulesBasedSamplerRule
    , RulesBasedSamplerConfig
    , RulesBasedSamplerConfig/render
    , RulesBasedDownstreamSampler
    }
