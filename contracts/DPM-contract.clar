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