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
import System.Process

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
stopLLMModel model_name = void $ createProcess $ shell model_name
        
                              
execModule :: PythonCall -> IO PythonResults
execModule parameters = createProcess ((mkProcessInfo $ mkShellString parameters){ std_out = CreatePipe }) >>=
           (\case
              (_, Just hOut, _, pHandle) -> hGetContents hOut >>= (\content -> 
                                      if null content 
                                        then PythonResults "<null>" . exitCodeToInt <$> waitForProcess pHandle
                                        else PythonResults content .  exitCodeToInt <$> waitForProcess pHandle)
              _ -> return $ PythonResults "Process creation failure" (-1))


exitCodeToInt :: ExitCode -> Int 
exitCodeToInt ExitSuccess = 0
exitCodeToInt (ExitFailure i) = i 

mkShellString  :: PythonCall -> [String]
mkShellString pycall = let
                        moduleStrList = ["python" , "modules/" ++ modName pycall ++ ".py"] 
                       in 
                        moduleStrList ++ getParams pycall
                  
getParams :: PythonCall -> [String]
getParams pycall = filter strIsNotEmpty [p0 pycall, p1 pycall, p2 pycall, p3 pycall, p4 pycall]


mkProcessInfo :: [String] -> CreateProcess
mkProcessInfo (x:xs) = CreateProcess {
                    cmdspec = RawCommand x xs,
                    cwd = Nothing,
                    env = Nothing,
                    std_in = Inherit,
                    std_out = Inherit,
                    std_err = Inherit,
                    close_fds = False,
                    create_group = False,
                    delegate_ctlc = False,
                    detach_console = False,
                    create_new_console = False,
                    new_session = False,
                    child_group = Nothing,
                    child_user = Nothing,
                    use_process_jobs = False }

strIsNotEmpty :: String -> Bool
strIsNotEmpty str 
  | not (null str) = True
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
