# Dhall expressions for Honeycomb Refinery configuration

These expressions are intended to make it easier to write correct configuration
files for [Honeycomb Refinery].

Currently this repo provides type definitions for the rules file, which can be
used with `dhall-toml` or `dhall-yaml` (since it accepts either format!). The
main configuration file is not currently covered.

Do note that `dhall-toml` needs to be an extremely recent version [due to a
bugfix][dhall-toml-bugfix]. It's probably easier to use YAML :)

[dhall-toml-bugfix]: https://github.com/dhall-lang/dhall-haskell/pull/2469

## Rules file

[Example rules config file](./example-config.dhall)

[Honeycomb Refinery]: https://github.com/honeycombio/refinery
