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

