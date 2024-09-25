;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant err-not-borrower (err u102))

;; Define data vars
(define-data-var total-liquidity uint u0)

;; Define data maps
(define-map balances principal uint)
(define-map borrows principal uint)

;; Public function to deposit tokens
(define-public (deposit (amount uint))
  (let ((current-balance (default-to u0 (map-get? balances tx-sender))))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set balances tx-sender (+ current-balance amount))
    (var-set total-liquidity (+ (var-get total-liquidity) amount))
    (ok true)))

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
  (let ((current-borrows (default-to u0 (map-get? borrows tx-sender))))
    (asserts! (<= amount (var-get total-liquidity)) err-insufficient-balance)
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set borrows tx-sender (+ current-borrows amount))
    (var-set total-liquidity (- (var-get total-liquidity) amount))
    (ok true)))

;; Public function to repay borrowed tokens
(define-public (repay (amount uint))
  (let ((current-borrows (default-to u0 (map-get? borrows tx-sender))))
    (asserts! (>= current-borrows amount) err-not-borrower)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set borrows tx-sender (- current-borrows amount))
    (var-set total-liquidity (+ (var-get total-liquidity) amount))
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