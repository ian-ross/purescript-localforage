module Localforage
  ( LocalforageConfig
  , LocalforageConfigRep
  , Localforage
  , LOCALFORAGE_DRIVERS(..)
  , createInstance
  , defaultLocalforageConfig
  , getItem
  , setItem
  , removeItem
  , clear
  , keys
  ) where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (Aff, Error, attempt, error, makeAff, nonCanceler)
import Foreign (Foreign)

foreign import getLocalforageDriver :: String -> Foreign


foreign import data Localforage :: Type

data LOCALFORAGE_DRIVERS = WEBSQL | INDEXEDDB | LOCALSTORAGE
encodeDriver :: LOCALFORAGE_DRIVERS -> Foreign
encodeDriver WEBSQL = getLocalforageDriver "websql"
encodeDriver INDEXEDDB = getLocalforageDriver "indexeddb"
encodeDriver LOCALSTORAGE = getLocalforageDriver "localstorage"

type LocalforageConfigRep a =
  { driver :: a
  , name :: String
  , version :: Number
  , size :: Int -- Size of database, in bytes. WebSQL-only for now.
  , storeName :: String -- // Should be alphanumeric, with underscores.
  , description :: String
  }

type LocalforageConfig = LocalforageConfigRep LOCALFORAGE_DRIVERS

defaultLocalforageConfig :: LocalforageConfig
defaultLocalforageConfig = {
  driver: INDEXEDDB,
  name: "localforage",
  version: 1.0,
  size: 4980736,
  storeName: "keyvaluepairs",
  description: ""
}

encodeConfig :: LocalforageConfig -> LocalforageConfigRep Foreign
encodeConfig cfg = cfg { driver = encodeDriver cfg.driver }

foreign import _createInstance :: LocalforageConfigRep Foreign -> Effect Localforage
foreign import _dropInstance :: (Effect Unit) -> (String -> Effect Unit) -> Localforage -> Effect Unit
foreign import _keys :: ((Array String) -> Effect Unit) -> (String -> Effect Unit) -> Localforage -> Effect Unit
foreign import _clear :: (Effect Unit) -> (String -> Effect Unit) -> Localforage -> Effect Unit
foreign import _setItem :: (Foreign -> Effect Unit) -> (String -> Effect Unit) -> Localforage -> String -> Foreign -> Effect Unit
foreign import _getItem :: (Foreign -> Effect Unit) -> (String -> Effect Unit) -> Localforage -> String -> Effect Unit
foreign import _removeItem :: (Effect Unit) -> (String -> Effect Unit) -> Localforage -> String -> Effect Unit

-- | Creates a new instance.
createInstance :: LocalforageConfig -> Effect Localforage
createInstance = _createInstance <<< encodeConfig

-- | When invoked with no arguments, it drops the “store” of the current instance.
dropInstance :: Localforage -> Aff (Either Error Unit)
dropInstance db = attempt $ makeAff (\cb -> _dropInstance (cb $ Right unit) (error >>> Left >>> cb) db *> pure nonCanceler)

-- | Gets an item from the storage library. If the key does not exist, `getItem` will return `null`.
getItem :: Localforage -> String -> Aff (Either Error Foreign)
getItem db key = attempt $ makeAff (\cb -> _getItem (Right >>> cb) (error >>> Left >>> cb) db key *> pure nonCanceler)

-- | Saves data to an offline store.
setItem :: Localforage -> String -> Foreign -> Aff (Either Error Foreign)
setItem db key value = attempt $ makeAff(\cb -> _setItem (Right >>> cb) (error >>> Left >>> cb) db key value *> pure nonCanceler)

-- | Removes the value of a key from the offline store.
removeItem :: Localforage -> String -> Aff (Either Error Unit)
removeItem db key = attempt $ makeAff(\cb -> _removeItem (cb $ Right unit) (error >>> Left >>> cb) db key *> pure nonCanceler)

-- | Removes every key from the database, returning it to a blank slate.
clear :: Localforage -> Aff (Either Error Unit)
clear db = attempt $ makeAff(\cb -> _clear (cb $ Right unit) (error >>> Left >>> cb) db *> pure nonCanceler)

-- | Get the list of all keys in the datastore.
keys :: Localforage -> Aff (Either Error (Array String))
keys db = attempt $ makeAff(\cb -> _keys (Right >>> cb) (error >>> Left >>> cb) db *> pure nonCanceler)
