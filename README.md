# Minimal example

This repository serves as a minimal example to showcase an issue where HLS is giving a false negative as a compilation error.

The errors seems to be connected to a lacking configuration for hie.

Although `cabal build` and `cabal repl lib:minex` works, `hie-bios check lib:minex` will fail.
The failure is related to template haskell.

A very brief explanation on what happens in the template haskell part:

The Haskell code is transpiled to a representation compatible with [`plutus-core`](https://github.com/input-output-hk/plutus).
It is a necessity that every Haskell function used is `INLINEABLE`.
It seems that either `mkExampleValidator` is not recognized as being `INLINEABLE` or something is wrong with the dependencies?

## Building

On some machines I would have to do a `cabal build --ghc-options=-dynamic` to make the build work.
As far as I can tell I was able to observe the same behavior on all my machines no matter if the build was done with `cabal build` or adding the `-dynamic` flag.

# Error in question

According to the first line the problem function might be `Ledger.Typed.Scripts.Validators.wrapValidator`.
This function is `INLINEABLE` and I posted its implementation below for reference in case this helps.

```
hie-bios: GHC Core to PLC plugin: E043:Error: Reference to a name which is not a local, a builtin, or an external INLINABLE function: Variable Ledger.Typed.Scripts.Validators.wrapValidator
            No unfolding
Context: Compiling expr: Ledger.Typed.Scripts.Validators.wrapValidator
Context: Compiling expr: Ledger.Typed.Scripts.Validators.wrapValidator
                           @ MyLib.ExampleInput
Context: Compiling expr: Ledger.Typed.Scripts.Validators.wrapValidator
                           @ MyLib.ExampleInput @ MyLib.ExampleInput
Context: Compiling expr: Ledger.Typed.Scripts.Validators.wrapValidator
                           @ MyLib.ExampleInput
                           @ MyLib.ExampleInput
                           MyLib.$fUnsafeFromDataExampleInput
Context: Compiling expr: Ledger.Typed.Scripts.Validators.wrapValidator
                           @ MyLib.ExampleInput
                           @ MyLib.ExampleInput
                           MyLib.$fUnsafeFromDataExampleInput
                           MyLib.$fUnsafeFromDataExampleInput
Context: Compiling expr at "minex-0.1.0.0-inplace:MyLib:(36,8)-(36,35)"
```

Can be found [here](https://github.com/input-output-hk/plutus-apps/blob/e4062bca213f233cdf9822833b07aa69dff6d22a/plutus-ledger/src/Ledger/Typed/Scripts/Validators.hs#L84):
```
{-# INLINABLE wrapValidator #-}
wrapValidator
    :: forall d r
    . (UnsafeFromData d, UnsafeFromData r)
    => (d -> r -> Validation.ScriptContext -> Bool)
    -> WrappedValidatorType
-- We can use unsafeFromBuiltinData here as we would fail immediately anyway if parsing failed
wrapValidator f d r p = check $ f (unsafeFromBuiltinData d) (unsafeFromBuiltinData r) (unsafeFromBuiltinData p)
```
