let SampleRate = Natural

let
    -- | https://github.com/honeycombio/refinery/blob/8810c625279627f7fd0b7ca967470dd38a80712c/config/file_config.go#L37
    Sampler =
      < DeterministicSampler
      | DynamicSampler
      | EMADynamicSampler
      | RulesBasedSampler
      | TotalThroughputSampler
      >

let
    -- | https://github.com/honeycombio/refinery/blob/50ca88449e6ee4b6a8f413615ad357ad0e4f8a1d/config/sampler_config.go#L35-L42
    TotalThroughputSamplerConfig =
      { Type =
          { GoalThroughputPerSec : Natural
          , ClearFrequencySec : Natural
          , FieldList : List Text
          , UseTraceLength : Bool
          , AddSampleRateKeyToTrace : Bool
          , AddSampleRateKeyToTraceField : Optional Text
          }
      , default =
        { UseTraceLength = False, AddSampleRateKeyToTrace = None Text }
      }

let
    -- | https://github.com/honeycombio/refinery/blob/50ca88449e6ee4b6a8f413615ad357ad0e4f8a1d/config/sampler_config.go#L20-L33
    EMADynamicSamplerConfig =
      { Type =
          { GoalSampleRate : Natural
          , AdjustmentInterval : Natural
          , Weight : Double
          , AgeOutValue : Double
          , BurstMultiple : Double
          , BurstDetectionDelay : Natural
          , MaxKeys : Natural
          , FieldList : List Text
          , UseTraceLength : Bool
          , AddSampleRateKeyToTrace : Bool
          , AddSampleRateKeyToTraceField : Optional Text
          }
      , default =
        { AdjustmentInterval = 0
        , Weight = 0.0
        , AgeOutValue = 0.0
        , BurstMultiple = 0.0
        , BurstDetectionDelay = 0
        , MaxKeys = 0
        , UseTraceLength = False
        , AddSampleRateKeyToTrace = False
        , AddSampleRateKeyToTraceField = None Text
        }
      }

in  { Sampler, SampleRate, EMADynamicSamplerConfig, TotalThroughputSamplerConfig }
