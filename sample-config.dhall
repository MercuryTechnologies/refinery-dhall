let R = ./rules.dhall

let Rules = R.Rules

let Dataset = R.Dataset

let RulesBasedSamplerConfig = R.RulesBasedSamplerConfig

let RulesBasedSamplerRule = R.RulesBasedSamplerRule

let ShouldSample = R.ShouldSample

let Operator = R.Operator

let FieldType = R.FieldType

let RulesBasedDownstreamSampler = R.RulesBasedDownstreamSampler

let EMADynamicSamplerConfig = R.EMADynamicSamplerConfig

let TotalThroughputSamplerConfig = R.TotalThroughputSamplerConfig

let prodDataset =
      Dataset.RulesBasedSampler
        RulesBasedSamplerConfig::{
        , rule =
          [ RulesBasedSamplerRule::{
            , Name = "drop index queries"
            , ShouldSample = ShouldSample.Drop
            , condition =
              [ { Field = "http.route"
                , Operator = Operator.equal (FieldType.Text "/")
                }
              ]
            }
          , RulesBasedSamplerRule::{
            , Name = "backend downstream sampler"
            , ShouldSample = ShouldSample.Sample 1
            , condition =
              [ { Field = "service.name"
                , Operator = Operator.equal (FieldType.Text "backend")
                }
              ]
            , Sampler = Some
                ( RulesBasedDownstreamSampler.EMADynamicSampler
                    { EMADynamicSampler =
                            EMADynamicSamplerConfig::{
                            , GoalSampleRate = 100
                            , UseTraceLength = True
                            , AddSampleRateKeyToTrace = True
                            , AddSampleRateKeyToTraceField = Some
                                "meta.refinery.dynsampler_key"
                            , AdjustmentInterval = 60
                            , MaxKeys = 10000
                            , Weight = 0.5
                            , FieldList =
                              [ "http.method", "http.path", "http.status_code" ]
                            }
                        //  { Sampler = "EMADynamicSampler" }
                    }
                )
            }
          , RulesBasedSamplerRule::{
            , Name = "worker downstream sampler"
            , ShouldSample = ShouldSample.Sample 1
            , condition =
              [ { Field = "service.name"
                , Operator = Operator.equal (FieldType.Text "worker")
                }
              ]
            , Sampler = Some
                ( RulesBasedDownstreamSampler.TotalThroughputSampler
                    { TotalThroughputSampler =
                            TotalThroughputSamplerConfig::{
                            , FieldList = [ "type", "name" ]
                            , GoalThroughputPerSec = 200
                            , ClearFrequencySec = 30
                            , AddSampleRateKeyToTrace = True
                            , AddSampleRateKeyToTraceField = Some
                                "meta.refinery.dynsampler_key"
                            , UseTraceLength = True
                            }
                        //  { Sampler = "TotalThroughputSampler" }
                    }
                )
            }
          ]
        }

in      Rules::{=}
    //  { -- n.b. this is in this structure since Dhall doesn't let us write a function
          -- "fromMap" with a type like: Map Text V -> { key... : V }
          --
          -- In this approach vs converting to Prelude.JSON.Type, type safety is a bit
          -- worse, boilerplate of "render" functions is way less, and "oops" safety
          -- (due to avoiding screwing up the boilerplate) is a bit better.
          production = R.Dataset/render prodDataset
        }
