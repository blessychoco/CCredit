;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-not-borrower (err u102))
(define-constant err-overflow (err u103))
(define-constant err-insufficient-collateral (err u104))
(define-constant err-no-liquidation-needed (err u105))
(define-constant interest-rate u50) ;; 5% annual interest rate (50 basis points)
(define-constant blocks-per-year u52560) ;; Assuming 1 block per 10 minutes
(define-constant collateral-ratio u150) ;; 150% collateralization ratio
(define-constant liquidation-threshold u130) ;; 130% liquidation threshold

;; Define data vars
(define-data-var total-liquidity uint u0)
(define-data-var last-interest-update uint u0)

;; Define data maps
(define-map balances principal uint)
(define-map borrows principal uint)
(define-map borrow-timestamps principal uint)
(define-map collateral principal uint)

;; Helper functions
(define-read-only (safe-add (a uint) (b uint))
  (ok (+ a b)))

(define-read-only (safe-mul (a uint) (b uint))
  (ok (* a b)))

;; Calculate interest function
(define-read-only (calculate-interest (principal uint) (blocks uint))
  (let
    (
      (interest-per-block (/ interest-rate blocks-per-year))
      (interest-amount (unwrap! (safe-mul principal (unwrap! (safe-mul blocks interest-per-block) err-overflow)) err-overflow))
    )
    (ok (/ interest-amount u10000))))

;; Helper function to calculate maximum borrow amount
(define-read-only (calculate-max-borrow (collateral-amount uint))
  (ok (/ (* collateral-amount u100) collateral-ratio)))

;; Public function to deposit collateral
(define-public (deposit-collateral (amount uint))
  (let
    (
      (current-collateral (default-to u0 (map-get? collateral tx-sender)))
      (new-collateral (unwrap! (safe-add current-collateral amount) err-overflow))
    )
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set collateral tx-sender new-collateral)
    (ok true)))

;; Public function to withdraw collateral
(define-public (withdraw-collateral (amount uint))
  (let
    (
      (current-collateral (default-to u0 (map-get? collateral tx-sender)))
      (current-borrows (unwrap! (get-current-debt tx-sender) err-overflow))
      (new-collateral (- current-collateral amount))
    )
    (asserts! (>= current-collateral amount) err-insufficient-balance)
    (asserts! (>= (unwrap! (calculate-max-borrow new-collateral) err-overflow) current-borrows) err-insufficient-collateral)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set collateral tx-sender new-collateral)
    (ok true)))

;; Public function to borrow tokens
(define-public (borrow (amount uint))
  (let 
    (
      (current-borrows (unwrap! (get-current-debt tx-sender) err-overflow))
      (current-collateral (default-to u0 (map-get? collateral tx-sender)))
      (new-borrow-amount (+ current-borrows amount))
      (current-block block-height)
    )
    (asserts! (<= amount (var-get total-liquidity)) err-insufficient-balance)
    (asserts! (<= new-borrow-amount (unwrap! (calculate-max-borrow current-collateral) err-overflow)) err-insufficient-collateral)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set borrows tx-sender new-borrow-amount)
    (map-set borrow-timestamps tx-sender current-block)
    (var-set total-liquidity (- (var-get total-liquidity) amount))
    (ok true)))

;; Public function to repay borrowed tokens
(define-public (repay (amount uint))
  (let 
    (
      (current-borrows (unwrap! (get-current-debt tx-sender) err-overflow))
      (current-block block-height)
    )
    (asserts! (>= current-borrows amount) err-not-borrower)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (if (< amount current-borrows)
      (begin
        (map-set borrows tx-sender (- current-borrows amount))
        (map-set borrow-timestamps tx-sender current-block))
      (begin
        (map-delete borrows tx-sender)
        (map-delete borrow-timestamps tx-sender)))
    (var-set total-liquidity (+ (var-get total-liquidity) amount))
    (ok true)))

;; Public function to liquidate undercollateralized position
(define-public (liquidate (borrower principal))
  (let
    (
      (borrower-debt (unwrap! (get-current-debt borrower) err-overflow))
      (borrower-collateral (default-to u0 (map-get? collateral borrower)))
      (collateral-value (unwrap! (safe-mul borrower-collateral u100) err-overflow))
      (debt-value (unwrap! (safe-mul borrower-debt liquidation-threshold) err-overflow))
    )
    (asserts! (> debt-value collateral-value) err-no-liquidation-needed)
    (let
      (
        (liquidation-amount (unwrap! (safe-mul borrower-debt collateral-ratio) err-overflow))
        (adjusted-liquidation-amount (/ liquidation-amount u100))
      )
      ;; Check if the liquidator has enough funds
      (asserts! (>= (stx-get-balance tx-sender) adjusted-liquidation-amount) err-insufficient-balance)
      ;; Transfer liquidation amount from liquidator to contract
      (try! (stx-transfer? adjusted-liquidation-amount tx-sender (as-contract tx-sender)))
      ;; Transfer collateral from contract to liquidator
      (try! (as-contract (stx-transfer? borrower-collateral tx-sender tx-sender)))
      ;; Clean up borrower's data
      (map-delete borrows borrower)
      (map-delete borrow-timestamps borrower)
      (map-delete collateral borrower)
      ;; Update total liquidity
      (var-set total-liquidity 
        (unwrap! (safe-add (var-get total-liquidity) adjusted-liquidation-amount) err-overflow))
      (ok true))))

;; Read-only functions
(define-read-only (get-balance (account principal))
  (ok (default-to u0 (map-get? balances account))))

(define-read-only (get-borrows (account principal))
  (ok (default-to u0 (map-get? borrows account))))

(define-read-only (get-total-liquidity)
  (ok (var-get total-liquidity)))

;; Read-only function to get current debt including interest
(define-read-only (get-current-debt (account principal))
  (let
    (
      (borrowed-amount (default-to u0 (map-get? borrows account)))
      (borrow-timestamp (default-to u0 (map-get? borrow-timestamps account)))
      (current-block block-height)
      (blocks-passed (- current-block borrow-timestamp))
      (interest (unwrap! (calculate-interest borrowed-amount blocks-passed) err-overflow))
    )
    (ok (+ borrowed-amount interest))))

;; Read-only function to get collateral amount
(define-read-only (get-collateral (account principal))
  (ok (default-to u0 (map-get? collateral account))))

;; Read-only function to get collateralization ratio
(define-read-only (get-collateralization-ratio (account principal))
  (let
    (
      (current-debt (unwrap! (get-current-debt account) err-overflow))
      (current-collateral (unwrap! (get-collateral account) err-overflow))
    )
    (ok (if (is-eq current-debt u0)
      u0
      (/ (* current-collateral u100) current-debt)))))

;; Read-only function to check if account can be liquidated
(define-read-only (can-liquidate (account principal))
  (let
    ((ratio (unwrap! (get-collateralization-ratio account) err-overflow)))
    (ok (< ratio liquidation-threshold))))