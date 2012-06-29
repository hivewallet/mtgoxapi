module DepthStoreTest
    (
    ) where

import Control.Applicative
import Data.Maybe
import Data.Time.Clock
import Data.Typeable
import Test.QuickCheck

import qualified Data.IxSet as I

import DepthStore

timestamp :: UTCTime
timestamp = read "2012-06-25 00:00:00 UTC"

instance Arbitrary DepthStoreEntry where
    arbitrary = do
        amount <- choose (1 * 10^8, 10 * 10^8)
        price <- choose (1 * 10^5, 8 * 10^5)
        return $ DepthStoreEntry amount price timestamp

returnDescending :: (I.Indexable a, Typeable a, Ord a) => [a] -> [a]
returnDescending entries =
    I.toDescList (I.Proxy :: I.Proxy Integer) $ I.fromList entries

returnAscending :: (I.Indexable a, Typeable a, Ord a) => [a] -> [a]
returnAscending entries =
    I.toAscList (I.Proxy :: I.Proxy Integer) $ I.fromList entries

propZeroAmountAlwaysOk :: [DepthStoreEntry] -> Bool
propZeroAmountAlwaysOk entries = case simulateBTC 0 (returnDescending entries) of
                                    Just _ -> True
                                    Nothing -> False

propLowerAmountAlwaysOk :: [DepthStoreEntry] -> Integer -> Integer -> Property
propLowerAmountAlwaysOk entries a1 a2 =
    let entries' = returnDescending entries
        sim1 = simulateBTC a1 entries'
        sim2 = simulateBTC a2 entries'
    in a1 >= 0 && a2 >= 0 && a1 >= a2 && isJust sim1 ==>
        isJust sim2 && checkTotalPriceIsHigherOrEqual sim1 sim2

propSellingAndBuyingMatches :: [DepthStoreEntry] -> Integer -> Property
propSellingAndBuyingMatches entries amount =
    let amount' = amount * 10^5
        entries' = returnAscending entries
        sim1 = simulateUSD amount' entries'
        sim2 = simulateBTC (fromMaybe 0 sim1) entries'
    in amount' >= 0 && isJust sim1 ==>
        isJust sim2 && Just amount' == sim2

checkTotalPriceIsHigherOrEqual (Just a) (Just b) = a >= b
checkTotalPriceIsHigherOrEqual _ _ = False
