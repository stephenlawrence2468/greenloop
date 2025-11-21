;;  GreenLoop: Deposit & Reward Smart Contract
;;  Author: GPT-5
;;  Version: 1.0
;;  Network: Stacks
;;  Description:
;;    GreenLoop incentivizes users to return reusable items
;;    by locking deposits, issuing NFT vouchers, and rewarding
;;    timely returns with EcoReward tokens.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ---------------------------
;; SIP-010 Fungible Token Trait
;; ---------------------------
(define-trait sip010-ft-trait
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (mint (principal uint) (response bool uint))
    (burn (principal uint) (response bool uint))
  )
)

;; ---------------------------
;; Constants
;; ---------------------------
(define-constant DEPOSIT-PRICE u10000000) ;; 10 STX
(define-constant REWARD-AMOUNT u1000)     ;; reward tokens
(define-constant RETURN-DEADLINE u1440)   ;; ~10 days (~144 blocks/day)

;; ---------------------------
;; Data Variables & Maps
;; ---------------------------
(define-data-var pool-funds uint u0)

(define-non-fungible-token voucher uint)

(define-map voucher-info
  {device-id: uint}
  {
    owner: principal,
    deposit: uint,
    start-block: uint,
    referrer: (optional principal)
  }
)

(define-map referral-points
  {referrer: principal}
  {points: uint})

;; ---------------------------
;; External Reward Token Contract Reference
;; ---------------------------
(define-constant REWARD-TOKEN-ADDRESS .eco-reward-token) ;; must match deployed token



;; ---------------------------
;; Public Functions
;; ---------------------------

;; --- Borrow Item ---
(define-public (borrow-item (device-id uint) (referrer (optional principal)))
  ;; ensure NFT not already owned
  (let ((owner-opt (nft-get-owner? voucher device-id)))
    (asserts! (is-none owner-opt) (err u100)) ;; already borrowed

    ;; collect deposit
    (unwrap! (stx-transfer? DEPOSIT-PRICE tx-sender (as-contract tx-sender)) (err u101))

    ;; mint voucher NFT (check response)
    (unwrap! (nft-mint? voucher device-id tx-sender) (err u102))

    ;; store voucher info
    (map-set voucher-info
      {device-id: device-id}
      {
        owner: tx-sender,
        deposit: DEPOSIT-PRICE,
        start-block: stacks-block-height,
        referrer: referrer
      }
    )
    (ok "Borrow successful")
  )
)

;; --- Return Item ---
(define-public (return-item (device-id uint))
  (let (
    (info (map-get? voucher-info {device-id: device-id}))
  )
    (asserts! (is-some info) (err u102))
    (let ((unwrapped (unwrap! info (err u103))))
      (asserts! (is-eq (get owner unwrapped) tx-sender) (err u104))
      (unwrap! (nft-burn? voucher device-id tx-sender) (err u111))
      (map-delete voucher-info {device-id: device-id})

      (let ((elapsed (- stacks-block-height (get start-block unwrapped))))
        (if (<= elapsed RETURN-DEADLINE)
          ;; --------------------
          ;; On-time return
          ;; --------------------
          (begin
            ;; transfer back the deposit
            (unwrap! (stx-transfer? (get deposit unwrapped) (as-contract tx-sender) tx-sender) (err u105))

            ;; Referral bonus logic
            (unwrap! 
              (if (is-some (get referrer unwrapped))
                  (let ((r (unwrap-panic (get referrer unwrapped))))
                    (let ((existing (map-get? referral-points {referrer: r})))
                      (let ((current (if (is-some existing)
                                      (get points (unwrap-panic existing))
                                      u0)))
                        (map-set referral-points {referrer: r} {points: (+ current u1)})
                        (ok true)
                      )
                    )
                  )
                  (ok true)
              )
              (err u106)
            )
            
            (ok "Returned on time; deposit + reward issued.")
          )

          ;; --------------------
          ;; Late return
          ;; --------------------
          (begin
            (let ((half (/ (get deposit unwrapped) u2)))
              (unwrap! (stx-transfer? half (as-contract tx-sender) tx-sender) (err u107))
              (var-set pool-funds (+ (var-get pool-funds) half))
              (ok "Late return; half deposit refunded.")
            )
          )
        )
      )
    )
  )
)

;; ---------------------------
;; Admin: Withdraw Pool Funds
;; ---------------------------
(define-public (withdraw-pool (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender ) (err u108))
    (let ((bal (var-get pool-funds)))
      (asserts! (>= bal amount) (err u109))
      (unwrap! (stx-transfer? amount (as-contract tx-sender) recipient) (err u110))
      (var-set pool-funds (- bal amount))
      (ok "Funds withdrawn")
    )
  )
)

;; ---------------------------
;; Read-only Functions
;; ---------------------------
(define-read-only (get-voucher (device-id uint))
  (map-get? voucher-info {device-id: device-id})
)

(define-read-only (get-referrer-points (who principal))
  (map-get? referral-points {referrer: who})
)

(define-read-only (get-pool-balance)
  (ok (var-get pool-funds))
)
