{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoImplicitPrelude #-}

module MyLib where

import Ledger
import qualified Ledger.Typed.Scripts as Scripts
import qualified PlutusTx
import PlutusTx.Prelude

newtype ExampleInput = EW Integer

PlutusTx.unstableMakeIsData ''ExampleInput

data ExampleType

instance Scripts.ValidatorTypes ExampleType where
  type RedeemerType ExampleType = ExampleInput
  type DatumType ExampleType = ExampleInput

-- mkExampleValidator is just an example on-chain validator which is always
-- valid, hence returning True. It has to be `INLINEABLE` for
-- `PlutusTx.compile` to work.
{-# INLINEABLE mkExampleValidator #-}
mkExampleValidator :: ExampleInput -> ExampleInput -> ScriptContext -> Bool
mkExampleValidator _ _ _ = True

typedValidator :: Scripts.TypedValidator ExampleType
typedValidator =
  Scripts.mkTypedValidator @ExampleType
    $$(PlutusTx.compile [||mkExampleValidator||])
    $$(PlutusTx.compile [||wrap||])
  where
    wrap = Scripts.wrapValidator @ExampleInput @ExampleInput
