{-# LANGUAGE DataKinds #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Logger where

import Colog (LogAction (..), LoggerT (..), Message)
import Control.Applicative (Alternative (..))
import Control.Monad.IO.Class (MonadIO (..))
import Control.Monad.Reader (ReaderT (..))
import Control.Monad.Reader.Class (MonadReader (ask, local))
import PyF (PyFCategory (PyFString), PyFClassify, PyFToString (..), fmt)
import UnliftIO (MonadUnliftIO (withRunInIO))

newtype MyLoggerT msg m a = MyLoggerT {_myLoggerT :: LoggerT msg m a}
  deriving newtype (Functor, Applicative, Monad, MonadIO)

type MyLogger = MyLoggerT Message IO

instance Alternative m => Alternative (MyLoggerT msg m) where
  empty = MyLoggerT $ LoggerT empty
  (<|>) :: MyLoggerT msg m a -> MyLoggerT msg m a -> MyLoggerT msg m a
  (<|>) (MyLoggerT (LoggerT r1)) (MyLoggerT (LoggerT r2)) = MyLoggerT (LoggerT (r1 <|> r2))

instance MonadUnliftIO m => MonadUnliftIO (MyLoggerT msg m) where
  withRunInIO :: ((forall a. MyLoggerT msg m a -> IO a) -> IO b) -> MyLoggerT msg m b
  withRunInIO action = MyLoggerT $ LoggerT $ withRunInIO $ \runInIO -> action $ \(MyLoggerT (LoggerT x)) -> runInIO x

instance Monad m => MonadReader (LogAction (MyLoggerT msg m) msg) (MyLoggerT msg m) where
  ask :: MyLoggerT msg m (LogAction (MyLoggerT msg m) msg)
  ask = MyLoggerT $ LoggerT $ ReaderT $ \(LogAction l) -> pure $ LogAction $ MyLoggerT . l
  local :: (LogAction (MyLoggerT msg m) msg -> LogAction (MyLoggerT msg m) msg) -> MyLoggerT msg m a -> MyLoggerT msg m a
  local f g = do
    let MyLoggerT (LoggerT (ReaderT r)) = g
    MyLoggerT (LoggerT (ReaderT $ \(LogAction l) -> r (LogAction (_myLoggerT . unLogAction (f (LogAction (MyLoggerT . l)))))))

data ActionStatus = INFO | START | FAIL | ABORT | FINISH

instance Show ActionStatus where
  show :: ActionStatus -> String
  show d =
    let
      repr :: ActionStatus -> String
      repr e = case e of
        INFO -> "INFO"
        START -> "START"
        FAIL -> "FAIL"
        ABORT -> "ABORT"
        FINISH -> "FINISH"
      width = maximum $ length . repr <$> [INFO, START, FAIL, ABORT, FINISH]
     in
      (\x -> [fmt|[ {x <> (replicate (width - length x) ' ') } ]|]) (repr d)

type instance PyFClassify ActionStatus = 'PyFString

instance PyFToString ActionStatus where
  pyfToString = show