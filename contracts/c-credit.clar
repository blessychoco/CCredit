;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-not-borrower (err u102))
(define-constant err-overflow (err u103))
(define-constant interest-rate u50) ;; 5% annual interest rate (50 basis points)
(define-constant blocks-per-year u52560) ;; Assuming 1 block per 10 minutes

;; Define data vars
(define-data-var total-liquidity uint u0)
(define-data-var last-interest-update uint u0)

;; Define data maps
(define-map balances principal uint)
(define-map borrows principal uint)
(define-map borrow-timestamps principal uint)

;; Helper function for safe addition
(define-read-only (safe-add (a uint) (b uint))
  (let ((sum (+ a b)))
    (if (>= sum a)
        (ok sum)
        err-overflow)))

;; Helper function for safe multiplication
(define-read-only (safe-mul (a uint) (b uint))
  (let ((product (* a b)))
    (if (or (is-eq a u0) (is-eq (/ product a) b))
        (ok product)
        err-overflow)))

;; Helper function to calculate interest
(define-read-only (calculate-interest (principal uint) (blocks uint))
  (let
    (
      (interest-per-block (/ (* principal interest-rate) (* u100 blocks-per-year)))
    )
    (/ (* interest-per-block blocks) u100)
  )
)

;; Public function to deposit tokens
(define-public (deposit (amount uint))
  (let 
    (
      (current-balance (default-to u0 (map-get? balances tx-sender)))
    )
    (match (safe-add current-balance amount)
      success1 (match (safe-add (var-get total-liquidity) amount)
        success2 (begin
          (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
          (map-set balances tx-sender success1)
          (var-set total-liquidity success2)
          (ok true))
        error (err error))
      error (err error))
  )
)

;; Public function to withdraw tokens
(define-public (withdraw (amount uint))
  (let ((current-balance (default-to u0 (map-get? balances tx-sender))))
    (asserts! (>= current-balance amount) err-insufficient-balance)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set balances tx-sender (- current-balance amount))
    (var-set total-liquidity (- (var-get total-liquidity) amount))
    (ok true)))

;; Public function to borrow tokens
(define-public (borrow (amount uint))
  (let 
    (
      (current-borrows (default-to u0 (map-get? borrows tx-sender)))
      (current-block block-height)
    )
    (asserts! (<= amount (var-get total-liquidity)) err-insufficient-balance)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set borrows tx-sender (+ current-borrows amount))
    (map-set borrow-timestamps tx-sender current-block)
    (var-set total-liquidity (- (var-get total-liquidity) amount))
    (ok true)))

;; Public function to repay borrowed tokens
(define-public (repay (amount uint))
  (let 
    (
      (current-borrows (default-to u0 (map-get? borrows tx-sender)))
      (borrow-timestamp (default-to u0 (map-get? borrow-timestamps tx-sender)))
      (current-block block-height)
      (blocks-passed (- current-block borrow-timestamp))
      (interest (calculate-interest current-borrows blocks-passed))
      (total-due (+ current-borrows interest))
    )
    (asserts! (>= total-due amount) err-not-borrower)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (if (< amount total-due)
      (begin
        (map-set borrows tx-sender (- total-due amount))
        (map-set borrow-timestamps tx-sender current-block))
      (begin
        (map-delete borrows tx-sender)
        (map-delete borrow-timestamps tx-sender)))
    (var-set total-liquidity (+ (var-get total-liquidity) amount))
    (ok true)))

;; Public function to accrue interest
(define-public (accrue-interest)
  (let
    (
      (current-block block-height)
      (blocks-passed (- current-block (var-get last-interest-update)))
    )
    (map-set borrows
      tx-sender
      (+ (default-to u0 (map-get? borrows tx-sender))
         (calculate-interest (default-to u0 (map-get? borrows tx-sender)) blocks-passed)))
    (var-set last-interest-update current-block)
    (ok true)))

;; Read-only function to get account balance
(define-read-only (get-balance (account principal))
  (default-to u0 (map-get? balances account)))

;; Read-only function to get borrowed amount
(define-read-only (get-borrows (account principal))
  (default-to u0 (map-get? borrows account)))

;; Read-only function to get total liquidity
(define-read-only (get-total-liquidity)
  (var-get total-liquidity))

;; Read-only function to get current debt including interest
(define-read-only (get-current-debt (account principal))
  (let
    (
      (borrowed-amount (default-to u0 (map-get? borrows account)))
      (borrow-timestamp (default-to u0 (map-get? borrow-timestamps account)))
      (current-block block-height)
      (blocks-passed (- current-block borrow-timestamp))
      (interest (calculate-interest borrowed-amount blocks-passed))
    )
    (+ borrowed-amount interest)))