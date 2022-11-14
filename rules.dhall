let RB = ./rules_based.dhall

let S = ./sampler.dhall

let
    -- | Fields inferred by staring down the parsing code at
    -- https://github.com/honeycombio/refinery/blob/8810c625279627f7fd0b7ca967470dd38a80712c/config/file_config.go#L170-L190
    Rules =
      { Type =
          { Sampler : Optional S.Sampler
          , SampleRate : Optional S.SampleRate
          , DryRun : Optional Bool
          , DryRunFieldName : Optional Text
          }
      , default =
        { Sampler = None S.Sampler
        , SampleRate = None S.SampleRate
        , DryRun = None Bool
        , DryRunFieldName = None Text
        }
      }

let Dataset =
    -- | One dataset.
    -- FIXME(jadel): add more sampler types
      < RulesBasedSampler : RB.RulesBasedSamplerConfig.Type >

let Dataset/render =
      \(ds : Dataset) ->
        merge
          { RulesBasedSampler =
              \(config : RB.RulesBasedSamplerConfig.Type) ->
                    { Sampler = "RulesBasedSampler" }
                //  RB.RulesBasedSamplerConfig/render config
          }
          ds

in  RB // S // { Rules, Dataset, Dataset/render }
