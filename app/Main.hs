{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}

module Main where

import Web.Scotty as S
import Data.Aeson
import qualified  Data.Text as Txt 
import System.Exit
import Control.Monad.IO.Class (liftIO)
import Control.Monad (void)
import GHC.IO.Handle
import GHC.Generics
import qualified System.Directory as SysDir
import qualified System.Process as SysProc

main :: IO ()
main =
  mkModuleDirIfNotThere >>
  startToolServer

startToolServer :: IO ()
startToolServer = scotty 8181 $ do
  get  "/list" $ S.json =<< liftIO listModules
  post "/call" $ jsonData >>= \(res :: PythonCall) -> liftIO (execModule res) >>= S.json
  get  "/stop/:modelname" $ captureParam "modelname" >>= liftIO . stopLLMModel

mkModuleDirIfNotThere :: IO ()
mkModuleDirIfNotThere = SysDir.createDirectoryIfMissing True "./modules"

listModules :: IO ModList
listModules = ModList . map (`PythonMod` "") <$> SysDir.listDirectory "./modules"

stopLLMModel :: String -> IO ()
stopLLMModel model_name = void $ SysProc.createProcess $ SysProc.shell model_name
        
                              
execModule :: PythonCall -> IO PythonResults
execModule parameters = SysProc.createProcess ((SysProc.shell $ mkShellString parameters){ SysProc.std_out = SysProc.CreatePipe }) >>=
           (\case
              (_, Just hOut, _, pHandle) -> hGetContents hOut >>= (\content -> 
                                      if null content 
                                        then PythonResults "<null>" . exitCodeToInt <$> SysProc.waitForProcess pHandle
                                        else PythonResults content .  exitCodeToInt <$> SysProc.waitForProcess pHandle)
              _ -> return $ PythonResults "Process creation failure" (-1))


exitCodeToInt :: ExitCode -> Int 
exitCodeToInt ExitSuccess = 0
exitCodeToInt (ExitFailure i) = i 

mkShellString  :: PythonCall -> String
mkShellString pycall = let 
                        module_str = "python modules/" ++ modName pycall ++ ".py" 
                       in 
                        foldMap (++ " ") $  module_str : getParams pycall 
                  
getParams :: PythonCall -> [String]
getParams pycall = filter strIsNotEmpty [p0 pycall, p1 pycall, p2 pycall, p3 pycall, p4 pycall]

strIsNotEmpty :: String -> Bool
strIsNotEmpty str 
  | not (null str)= True
  | otherwise = False 
         
data PythonResults = PythonResults { pyOutput :: String, exitcode :: Int } deriving (Generic, Show)
data PythonCall = PythonCall { modName :: String, p0 :: String, p1 :: String, p2 :: String, p3 :: String, p4 :: String } deriving (Generic, Show)
data PythonMod = PythonMod { name :: String, description :: String } deriving (Generic, Show)
newtype ModList = ModList { modules :: [PythonMod] } deriving (Generic, Show)


instance ToJSON PythonResults where
instance FromJSON PythonResults
 
instance ToJSON PythonCall where
instance FromJSON PythonCall 
                     
instance ToJSON ModList where
instance FromJSON ModList 

instance ToJSON  PythonMod where
instance FromJSON PythonMod
