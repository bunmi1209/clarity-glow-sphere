;; GlowSphere Contract
;; Manage skincare routines and tracking on the Stacks blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-map routines
    { routine-id: uint }
    {
        owner: principal,
        name: (string-ascii 50),
        description: (string-ascii 500),
        products: (list 20 (string-ascii 50)),
        created-at: uint
    }
)

(define-map progress-records
    { record-id: uint }
    {
        owner: principal,
        routine-id: uint,
        note: (string-ascii 500),
        photo-hash: (string-ascii 64),
        timestamp: uint
    }
)

(define-data-var routine-id-nonce uint u0)
(define-data-var record-id-nonce uint u0)

;; Public Functions

;; Create a new skincare routine
(define-public (create-routine (name (string-ascii 50)) (description (string-ascii 500)) (products (list 20 (string-ascii 50))))
    (let
        (
            (new-routine-id (+ (var-get routine-id-nonce) u1))
        )
        (try! (create-routine-internal new-routine-id name description products))
        (var-set routine-id-nonce new-routine-id)
        (ok new-routine-id)
    )
)

;; Add a progress record
(define-public (add-progress-record (routine-id uint) (note (string-ascii 500)) (photo-hash (string-ascii 64)))
    (let
        (
            (new-record-id (+ (var-get record-id-nonce) u1))
            (routine (get-routine routine-id))
        )
        (asserts! (is-some routine) err-not-found)
        (asserts! (is-eq (get owner (unwrap-panic routine)) tx-sender) err-unauthorized)
        
        (try! (map-insert progress-records
            { record-id: new-record-id }
            {
                owner: tx-sender,
                routine-id: routine-id,
                note: note,
                photo-hash: photo-hash,
                timestamp: block-height
            }
        ))
        (var-set record-id-nonce new-record-id)
        (ok new-record-id)
    )
)

;; Private Functions

(define-private (create-routine-internal (id uint) (name (string-ascii 50)) (description (string-ascii 500)) (products (list 20 (string-ascii 50))))
    (map-insert routines
        { routine-id: id }
        {
            owner: tx-sender,
            name: name,
            description: description,
            products: products,
            created-at: block-height
        }
    )
)

;; Read Only Functions

(define-read-only (get-routine (routine-id uint))
    (map-get? routines { routine-id: routine-id })
)

(define-read-only (get-progress-record (record-id uint))
    (map-get? progress-records { record-id: record-id })
)