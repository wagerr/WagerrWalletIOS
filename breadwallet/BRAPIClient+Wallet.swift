//
//  BRAPIClient+Wallet.swift
//  breadwallet
//
//  Created by Samuel Sutch on 4/2/17.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import Foundation

private let fallbackRatesURL = "https://bitpay.com/api/rates"
private let instaswapURL = "https://instaswap.wagerr.com/instaswap_service.php?s="

enum RatesResult {
    case success([Rate])
    case error(String)
}

extension BRAPIClient {

    func me() {
        let req = URLRequest(url: url("/me"))
        let task = dataTaskWithRequest(req, authenticated: true, handler: { data, response, err in
            if let data = data {
                print("me: \(String(describing: String(data: data, encoding: .utf8)))")
            }
        })
        task.resume()
    }

    func feePerKb(code: String, _ handler: @escaping (_ fees: Fees, _ error: String?) -> Void) {
        let param = code == Currencies.bch.code ? "?currency=bch" : ""
        let req = URLRequest(url: url("/fee-per-kb\(param)"))
        let task = self.dataTaskWithRequest(req) { (data, response, err) -> Void in
            var regularFeePerKb: uint_fast64_t = 10000
            var economyFeePerKb: uint_fast64_t = 5000
            var errStr: String? = nil
            if err == nil {
                do {
                    let parsedObject: Any? = try JSONSerialization.jsonObject(
                        with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                    if let top = parsedObject as? NSDictionary, let regular = top["fee_per_kb"] as? NSNumber, let economy = top["fee_per_kb_economy"] as? NSNumber {
                        regularFeePerKb = regular.uint64Value
                        economyFeePerKb = economy.uint64Value
                    }
                } catch (let e) {
                    self.log("fee-per-kb: error parsing json \(e)")
                }
                if regularFeePerKb == 0 || economyFeePerKb == 0 {
                    errStr = "invalid json"
                }
            } /*else {
                self.log("fee-per-kb network error: \(String(describing: err))")
                errStr = "bad network connection"
            }*/
            handler(Fees(regular: regularFeePerKb, economy: economyFeePerKb, timestamp: Date().timeIntervalSince1970), errStr)
        }
        task.resume()
    }
    
    /// Fetches Bitcoin exchange rates in all available fiat currencies
    func bitcoinExchangeRates(isFallback: Bool = false, _ handler: @escaping (RatesResult) -> Void) {
        let code = "BTC"
        let param = "?currency=\(code.lowercased())"
        let request = isFallback ? URLRequest(url: URL(string: fallbackRatesURL)!) : URLRequest(url: url("/rates\(param)"))
        let task = dataTaskWithRequest(request) { (data, response, error) in
            if error == nil, let data = data,
                let parsedData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                self.FetchCoinRate() { [weak self] result in
                    guard let `self` = self,
                        case .success(let CoinRates) = result else { return }
                    
                    // calculate token/fiat rates
                    if isFallback {
                        guard let array = parsedData as? [Any] else {
                            return handler(.error("/rates didn't return an array"))
                        }
                        handler(.success(CoinRates + array.compactMap { Rate(data: $0, reciprocalCode: code) }))
                    } else {
                        guard var dict = parsedData as? [String: Any],
                            let array = dict["body"] as? [Any] else {
                                return self.bitcoinExchangeRates(isFallback: true, handler)
                        }
                        handler(.success(CoinRates + array.compactMap { Rate(data: $0, reciprocalCode: code) }))
                    }
                }
            } else {
                if isFallback {
                    handler(.error("Error fetching from fallback url"))
                } else {
                    self.bitcoinExchangeRates(isFallback: true, handler)
                }
            }
        }
        task.resume()
    }

    func FetchCoinRate(_ handler: @escaping (RatesResult) -> Void) {
        let urlString = "https://api.crex24.com/CryptoExchangeService/BotPublic/ReturnTicker?request=[NamePairs=BTC_WGR]";
        var ret = [Rate]()
        
        guard let requestUrl = URL(string:urlString) else { return handler(.error("Coin rate not found")) }
        let request = URLRequest(url:requestUrl)
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error == nil,let usableData = data {
                
                struct Crex24TickerItem : Codable {
                    var PairId : integer_t!
                    var PairName : String!
                    var Last : double_t!
                    var LowPrice: double_t!
                    var HighPrice: double_t!
                    var PercentChange: double_t!
                    var BaseVolume: double_t!
                    var QuoteVolume: double_t!
                    var VolumeInBtc: double_t!
                    var VolumeInUsd: double_t!
                }
                
                struct Crex24TickerObject : Codable {
                    var Error : String!
                    var Tickers : [Crex24TickerItem]!
                }
                
                do {
                    let decoder = JSONDecoder()
                    let objData = try decoder.decode(Crex24TickerObject.self, from: usableData)
                    let coinrate = objData.Tickers[0].Last;
                    ret.append(Rate(code: Currencies.btc.code, name: Currencies.btc.name, rate: coinrate!, reciprocalCode:"BTC"))
                    handler(.success(ret))
                }
                catch let ex{
                    handler(.error(ex.localizedDescription))
                }
            }
        }
 
        task.resume()
        handler(.success(ret))
        return
    }
    
    // Explorer API
    func ExplorerTxInfo(txHash: String, handler: @escaping (ExplorerTxResult) -> Void) {
        let explorerURL = (E.isTestnet) ? "https://explorer2.wagerr.com" : "https://explorer.wagerr.com"
        let urlString = explorerURL + "/api/tx/" + txHash
        var ret : ExplorerTxData?

        guard let requestUrl = URL(string:urlString) else {
            return handler(.error("Error connecting to explorer"))
        }
        let request = URLRequest(url:requestUrl)
        let task = URLSession.shared.dataTask(with: request) {
           (data, response, error) in
           if error == nil,let usableData = data {
               do {
                    let decoder = JSONDecoder()
                    let ret = try decoder.decode(ExplorerTxData.self, from: usableData)
                    handler(.success(ret))
               }
               catch let ex{
                let de = ex as? DecodingError
                   handler(.error(ex.localizedDescription))
               }
           }
        }

        task.resume()
        return
    }
    
    func ExplorerTxPayoutInfo(txHash: String, vout: Int, handler: @escaping (ExplorerTxPayoutResult) -> Void) {
        let explorerURL = (E.isTestnet) ? "https://explorer2.wagerr.com" : "https://explorer.wagerr.com"
        let urlString = String.init(format: "%@/api/bet/infobypayout?payoutTx=%@&nOut=%d", explorerURL , txHash, vout )
        var ret : ExplorerTxPayoutData?

        guard let requestUrl = URL(string:urlString) else {
            return handler(.error("Error connecting to explorer"))
        }
        let request = URLRequest(url:requestUrl)
        let task = URLSession.shared.dataTask(with: request) {
           (data, response, error) in
           if error == nil,let usableData = data {
               do {
                    let decoder = JSONDecoder()
                    let ret = try decoder.decode(ExplorerTxPayoutData.self, from: usableData)
                    handler(.success(ret))
               }
               catch let ex{
                let de = ex as? DecodingError
                   handler(.error(ex.localizedDescription))
               }
           }
        }

        task.resume()
        return
    }
    
    // End Explorer API

    // Instaswap API
    func InstaswapTickers(getCoin: String, giveCoin: String, sendAmount: String, handler: @escaping (TickersResult) -> Void) {
        let urlString = instaswapURL + "InstaswapTickers&getCoin=\(getCoin)&giveCoin=\(giveCoin)&sendAmount=\(sendAmount)"
        var ret : TickersData?

        guard let requestUrl = URL(string:urlString) else {
            return handler(.error("Error connecting to Instaswap"))
        }
        let request = URLRequest(url:requestUrl)
        let task = URLSession.shared.dataTask(with: request) {
           (data, response, error) in
           if error == nil,let usableData = data {
               do {
                    let decoder = JSONDecoder()
                    let objData = try decoder.decode(TickersData.self, from: usableData)
                    guard objData.error == nil else  { return handler(.error(objData.error!)) }
                    ret = objData
                    handler(.success(ret!))
               }
               catch let ex{
                   handler(.error(ex.localizedDescription))
               }
           }
        }

        task.resume()
        return
    }

    func InstaswapSendSwap(getCoin: String, giveCoin: String, sendAmount: String, receiveWallet: String, refundWallet: String, handler: @escaping (SwapResult) -> Void) {

        let urlString = instaswapURL + "InstaswapSwap&getCoin=\(getCoin)&giveCoin=\(giveCoin)&sendAmount=\(sendAmount)&receiveWallet=\(receiveWallet)&refundWallet=\(refundWallet)&memo="
        var ret : SwapData?

        guard let requestUrl = URL(string:urlString) else { return handler(.error("Error connecting to Instaswap")) }
        let request = URLRequest(url:requestUrl)
        let task = URLSession.shared.dataTask(with: request) {
           (data, response, error) in
           if error == nil,let usableData = data {
               do {
                    let decoder = JSONDecoder()
                    let objData = try decoder.decode(SwapData.self, from: usableData)
                    guard objData.error == nil else  { return handler(.error(objData.error!)) }
                    ret = objData
                    handler(.success(ret!))
               }
               catch let ex{
                   handler(.error(ex.localizedDescription))
               }
           }
        }

        task.resume()
        return
    }
    
    func InstaswapListSwaps(wallet: String, handler: @escaping (SwapHistoryResult) -> Void) {

        let urlString = instaswapURL + "InstaswapReportWalletHistory&wallet=\(wallet)"
        var ret : ReportSwapHistoryData?

        guard let requestUrl = URL(string:urlString) else { return handler(.error("Error connecting to Instaswap")) }
        let request = URLRequest(url:requestUrl)
        let task = URLSession.shared.dataTask(with: request) {
           (data, response, error) in
           if error == nil,let usableData = data {
               do {
                    let decoder = JSONDecoder()
                    let objData = try decoder.decode(ReportSwapHistoryData.self, from: usableData)
                    guard objData.error == nil else  { return handler(.error(objData.error!)) }
                    ret = objData
                    handler(.success(ret!))
               }
               catch let ex{
                   handler(.error(ex.localizedDescription))
               }
           }
        }

        task.resume()
        return
    }
    // End Instaswap API
    
    /// Fetches all token exchange rates in BTC from CoinMarketCap
    func tokenExchangeRates(_ handler: @escaping (RatesResult) -> Void) {
        let request = URLRequest(url: URL(string: "https://api.coinmarketcap.com/v1/ticker/?limit=1000&convert=BTC")!)
        dataTaskWithRequest(request, handler: { data, response, error in
            if error == nil, let data = data {
                do {
                    let codes = Store.state.currencies.map({ $0.code.lowercased() })
                    let tickers = try JSONDecoder().decode([Ticker].self, from: data)
                    let rates: [Rate] = tickers.compactMap({ ticker in
                        guard ticker.btcRate != nil, let rate = Double(ticker.btcRate!) else { return nil }
                        guard codes.contains(ticker.symbol.lowercased()) else { return nil }
                        return Rate(code: Currencies.btc.code,
                                    name: ticker.name,
                                    rate: rate,
                                    reciprocalCode: ticker.symbol.lowercased())
                    })
                    handler(.success(rates))
                } catch let e {
                    handler(.error(e.localizedDescription))
                }
            } else {
                handler(.error(error?.localizedDescription ?? "unknown error"))
            }
        }).resume()
    }
    
    func savePushNotificationToken(_ token: Data) {
        var req = URLRequest(url: url("/me/push-devices"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let reqJson = [
            "token": token.hexString,
            "service": "apns",
            "data": [   "e": pushNotificationEnvironment(),
                        "b": Bundle.main.bundleIdentifier!]
            ] as [String : Any]
        do {
            let dat = try JSONSerialization.data(withJSONObject: reqJson, options: .prettyPrinted)
            req.httpBody = dat
        } catch (let e) {
            log("JSON Serialization error \(e)")
            return
        }
        dataTaskWithRequest(req as URLRequest, authenticated: true, retryCount: 0) { (dat, resp, er) in
            let dat2 = String(data: dat ?? Data(), encoding: .utf8)
            self.log("save push token resp: \(String(describing: resp)) data: \(String(describing: dat2))")
        }.resume()
    }

    func deletePushNotificationToken(_ token: Data) {
        var req = URLRequest(url: url("/me/push-devices/apns/\(token.hexString)"))
        req.httpMethod = "DELETE"
        dataTaskWithRequest(req as URLRequest, authenticated: true, retryCount: 0) { (dat, resp, er) in
            self.log("delete push token resp: \(String(describing: resp))")
            if let statusCode = resp?.statusCode {
                if statusCode >= 200 && statusCode < 300 {
                    UserDefaults.pushToken = nil
                    self.log("deleted old token")
                }
            }
        }.resume()
    }

    func fetchUTXOS(address: String, currency: CurrencyDef, completion: @escaping ([[String: Any]]?)->Void) {
        let path = "https://chainz.cryptoid.info/wgr/api.dws?key=552651714eae&q=unspent&active=\(address)";
        var req = URLRequest(url: URL(string: path)!)
        req.httpMethod = "GET"
        //req.httpBody = "addrs=\(address)".data(using: .utf8)
        dataTaskWithRequest(req, handler: { data, resp, error in
            guard error == nil else { completion(nil); return }
            if  let data = data,
                let jsonData = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {
                if let utxos = jsonData["unspent_outputs"] as? [[String: Any]] {
                    completion(utxos)
                }
            }
            else { completion(nil); return }
        }).resume()
    }
}

struct BTCRateResponse : Codable {
    let body: [BTCRate]
    
    struct BTCRate : Codable {
        let code: String
        let name: String
        let rate: Double
    }
}

struct Ticker: Codable {
    let symbol: String
    let name: String
    let usdRate: String?
    let btcRate: String?
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case name
        case usdRate = "price_usd"
        case btcRate = "price_btc"
    }
}

private func pushNotificationEnvironment() -> String {
    return E.isDebug ? "d" : "p" //development or production
}
