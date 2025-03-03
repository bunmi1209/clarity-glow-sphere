;; GlowSphere Contract
;; Manage skincare routines, tracking and social features on the Stacks blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-already-liked (err u105))
(define-constant err-already-following (err u106))
(define-constant err-self-action (err u107))
(define-constant err-empty-products (err u108))

;; Enhanced input validation
(define-private (is-valid-string (s (string-ascii 500)))
    (> (len s) u0)
)

(define-private (is-valid-product-list (products (list 20 (string-ascii 50))))
    (and
        (> (len products) u0)
        (fold and true (map is-valid-string products))
    )
)

;; Create a new skincare routine with enhanced validation
(define-public (create-routine (name (string-ascii 50)) (description (string-ascii 500)) (products (list 20 (string-ascii 50))) (is-public bool))
    (begin
        (asserts! (is-valid-string name) err-invalid-input)
        (asserts! (is-valid-string description) err-invalid-input)
        (asserts! (is-valid-product-list products) err-empty-products)
        (let
            (
                (new-routine-id (+ (var-get routine-id-nonce) u1))
            )
            (try! (create-routine-internal new-routine-id name description products is-public))
            (try! (update-user-stats-routines tx-sender))
            (var-set routine-id-nonce new-routine-id)
            (ok new-routine-id)
        )
    )
)

;; Get progress record
(define-read-only (get-progress-record (record-id uint))
    (map-get? progress-records record-id)
)

;; Enhanced like-record with self-like prevention
(define-public (like-record (record-id uint))
    (let
        (
            (record (get-progress-record record-id))
        )
        (asserts! (is-some record) err-not-found)
        (asserts! (not (is-eq tx-sender (get user (unwrap-panic record)))) err-self-action)
        (asserts! (not (has-liked-record tx-sender record-id)) err-already-liked)
        (try! (map-insert record-likes
            { user: tx-sender, record-id: record-id }
            { timestamp: block-height }
        ))
        (try! (increment-record-likes record-id))
        (ok true)
    )
)

;; Enhanced like-routine with self-like prevention
(define-public (like-routine (routine-id uint))
    (let
        (
            (routine (get-routine routine-id))
        )
        (asserts! (is-some routine) err-not-found)
        (asserts! (not (is-eq tx-sender (get creator (unwrap-panic routine)))) err-self-action)
        (asserts! (not (has-liked-routine tx-sender routine-id)) err-already-liked)
        (try! (map-insert routine-likes
            { user: tx-sender, routine-id: routine-id }
            { timestamp: block-height }
        ))
        (try! (increment-routine-likes routine-id))
        (ok true)
    )
)
