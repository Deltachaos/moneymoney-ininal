WebBanking {
    version = 1.00,
    url = "https://ininal.com/",
    services = {"ininal"},
    description = string.format(MM.localizeText("Get balance and transactions for %s"), "ininal")
}

local Transaction = {}
Transaction.__index = Transaction

function Transaction.new(
    transactionDate,
    description,
    referenceNo,
    amount,
    currency,
    icon,
    transactionType,
    repeatActionType)
    local self = setmetatable({}, Transaction)
    self.transactionDate = transactionDate
    self.description = description
    self.referenceNo = referenceNo
    self.amount = amount
    self.currency = currency
    self.icon = icon
    self.transactionType = transactionType
    self.repeatActionType = repeatActionType
    return self
end

function Transaction.fromArray(response)
    return Transaction.new(
        response.transactionDate,
        response.description,
        response.referenceNo,
        response.amount,
        response.currency,
        response.icon,
        response.transactionType,
        response.repeatActionType
    )
end

local Transactions = {}
Transactions.__index = Transactions

function Transactions.new(transactionList)
    local self = setmetatable({}, Transactions)
    self.transactionList = transactionList
    return self
end

function Transactions.fromArray(response)
    local transactions = {}
    for _, transactionResponse in ipairs(response.transactionList) do
        table.insert(transactions, Transaction.fromArray(transactionResponse))
    end
    return Transactions.new(transactions)
end

local Card = {}
Card.__index = Card

function Card.new(cardId, productCode, cardStatus, cardType, barcodeNumber, cardNumber, cardToken)
    local self = setmetatable({}, Card)
    self.cardId = cardId
    self.productCode = productCode
    self.cardStatus = cardStatus
    self.cardType = cardType
    self.barcodeNumber = barcodeNumber
    self.cardNumber = cardNumber
    self.cardToken = cardToken
    return self
end

function Card.fromArray(response)
    return Card.new(
        response.cardId,
        response.productCode,
        response.cardStatus,
        response.cardType,
        response.barcodeNumber,
        response.cardNumber,
        response.cardToken
    )
end

local Account = {}
Account.__index = Account

function Account.new(
    accountNumber,
    accountName,
    accountStatus,
    accountBalance,
    availableBalance,
    isFavorite,
    currency,
    iban,
    ibanValid,
    cardListResponse)
    local self = setmetatable({}, Account)
    self.accountNumber = accountNumber
    self.accountName = accountName
    self.accountStatus = accountStatus
    self.accountBalance = accountBalance
    self.availableBalance = availableBalance
    self.isFavorite = isFavorite
    self.currency = currency
    self.iban = iban
    self.ibanValid = ibanValid
    self.cardListResponse = cardListResponse
    return self
end

function Account.fromArray(response)
    local cards = {}
    for _, cardResponse in ipairs(response.cardListResponse) do
        table.insert(cards, Card.fromArray(cardResponse))
    end
    return Account.new(
        response.accountNumber,
        response.accountName,
        response.accountStatus,
        response.accountBalance,
        response.availableBalance,
        response.isFavorite,
        response.currency,
        response.iban,
        response.ibanValid,
        cards
    )
end

local CardAccount = {}
CardAccount.__index = CardAccount

function CardAccount.new(
    loadableLimit,
    monthlyLoadableLimit,
    exchangeDailySellCount,
    exchangeDailyBuyCount,
    exchangeMonthlySellCount,
    exchangeMonthlyBuyCount,
    cashdrawBlockedAmount,
    availableCashdrawAmount,
    accessToken,
    accountListResponse)
    local self = setmetatable({}, CardAccount)
    self.loadableLimit = loadableLimit
    self.monthlyLoadableLimit = monthlyLoadableLimit
    self.exchangeDailySellCount = exchangeDailySellCount
    self.exchangeDailyBuyCount = exchangeDailyBuyCount
    self.exchangeMonthlySellCount = exchangeMonthlySellCount
    self.exchangeMonthlyBuyCount = exchangeMonthlyBuyCount
    self.cashdrawBlockedAmount = cashdrawBlockedAmount
    self.availableCashdrawAmount = availableCashdrawAmount
    self.accessToken = accessToken
    self.accountListResponse = accountListResponse
    return self
end

function CardAccount.fromArray(response)
    local accounts = {}
    for _, accountResponse in ipairs(response.accountListResponse) do
        table.insert(accounts, Account.fromArray(accountResponse))
    end
    return CardAccount.new(
        response.loadableLimit,
        response.monthlyLoadableLimit,
        response.exchangeDailySellCount,
        response.exchangeDailyBuyCount,
        response.exchangeMonthlySellCount,
        response.exchangeMonthlyBuyCount,
        response.cashdrawBlockedAmount,
        response.availableCashdrawAmount,
        response.accessToken,
        accounts
    )
end

local HttpClient = {}
HttpClient.__index = HttpClient

function HttpClient.new()
    local self = setmetatable({}, HttpClient)
    self.client = Connection()
    self.client.useragent = "ininal/3.6.5 (com.ngier.ininalwallet; build:3; iOS 17.4.1) Alamofire/5.4.4"
    return self
end

function HttpClient:request(method, url, options)
    local headers = options.headers or {}

    if options.auth_bearer then
        headers["Authorization"] = "Bearer " .. options.auth_bearer
    end

    local requestBodyContentType = nil
    local requestBody = nil
    if options.json then
        requestBodyContentType = "application/json"
        requestBody = JSON():set(options.json):json()
    end

    headers["Accept"] = "application/json"

    local responseBody, charset, mimeType, filename, headers =
        self.client:request(method, url, requestBody, requestBodyContentType, headers)

    local json = JSON(responseBody)

    local data = json:dictionary()

    if type(data) ~= "table" then
        error("invalid response")
    end

    return data
end

local Date = {}
Date.__index = Date

function Date.toTimestamp(date_string)
    -- Zerlegen des Datums und der Zeit
    local year, month, day, hour, min, sec, frac_sec, plus_minus, offset_hours, offset_minutes =
        date_string:match("^(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)%.(%d+)([-+])(%d%d):(%d%d)$")

    -- Prüfen, ob das Datum im RFC3339-Format ist
    if not year then
        error("Ungültiges Datum " .. date_string .. " im RFC3339-Format")
    end

    -- Konvertierung von Datum und Zeit in Unix-Zeitstempel
    local timestamp =
        os.time(
        {
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = tonumber(hour),
            min = tonumber(min),
            sec = tonumber(sec)
        }
    )

    -- Berücksichtigung der Zeitzone-Offset
    local offset_seconds = (tonumber(offset_hours) * 3600) + (tonumber(offset_minutes) * 60)
    if plus_minus == "-" then
        offset_seconds = -offset_seconds
    end

    -- Hinzufügen des Zeitzone-Offsets zum Unix-Zeitstempel
    timestamp = timestamp + offset_seconds

    return timestamp
end

function Date.toString(timestamp)
    -- Konvertierung des Unix-Zeitstempels in Datum und Zeit
    local date_time = os.date("!*t", timestamp)

    -- Formatierung des Datums und der Zeit im RFC3339-Format
    local rfc3339_date =
        string.format(
        "%04d-%02d-%02dT%02d:%02d:%02d.0+00:00",
        date_time.year,
        date_time.month,
        date_time.day,
        date_time.hour,
        date_time.min,
        date_time.sec
    )

    return rfc3339_date
end

local Client = {}
Client.__index = Client

function Client.new(authToken, token, loginCredential, deviceName, deviceId, password, deviceSignature)
    local self = setmetatable({}, Client)
    self.ENDPOINT = "https://api.ininal.com/"
    self.VERSION = "3.6.5"
    self.httpClient = HttpClient.new()
    self.authToken = authToken
    self.token = token
    self.loginCredential = loginCredential
    self.deviceName = deviceName
    self.deviceId = deviceId
    self.password = password
    self.deviceSignature = deviceSignature
    self.userToken = nil
    self.sessionToken = nil
    self.cardAccountAccessToken = nil
    return self
end

function Client.createWithSession(
    userToken,
    sessionToken,
    authToken,
    token,
    loginCredential,
    deviceName,
    deviceId,
    password,
    deviceSignature)
    local obj = Client.new(authToken, token, loginCredential, deviceName, deviceId, password, deviceSignature)
    obj.userToken = userToken
    obj.sessionToken = sessionToken
    return obj
end

function Client:request(method, url, options)
    url = self.ENDPOINT .. url:gsub("^/", "")
    return self.httpClient:request(method, url, options)
end

function Client:login()
    if self.sessionToken ~= nil then
        return true
    end

    local data =
        self:request(
        "POST",
        "v3.0/auth/login",
        {
            auth_bearer = self.authToken,
            json = {
                token = self.token,
                loginCredential = self.loginCredential,
                deviceName = self.deviceName,
                deviceId = self.deviceId,
                password = self.password,
                appVersion = self.VERSION,
                deviceSignature = self.deviceSignature
            }
        }
    )

    if not (data.response and data.response.authStatus and data.response.token and data.response.userToken) then
        error("Invalid response")
    end

    if data.response.authStatus == "AUTHORIZED" then
        self.sessionToken = data.response.token
        self.userToken = data.response.userToken
    end

    if data.response.authStatus == "OTP_REQUIRED" then
        error("not implemented")
    end

    return true
end

function Client:getSessionToken()
    self:login()
    return self.sessionToken
end

function Client:getUserToken()
    self:login()
    return self.userToken
end

function Client:getCardAccount()
    local data =
        self:request(
        "POST",
        "v3.2/users/" .. self:getUserToken() .. "/cardaccount",
        {
            auth_bearer = self:getSessionToken(),
            json = {
                deviceId = self.deviceId
            }
        }
    )

    if not data.response then
        error("Invalid response")
    end

    local cardAccountData = CardAccount.fromArray(data.response)
    self.cardAccountAccessToken = cardAccountData.accessToken
    return cardAccountData
end

function Client:getCardAccountAccessToken()
    if self.cardAccountAccessToken == nil then
        self:getCardAccount()
    end
    return self.cardAccountAccessToken
end

function Client:getTransactions(account, startDate, endDate, limit)
    if account == nil then
        local cardAccount = self:getCardAccount()
        for _, acc in ipairs(cardAccount.accountListResponse) do
            if acc.isFavorite then
                account = acc
                break
            end
        end
    end

    local accessToken = self:getCardAccountAccessToken()

    if startDate ~= nil then
        startDate = Date.toString(startDate)
    else
        startDate = ""
    end

    if endDate ~= nil then
        endDate = Date.toString(endDate)
    else
        endDate = ""
    end

    local data =
        self:request(
        "POST",
        "v3.1/users/" .. self:getUserToken() .. "/transactions/" .. account.accountNumber,
        {
            auth_bearer = accessToken,
            json = {
                resultLimit = limit or 0,
                endDate = endDate,
                startDate = startDate
            }
        }
    )

    if not data.response then
        error("Invalid response")
    end

    return Transactions.fromArray(data.response)
end

function SupportsBank(protocol, bankCode)
    return bankCode == "ininal" and protocol == ProtocolWebBanking
end

local c = nil

function InitializeSession(protocol, bankCode, username, username2, password, username3)
    c = Client.new("***TODO**", "***TODO**", username, "***TODO**", "***TODO**", password, "***TODO**")

    if not c:login() then
        return "Failed to log in. Please check your user credentials."
    end
end

function ListAccounts(knownAccounts)
    local cardAccount = c:getCardAccount()

    local accounts = {}
    for _, account in ipairs(cardAccount.accountListResponse) do
        table.insert(
            accounts,
            {
                name = account.accountName,
                owner = account.accountName,
                accountNumber = account.accountNumber,
                portfolio = false,
                currency = account.currency,
                type = AccountTypeCreditCard
            }
        )
    end

    return accounts
end

function RefreshAccount(account, since)
    local cardAccount = c:getCardAccount()
    local found = nil
    for _, acc in ipairs(cardAccount.accountListResponse) do
        if acc.accountNumber == account.accountNumber then
            found = acc
            break
        end
    end

    local cardTransactions = c:getTransactions(found, since)
    local balance = found.accountBalance
    local transactions = {}
    for _, transaction in ipairs(cardTransactions.transactionList) do
        table.insert(
            transactions,
            {
                bookingDate = Date.toTimestamp(transaction.transactionDate),
                endToEndReference = transaction.referenceNo,
                purpose = transaction.description,
                amount = transaction.amount
            }
        )
    end

    return {balance = balance, transactions = transactions}
end

function EndSession()
    return nil
end
