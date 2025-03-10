{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}

module Main where
import Data.Aeson
import qualified  Data.Text as Txt 
import System.Exit
import Control.Monad.IO.Class (liftIO)
import Control.Exception
import Control.Monad (void)
import GHC.IO.Handle
import GHC.Generics
import Network.Socket
import qualified Network.Socket.ByteString as NBS
import System.IO
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified System.Directory as SysDir
import System.Process

main :: IO ()
main = do
  mkModuleDirIfNotThere
  sock <- socket AF_INET Stream 0
  setSocketOption sock KeepAlive 1
  bind sock $ SockAddrInet 8181 0
  listen sock 2
  putStrLn "[*] Tool server started on port 8181"
  mainLoop sock
  

mainLoop :: Socket -> IO ()
mainLoop sock = do
  (connSock, _) <- accept sock
  putStrLn "[*] Started session with RPC client"
  commLoop connSock
  mainLoop sock


commLoop :: Socket -> IO ()
commLoop sock = do
  bs <- NBS.recv sock $ 4096 * 4
  case (decode $ BL.fromStrict bs) :: Maybe PythonCall of
    Nothing -> rpcSendError sock -- return malformed request error
    Just p -> do
                execModule p >>= rpcSend sock
                putStrLn $ "[*] Executed " ++ modName p ++ " module"
  
  commLoop sock
  
    


rpcSendError :: Socket -> IO ()
rpcSendError sock = NBS.sendAll sock $ BS.toStrict $ encode $ PythonResults "malformed text" 1


rpcSend :: Socket -> PythonResults -> IO ()
rpcSend sock pyresults = NBS.sendAll sock $ BS.toStrict $ encode pyresults

                 
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
