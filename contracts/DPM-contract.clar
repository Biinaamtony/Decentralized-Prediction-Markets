;; Decentralized Prediction Markets
;; A platform for creating and participating in prediction markets

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u1)
(define-constant ERR-MARKET-NOT-FOUND u2)
(define-constant ERR-MARKET-CLOSED u3)
(define-constant ERR-MARKET-NOT-CLOSED u4)
(define-constant ERR-MARKET-ALREADY-RESOLVED u5)
(define-constant ERR-MARKET-NOT-RESOLVED u6)
(define-constant ERR-INVALID-PARAMETERS u7)
(define-constant ERR-INSUFFICIENT-FUNDS u8)
(define-constant ERR-ORACLE-NOT-REGISTERED u9)
(define-constant ERR-OUTCOME-NOT-FOUND u10)
(define-constant ERR-MARKET-IN-DISPUTE u11)
(define-constant ERR-ALREADY-DISPUTED u12)
(define-constant ERR-DISPUTE-PERIOD-ENDED u13)
(define-constant ERR-ALREADY-WITHDRAWN u14)
(define-constant ERR-NO-REWARDS-AVAILABLE u15)
(define-constant ERR-POSITION-NOT-FOUND u16)
(define-constant ERR-INSUFFICIENT-STAKE u17)
(define-constant ERR-MARKET-INACTIVE u18)
(define-constant ERR-DISPUTE-NOT-FOUND u19)
(define-constant ERR-ORACLE-VERIFICATION-FAILED u20)
(define-constant ERR-OUTCOME-NOT-DETERMINED u21)
(define-constant ERR-NO-POSITION u22)
(define-constant ERR-NOT-ENOUGH-LIQUIDITY u23)

;; Market status constants
(define-constant MARKET-STATUS-ACTIVE u1)
(define-constant MARKET-STATUS-CLOSED u2)
(define-constant MARKET-STATUS-RESOLVED u3)
(define-constant MARKET-STATUS-DISPUTED u4)
(define-constant MARKET-STATUS-CANCELED u5)

;; Market types
(define-constant MARKET-TYPE-BINARY u1)
(define-constant MARKET-TYPE-CATEGORICAL u2)
(define-constant MARKET-TYPE-SCALAR u3)

;; Dispute status constants
(define-constant DISPUTE-STATUS-ACTIVE u1)
(define-constant DISPUTE-STATUS-RESOLVED u2)
(define-constant DISPUTE-STATUS-REJECTED u3)

;; Oracle verification methods
(define-constant ORACLE-METHOD-MANUAL u1)
(define-constant ORACLE-METHOD-API u2)
(define-constant ORACLE-METHOD-MULTISIG u3)

;; Data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var next-market-id uint u1)
(define-data-var next-oracle-id uint u1)
(define-data-var next-dispute-id uint u1)
(define-data-var platform-fee-percent uint u100) ;; 1% as basis points
(define-data-var min-market-maker-stake uint u1000000000) ;; 1000 STX
(define-data-var dispute-period-length uint u144) ;; ~24 hours in blocks (assuming 10 min/block)
(define-data-var default-resolution-delay uint u8640) ;; ~2 months in blocks

;; Registered oracles
(define-map oracles
  { oracle-id: uint }
  {
    principal: principal,
    name: (string-utf8 100),
    description: (string-utf8 500),
    verification-method: uint,
    accuracy-rating: uint, ;; 0-100 scale
    markets-resolved: uint,
    disputes-raised: uint,
    website-url: (string-utf8 256),
    is-active: bool,
    created-at: uint,
    multisig-members: (list 10 principal),
    required-signatures: uint
  }
)

;; Markets
(define-map markets
  { market-id: uint }
  {
    creator: principal,
    title: (string-utf8 100),
    description: (string-utf8 1000),
    market-type: uint,
    resolution-source: (string-utf8 500),
    categories: (list 10 (string-utf8 50))
    creator-stake: uint,
    total-liquidity: uint,
    trading-fee-percent: uint, ;; Basis points
    creation-block: uint,
    close-block: uint,
    resolution-block: (optional uint),
    status: uint,
    resolved-outcome-index: (optional uint),
    oracle-id: uint,
    dispute-period-end: (optional uint),
    outcome-count: uint,
    outcomes: (list 10 { 
      name: (string-utf8 50), 
      current-price: uint, 
      total-shares: uint 
    }),
    total-volume: uint,
    in-dispute: bool,
    active-dispute-id: (optional uint),
    creator-reputation-stake: uint,
    scalar-lower-bound: (optional uint), ;; For scalar markets
    scalar-upper-bound: (optional uint),  ;; For scalar markets
    scalar-resolution-value: (optional uint), ;; For scalar markets
    resolution-details: (optional (string-utf8 500))
  }
)
;; User positions in markets
(define-map positions
  { market-id: uint, trader: principal }
  {
    outcome-stakes: (list 10 { 
      outcome-index: uint, 
      shares: uint, 
      avg-price: uint 
    }),
    total-staked: uint,
    total-shares: uint,
    initial-position-time: uint,
    last-update-time: uint,
    rewards-withdrawn: bool
  }
)

;; User reputation
(define-map user-reputation
  { user: principal }
  {
    reputation-score: uint, ;; 0-100 scale
    markets-created: uint,
    markets-participated: uint,
    successful-predictions: uint,
    total-stake-history: uint,
    total-earnings: uint,
    disputed-markets: uint,
    successful-disputes: uint,
    stake-at-risk: uint,
    last-active-block: uint
  }
)

;; Disputes
(define-map disputes
  { dispute-id: uint }
  {
    market-id: uint,
    disputer: principal,
    dispute-reason: (string-utf8 1000),
    evidence-url: (string-utf8 256),
    stake-amount: uint,
    proposed-outcome-index: (optional uint),
    proposed-scalar-value: (optional uint),
    dispute-creation-block: uint,
    votes-for: uint,
    votes-against: uint,
    status: uint,
    resolution-block: (optional uint),
    resolution-notes: (optional (string-utf8 500))
  }
)

;; Market maker liquidity pools
(define-map liquidity-providers
  { market-id: uint, provider: principal }
  {
    liquidity-amount: uint,
    pool-share-percent: uint, ;; Basis points
    added-at-block: uint,
    last-update-block: uint,
    fees-earned: uint,
    fees-withdrawn: uint
  }
)

;; Trade history for analytics
(define-map trades
  { market-id: uint, trade-index: uint }
  {
    trader: principal,
    outcome-index: uint,
    shares: uint,
    price: uint,
    is-buy: bool,
    trade-block: uint,
    fee-paid: uint
  }
)

;; Trade count for each market
(define-map market-trade-count
  { market-id: uint }
  { count: uint }
)

;; Oracle results
(define-map oracle-results
  { market-id: uint, oracle-id: uint }
  {
    reported-outcome-index: (optional uint),
    reported-scalar-value: (optional uint),
    result-block: uint,
    result-description: (string-utf8 500),
    verification-proof: (buff 256),
    confirming-principals: (list 10 principal)
  }
)

;; Read-only functions

;; Get market details
(define-read-only (get-market (market-id uint))
  (map-get? markets { market-id: market-id })
)

;; Get oracle details
(define-read-only (get-oracle (oracle-id uint))
  (map-get? oracles { oracle-id: oracle-id })
)

;; Get user position in a market
(define-read-only (get-position (market-id uint) (trader principal))
  (map-get? positions { market-id: market-id, trader: trader })
)

;; Get user reputation
(define-read-only (get-user-reputation (user principal))
  (default-to {
    reputation-score: u50,
    markets-created: u0,
    markets-participated: u0,
    successful-predictions: u0,
    total-stake-history: u0,
    total-earnings: u0,
    disputed-markets: u0,
    successful-disputes: u0,
    stake-at-risk: u0,
    last-active-block: u0
  } (map-get? user-reputation { user: user }))
)

;; Get dispute details
(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes { dispute-id: dispute-id })
)

;; Get liquidity provider details
(define-read-only (get-liquidity-provider (market-id uint) (provider principal))
  (map-get? liquidity-providers { market-id: market-id, provider: provider })
)

;; Calculate rewards for a position
(define-read-only (calculate-rewards (market-id uint) (trader principal))
  (let
    (
      (market (unwrap! (get-market market-id) (err ERR-MARKET-NOT-FOUND)))
      (position (unwrap! (get-position market-id trader) (err ERR-POSITION-NOT-FOUND)))
      (winning-outcome (unwrap! (get resolved-outcome-index market) (err ERR-MARKET-NOT-RESOLVED)))
    )
    
    ;; Check if market is resolved
    (asserts! (is-eq (get status market) MARKET-STATUS-RESOLVED) (err ERR-MARKET-NOT-RESOLVED))
    
    ;; Check if rewards already withdrawn
    (asserts! (not (get rewards-withdrawn position)) (err ERR-ALREADY-WITHDRAWN))
    
    ;; Calculate rewards based on market type
    (if (is-eq (get market-type market) MARKET-TYPE-BINARY)
      ;; Binary markets: winner takes all
      (let
        (
          (winning-shares (default-to u0 (get-shares-for-outcome position winning-outcome)))
          (reward-amount (if (> winning-shares u0)
                          (/ (* winning-shares (get total-liquidity market)) 
                             (default-to u1 (get-total-shares-for-outcome market winning-outcome)))
                          u0))
        )
        (ok reward-amount)
      )
      
      ;; Categorical markets: similar to binary
      (let
        (
          (winning-shares (default-to u0 (get-shares-for-outcome position winning-outcome)))
          (reward-amount (if (> winning-shares u0)
                          (/ (* winning-shares (get total-liquidity market)) 
                             (default-to u1 (get-total-shares-for-outcome market winning-outcome)))
                          u0))
        )
        (ok reward-amount)
      )
    )
  )
)
        {
          outcome-stakes: (update-outcome-stakes 
                         (get outcome-stakes current-position) 
                         outcome-index 
                         shares-bought 
                         (get avg-price price-data)),
          total-staked: (+ (get total-staked current-position) amount-stx),
          total-shares: (+ (get total-shares current-position) shares-bought),
          initial-position-time: (if (is-eq (get total-staked current-position) u0)
                                 block-height
                                 (get initial-position-time current-position)),
          last-update-time: block-height,
          rewards-withdrawn: false
        }
      )
      
      ;; Record trade
      (let
        (
          (trade-count (default-to { count: u0 } (map-get? market-trade-count { market-id: market-id })))
        )
        (map-set trades
          { market-id: market-id, trade-index: (get count trade-count) }
          {
            trader: tx-sender,
            outcome-index: outcome-index,
            shares: shares-bought,
            price: (get avg-price price-data),
            is-buy: true,
            trade-block: block-height,
            fee-paid: trading-fee
          }
        )


(map-set market-trade-count
          { market-id: market-id }
          { count: (+ (get count trade-count) u1) }
        )
      )
      
      ;; Distribute trading fee to liquidity providers (simplified)
      (distribute-trading-fee market-id trading-fee)
      
      ;; Update user reputation
      (let
        (
          (user-rep (get-user-reputation tx-sender))
        )
        (map-set user-reputation
          { user: tx-sender }
          (merge user-rep {
            markets-participated: (+ (get markets-participated user-rep) 
                                 (if (is-eq (get total-staked current-position) u0) u1 u0)),
            total-stake-history: (+ (get total-stake-history user-rep) amount-stx),
            last-active-block: block-height
          })
        )
      )
      
      (ok shares-bought)
    )
  )
)

;; Helper to update outcome data with new price and shares
(define-private (update-outcome-data 
  (outcomes (list 10 { name: (string-utf8 50), current-price: uint, total-shares: uint }))
  (outcome-index uint)
  (new-price uint)
  (additional-shares uint)
)
  (map update-outcome outcomes outcome-index new-price additional-shares)
)

;; Helper to update a specific outcome
(define-private (update-outcome 
  (outcome { name: (string-utf8 50), current-price: uint, total-shares: uint })
  (index-to-update uint)
  (new-price uint)
  (additional-shares uint)
  (current-index uint)
)
  (if (is-eq current-index index-to-update)
    {
      name: (get name outcome),
      current-price: new-price,
      total-shares: (+ (get total-shares outcome) additional-shares)
    }
    outcome
  )
)

;; Helper to update outcome stakes for a user
(define-private (update-outcome-stakes
  (stakes (list 10 { outcome-index: uint, shares: uint, avg-price: uint }))
  (outcome-index uint)
  (additional-shares uint)
  (price uint)
)
  (match (find-outcome-stake stakes outcome-index)
    existing-stake
    (let
      (
        (existing-index (get outcome-index existing-stake))
        (existing-shares (get shares existing-stake))
        (existing-price (get avg-price existing-stake))
        (total-shares (+ existing-shares additional-shares))
        (new-avg-price (/ (+ (* existing-shares existing-price) (* additional-shares price)) total-shares))
      )
      (map update-stake stakes existing-index total-shares new-avg-price)
    )
    ;; No existing stake, add new one
    (append stakes {
      outcome-index: outcome-index,
      shares: additional-shares,
      avg-price: price
    })
  )
)

;; Helper to update a specific stake
(define-private (update-stake
  (stake { outcome-index: uint, shares: uint, avg-price: uint })
  (index-to-update uint)
  (new-shares uint)
  (new-price uint)
)
  (if (is-eq (get outcome-index stake) index-to-update)
    {
      outcome-index: index-to-update,
      shares: new-shares,
      avg-price: new-price
    }
    stake
  )
)
;; Helper to distribute trading fees to liquidity providers
(define-private (distribute-trading-fee (market-id uint) (fee-amount uint))
  ;; In a complete implementation, this would distribute fees proportionally to all providers
  ;; For simplicity, we just track the fee here
  (let
    (
      (market (unwrap! (get-market market-id) false))
      (creator (get creator market))
      (creator-pool (default-to 
                   { 
                     liquidity-amount: u0, 
                     pool-share-percent: u0, 
                     added-at-block: u0,
                     last-update-block: u0,
                     fees-earned: u0,
                     fees-withdrawn: u0 
                   } 
                   (map-get? liquidity-providers { market-id: market-id, provider: creator })))
    )
    
    (map-set liquidity-providers
      { market-id: market-id, provider: creator }
      (merge creator-pool {
        fees-earned: (+ (get fees-earned creator-pool) fee-amount),
        last-update-block: block-height
      })
    )
    
    true
  )
)

;; Provide liquidity to a market
(define-public (provide-liquidity (market-id uint) (amount uint))
  (let
    (
      (market (unwrap! (get-market market-id) (err ERR-MARKET-NOT-FOUND)))
      (current-liquidity (get total-liquidity market))
      (provider-data (default-to 
                    { 
                      liquidity-amount: u0, 
                      pool-share-percent: u0, 
                      added-at-block: block-height,
                      last-update-block: block-height,
                      fees-earned: u0,
                      fees-withdrawn: u0 
                    } 
                    (map-get? liquidity-providers { market-id: market-id, provider: tx-sender })))
    )
    
    ;; Check market status
    (asserts! (is-eq (get status market) MARKET-STATUS-ACTIVE) (err ERR-MARKET-INACTIVE))
    
    ;; Check market closing time
    (asserts! (< block-height (get close-block market)) (err ERR-MARKET-CLOSED))
    
    ;; Transfer STX from provider
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Calculate new pool share
    (let
      (
        (new-total-liquidity (+ current-liquidity amount))
        (new-provider-amount (+ (get liquidity-amount provider-data) amount))
        (new-share-percent (/ (* new-provider-amount u10000) new-total-liquidity))
        (existing-providers (map-get? liquidity-providers { market-id: market-id, provider: (get creator market) }))
      )
      
      ;; Update market total liquidity
      (map-set markets
        { market-id: market-id }
        (merge market {
          total-liquidity: new-total-liquidity
        })
      )
      
      ;; Update provider data
      (map-set liquidity-providers
        { market-id: market-id, provider: tx-sender }
        {
          liquidity-amount: new-provider-amount,
          pool-share-percent: new-share-percent,
          added-at-block: (if (is-eq (get liquidity-amount provider-data) u0)
                           block-height
                           (get added-at-block provider-data)),
          last-update-block: block-height,
          fees-earned: (get fees-earned provider-data),
          fees-withdrawn: (get fees-withdrawn provider-data)
        }
      )
      
      ;; Update creator's share if needed
      (match existing-providers
        creator-pool
        (let
          (
            (creator-new-share (/ (* (get liquidity-amount creator-pool) u10000) new-total-liquidity))
          )
          (map-set liquidity-providers
            { market-id: market-id, provider: (get creator market) }
            (merge creator-pool {
              pool-share-percent: creator-new-share,
              last-update-block: block-height
            })
          )
        )
        true
      )
      
      ;; Update user reputation
      (let
        (
          (user-rep (get-user-reputation tx-sender))
        )
        (map-set user-reputation
          { user: tx-sender }
          (merge user-rep {
            markets-participated: (+ (get markets-participated user-rep) 
                                 (if (is-eq (get liquidity-amount provider-data) u0) u1 u0)),
            total-stake-history: (+ (get total-stake-history user-rep) amount),
            last-active-block: block-height
          })
        )
      )
      
      (ok new-share-percent)
    )
  )
)

;; Close a market (automatic after close-block or by oracle)
(define-public (close-market (market-id uint))
  (let
    (
      (market (unwrap! (get-market market-id) (err ERR-MARKET-NOT-FOUND)))
    )
    
    ;; Check if market can be closed (past close time or called by oracle)
    (asserts! (or 
              (>= block-height (get close-block market))
              (is-eq tx-sender (get principal (unwrap! (get-oracle (get oracle-id market)) (err ERR-ORACLE-NOT-REGISTERED))))
              (is-eq tx-sender (var-get contract-owner)))
              (err ERR-NOT-AUTHORIZED))
    
    ;; Check if market is still active
    (asserts! (is-eq (get status market) MARKET-STATUS-ACTIVE) (err ERR-MARKET-CLOSED))
    
    ;; Update market status
    (map-set markets
      { market-id: market-id }
      (merge market {
        status: MARKET-STATUS-CLOSED
      })
    )
    
    (ok true)
  )
)

;; Report market outcome by oracle
(define-public (report-outcome 
  (market-id uint) 
  (outcome-index (optional uint))
  (scalar-value (optional uint))
  (result-description (string-utf8 500))
  (verification-proof (buff 256))
)
  (let
    (
      (market (unwrap! (get-market market-id) (err ERR-MARKET-NOT-FOUND)))
      (oracle-id (get oracle-id market))
      (oracle (unwrap! (get-oracle oracle-id) (err ERR-ORACLE-NOT-REGISTERED)))
    )
    
    ;; Check if market is closed
    (asserts! (is-eq (get status market) MARKET-STATUS-CLOSED) (err ERR-MARKET-NOT-CLOSED))
    
    ;; Check if report is from the assigned oracle
    (asserts! (is-eq tx-sender (get principal oracle)) (err ERR-NOT-AUTHORIZED))
    
    ;; Validate outcome based on market type
    (if (is-eq (get market-type market) MARKET-TYPE-SCALAR)
      ;; Scalar market - validate scalar value
      (match scalar-value
        value (asserts! (and 
                        (>= value (unwrap-panic (get scalar-lower-bound market)))
                        (<= value (unwrap-panic (get scalar-upper-bound market))))
                       (err ERR-INVALID-PARAMETERS))
        (err ERR-INVALID-PARAMETERS)
      )
      ;; Binary/Categorical market - validate outcome index
      (match outcome-index
        index (asserts! (< index (get outcome-count market)) (err ERR-OUTCOME-NOT-FOUND))
        (err ERR-INVALID-PARAMETERS)
      )
    )
    
    ;; Record oracle result
    (map-set oracle-results
      { market-id: market-id, oracle-id: oracle-id }
      {
        reported-outcome-index: outcome-index,
        reported-scalar-value: scalar-value,
        result-block: block-height,
        result-description: result-description,
        verification-proof: verification-proof,
        confirming-principals: (list (get principal oracle))
      }
    )
    
    ;; For Multisig oracle method, we need multiple confirmations
    (if (is-eq (get verification-method oracle) ORACLE-METHOD-MULTISIG)
      ;; Just record the result, don't resolve yet
      (ok false)
      ;; For single oracle methods, resolve immediately
      (resolve-market market-id outcome-index scalar-value result-description)
    )
  )
)

;; Confirm oracle result (for multisig oracle method)
(define-public (confirm-oracle-result (market-id uint))
  (let
    (
      (market (unwrap! (get-market market-id) (err ERR-MARKET-NOT-FOUND)))
      (oracle-id (get oracle-id market))
      (oracle (unwrap! (get-oracle oracle-id) (err ERR-ORACLE-NOT-REGISTERED)))
      (result (unwrap! (map-get? oracle-results { market-id: market-id, oracle-id: oracle-id }) 
                      (err ERR-OUTCOME-NOT-DETERMINED)))
    )
    
    ;; Check if market is closed
    (asserts! (is-eq (get status market) MARKET-STATUS-CLOSED) (err ERR-MARKET-NOT-CLOSED))
    
    ;; Check if oracle is multisig
    (asserts! (is-eq (get verification-method oracle) ORACLE-METHOD-MULTISIG) (err ERR-INVALID-PARAMETERS))
    
    ;; Check if caller is a multisig member
    (asserts! (is-some (index-of (get multisig-members oracle) tx-sender)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if caller hasn't already confirmed
    (asserts! (is-none (index-of (get confirming-principals result) tx-sender)) (err ERR-ALREADY-CONFIRMED))
    
    ;; Add confirmation
    (let
      (
        (updated-confirmations (append (get confirming-principals result) tx-sender))
      )
      (map-set oracle-results
        { market-id: market-id, oracle-id: oracle-id }
        (merge result {
          confirming-principals: updated-confirmations
        })
      )
      

    ;; Check if we have enough confirmations to resolve
      (if (>= (len updated-confirmations) (get required-signatures oracle))
        (resolve-market 
          market-id 
          (get reported-outcome-index result) 
          (get reported-scalar-value result) 
          (get result-description result))
        (ok false)
      )
    )
  )
)

;; Private function to resolve market
(define-private (resolve-market 
  (market-id uint) 
  (outcome-index (optional uint))
  (scalar-value (optional uint))
  (resolution-details (string-utf8 500))
)
  (let
    (
      (market (unwrap! (get-market market-id) (err ERR-MARKET-NOT-FOUND)))
      (oracle-id (get oracle-id market))
      (oracle (unwrap! (get-oracle oracle-id) (err ERR-ORACLE-NOT-REGISTERED)))
    )
    
    ;; Update market status and result
    (map-set markets
      { market-id: market-id }
      (merge market {
        status: MARKET-STATUS-RESOLVED,
        resolved-outcome-index: outcome-index,
        scalar-resolution-value: scalar-value,
        resolution-block: (some block-height),
        dispute-period-end: (some (+ block-height (var-get dispute-period-length))),
        resolution-details: (some resolution-details)
      })
    )
    
    ;; Update oracle stats
    (map-set oracles
      { oracle-id: oracle-id }
      (merge oracle {
        markets-resolved: (+ (get markets-resolved oracle) u1)
      })
    )
    
    (ok true)
  )
)

;; Claim rewards after market resolution
(define-public (claim-rewards (market-id uint))
  (let
    (
      (market (unwrap! (get-market market-id) (err ERR-MARKET-NOT-FOUND)))
      (position (unwrap! (get-position market-id tx-sender) (err ERR-NO-POSITION)))
      (rewards-amount (unwrap! (calculate-rewards market-id tx-sender) (err ERR-NO-REWARDS-AVAILABLE)))
    )
    
    ;; Check if market is resolved
    (asserts! (is-eq (get status market) MARKET-STATUS-RESOLVED) (err ERR-MARKET-NOT-RESOLVED))
    
    ;; Check if dispute period has ended
    (asserts! (>= block-height (unwrap! (get dispute-period-end market) (err ERR-MARKET-NOT-RESOLVED))) 
             (err ERR-MARKET-IN-DISPUTE))
    
    ;; Check if rewards haven't been withdrawn
    (asserts! (not (get rewards-withdrawn position)) (err ERR-ALREADY-WITHDRAWN))
    
    ;; Check if there are rewards to claim
    (asserts! (> rewards-amount u0) (err ERR-NO-REWARDS-AVAILABLE))
    
    ;; Transfer rewards
    (try! (as-contract (stx-transfer? rewards-amount tx-sender tx-sender)))
    
    ;; Update position to mark rewards as withdrawn
    (map-set positions
      { market-id: market-id, trader: tx-sender }
      (merge position {
        rewards-withdrawn: true
      })
    )
    
    ;; Update user reputation for successful prediction
    (let
      (
        (user-rep (get-user-reputation tx-sender))
        (winning-outcome (unwrap! (get resolved-outcome-index market) (err ERR-MARKET-NOT-RESOLVED)))
        (outcome-shares (default-to u0 (get-shares-for-outcome position winning-outcome)))
      )
      (when (> outcome-shares u0)
        (map-set user-reputation
          { user: tx-sender }
          (merge user-rep {
            successful-predictions: (+ (get successful-predictions user-rep) u1),
            total-earnings: (+ (get total-earnings user-rep) rewards-amount),
            stake-at-risk: (- (get stake-at-risk user-rep) (get total-staked position)),
            last-active-block: block-height
          })
        )
      )
    )
    
    (ok rewards-amount)
  )
)

;; Withdraw liquidity provider fees
(define-public (withdraw-fees (market-id uint))
  (let
    (
      (market (unwrap! (get-market market-id) (err ERR-MARKET-NOT-FOUND)))
      (provider-data (unwrap! (get-liquidity-provider market-id tx-sender) (err ERR-POSITION-NOT-FOUND)))
      (available-fees (- (get fees-earned provider-data) (get fees-withdrawn provider-data)))
    )
    
    ;; Check if there are fees to withdraw
    (asserts! (> available-fees u0) (err ERR-NO-REWARDS-AVAILABLE))
    
    ;; Transfer fees
    (try! (as-contract (stx-transfer? available-fees tx-sender tx-sender)))
    
    ;; Update provider data
    (map-set liquidity-providers
      { market-id: market-id, provider: tx-sender }
      (merge provider-data {
        fees-withdrawn: (+ (get fees-withdrawn provider-data) available-fees),
        last-update-block: block-height
      })
    )
    
    (ok available-fees)
  )
)

;; Dispute market resolution
(define-public (dispute-market-resolution
  (market-id uint)
  (dispute-reason (string-utf8 1000))
  (evidence-url (string-utf8 256))
  (proposed-outcome-index (optional uint))
  (proposed-scalar-value (optional uint))
  (stake-amount uint)
)
  (let
    (
      (market (unwrap! (get-market market-id) (err ERR-MARKET-NOT-FOUND)))
      (dispute-id (var-get next-dispute-id))
      (position (default-to 
               { 
                 outcome-stakes: (list), 
                 total-staked: u0, 
                 total-shares: u0, 
                 initial-position-time: u0,
                 last-update-time: u0,
                 rewards-withdrawn: false
               } 
               (get-position market-id tx-sender)))
    )
    
    ;; Check if market is resolved
    (asserts! (is-eq (get status market) MARKET-STATUS-RESOLVED) (err ERR-MARKET-NOT-RESOLVED))
    
    ;; Check if still in dispute period
    (asserts! (<= block-height (unwrap! (get dispute-period-end market) (err ERR-DISPUTE-PERIOD-ENDED)))
             (err ERR-DISPUTE-PERIOD-ENDED))
    
    ;; Check if not already in dispute
    (asserts! (not (get in-dispute market)) (err ERR-ALREADY-DISPUTED))
    
    ;; Check if user has a position in the market
    (asserts! (> (get total-staked position) u0) (err ERR-NO-POSITION))
    
    ;; Check if stake is sufficient (at least 10% of creator stake)
    (asserts! (>= stake-amount (/ (get creator-stake market) u10)) (err ERR-INSUFFICIENT-STAKE))
    
    ;; Transfer dispute stake
    (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
    
    ;; Create dispute
    (map-set disputes
      { dispute-id: dispute-id }
      {
        market-id: market-id,
        disputer: tx-sender,
        dispute-reason: dispute-reason,
        evidence-url: evidence-url,
        stake-amount: stake-amount,
        proposed-outcome-index: proposed-outcome-index,
        proposed-scalar-value: proposed-scalar-value,
        dispute-creation-block: block-height,
        votes-for: u0,
        votes-against: u0,
        status: DISPUTE-STATUS-ACTIVE,
        resolution-block: none,
        resolution-notes: none
      }
    )
    
    ;; Update market status
    (map-set markets
      { market-id: market-id }
      (merge market {
        status: MARKET-STATUS-DISPUTED,
        in-dispute: true,
        active-dispute-id: (some dispute-id)
      })
    )
    
    ;; Update user reputation
    (let
      (
        (user-rep (get-user-reputation tx-sender))
      )
      (map-set user-reputation
        { user: tx-sender }
        (merge user-rep {
          disputed-markets: (+ (get disputed-markets user-rep) u1),
          stake-at-risk: (+ (get stake-at-risk user-rep) stake-amount),
          last-active-block: block-height
        })
      )
    )
    
    ;; Increment dispute ID
    (var-set next-dispute-id (+ dispute-id u1))
    
    (ok dispute-id)
  )
)

;; Vote on a dispute
(define-public (vote-on-dispute (dispute-id uint) (vote-for bool) (weight uint))
  (let
    (
      (dispute (unwrap! (get-dispute dispute-id) (err ERR-DISPUTE-NOT-FOUND)))
      (market-id (get market-id dispute))
      (market (unwrap! (get-market market-id) (err ERR-MARKET-NOT-FOUND)))
      (user-rep (get-user-reputation tx-sender))
    )
    
    ;; Check if dispute is active
    (asserts! (is-eq (get status dispute) DISPUTE-STATUS-ACTIVE) (err ERR-DISPUTE-ALREADY-RESOLVED))
    
    ;; Check if user has reputation (minimum 10)
    (asserts! (>= (get reputation-score user-rep) u10) (err ERR-INSUFFICIENT-STAKE))
    
    ;; Check if weight is valid (can't exceed reputation)
    (asserts! (<= weight (get reputation-score user-rep)) (err ERR-INSUFFICIENT-STAKE))
    
    ;; Update dispute votes
    (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        votes-for: (if vote-for 
                    (+ (get votes-for dispute) weight)
                    (get votes-for dispute)),
        votes-against: (if vote-for
                        (get votes-against dispute)
                        (+ (get votes-against dispute) weight))
      })
    )
    
    (ok true)
  )
)

;; Resolve a dispute (only contract owner or designated arbiters)
(define-public (resolve-dispute (dispute-id uint) (uphold-dispute bool) (resolution-notes (string-utf8 500)))
  (let
    (
      (dispute (unwrap! (get-dispute dispute-id) (err ERR-DISPUTE-NOT-FOUND)))
      (market-id (get market-id dispute))
      (market (unwrap! (get-market market-id) (err ERR-MARKET-NOT-FOUND)))
      (oracle-id (get oracle-id market))
      (oracle (unwrap! (get-oracle oracle-id) (err ERR-ORACLE-NOT-REGISTERED)))
    )
    
    ;; Check if caller is authorized (contract owner for now)
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if dispute is active
    (asserts! (is-eq (get status dispute) DISPUTE-STATUS-ACTIVE) (err ERR-DISPUTE-ALREADY-RESOLVED))
    
    ;; Update dispute status
    (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        status: (if uphold-dispute DISPUTE-STATUS-RESOLVED DISPUTE-STATUS-REJECTED),
        resolution-block: (some block-height),
        resolution-notes: (some resolution-notes)
      })
    )
    
    ;; If dispute is upheld, update market with the proposed outcome
    (if uphold-dispute
      (begin
        (map-set markets
          { market-id: market-id }
          (merge market {
            status: MARKET-STATUS-RESOLVED,
            in-dispute: false,
            active-dispute-id: none,
            resolved-outcome-index: (get proposed-outcome-index dispute),
            scalar-resolution-value: (get proposed-scalar-value dispute),
            dispute-period-end: (some (+ block-height (var-get dispute-period-length)))
          })
        )
        
        ;; Update oracle dispute count
        (map-set oracles
          { oracle-id: oracle-id }
          (merge oracle {
            disputes-raised: (+ (get disputes-raised oracle) u1)
          })
        )
        
        ;; Update user reputation for successful dispute
        (let
          (
            (user-rep (get-user-reputation (get disputer dispute)))
          )
          (map-set user-reputation
            { user: (get disputer dispute) }
            (merge user-rep {
              successful-disputes: (+ (get successful-disputes user-rep) u1)
            })
          )
        )
        
        ;; Return the dispute stake to the disputer (plus a reward from the creator's stake)
        (try! (as-contract (stx-transfer? 
                         (+ (get stake-amount dispute) (/ (get creator-stake market) u10)) 
                         tx-sender 
                         (get disputer dispute))))
      )
      ;; Dispute rejected, return market to resolved state
      (begin
        (map-set markets
          { market-id: market-id }
          (merge market {
            status: MARKET-STATUS-RESOLVED,
            in-dispute: false,
            active-dispute-id: none,
            dispute-period-end: (some (+ block-height (var-get dispute-period-length)))
          })
        )
        
        ;; Transfer dispute stake to creator as compensation
        (try! (as-contract (stx-transfer? 
                         (get stake-amount dispute) 
                         tx-sender 
                         (get creator market))))
      )
    )
    
    (ok uphold-dispute)
  )
)

;; Update platform fee percentage (only contract owner)
(define-public (update-platform-fee (new-fee-percent uint))
  (begin
    ;; Only contract owner can update fee
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Check if fee is reasonable (max 5%)
    (asserts! (<= new-fee-percent u500) (err ERR-INVALID-PARAMETERS))
    
    ;; Update fee
    (var-set platform-fee-percent new-fee-percent)
    
    (ok true)
  )
)

;; Update minimum market maker stake (only contract owner)
(define-public (update-min-market-maker-stake (new-min-stake uint))
  (begin
    ;; Only contract owner can update
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Update minimum stake
    (var-set min-market-maker-stake new-min-stake)
    
    (ok true)
  )
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    ;; Only current owner can transfer
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Update owner
    (var-set contract-owner new-owner)
    
    (ok true)
  )
)

