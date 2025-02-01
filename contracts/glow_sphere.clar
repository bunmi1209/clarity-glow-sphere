;; GlowSphere Contract
;; Manage skincare routines, tracking and social features on the Stacks blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))

;; Data Variables
(define-map routines
    { routine-id: uint }
    {
        owner: principal,
        name: (string-ascii 50),
        description: (string-ascii 500),
        products: (list 20 (string-ascii 50)),
        created-at: uint,
        is-public: bool,
        likes: uint
    }
)

(define-map progress-records
    { record-id: uint }
    {
        owner: principal,
        routine-id: uint,
        note: (string-ascii 500),
        photo-hash: (string-ascii 64),
        timestamp: uint,
        likes: uint
    }
)

(define-map follows
    { follower: principal, following: principal }
    { timestamp: uint }
)

(define-map routine-likes
    { user: principal, routine-id: uint }
    { timestamp: uint }
)

(define-map record-likes
    { user: principal, record-id: uint }
    { timestamp: uint }
)

(define-map user-stats
    { user: principal }
    {
        routines-created: uint,
        records-created: uint,
        followers: uint,
        following: uint
    }
)

(define-data-var routine-id-nonce uint u0)
(define-data-var record-id-nonce uint u0)

;; Public Functions

;; Create a new skincare routine
(define-public (create-routine (name (string-ascii 50)) (description (string-ascii 500)) (products (list 20 (string-ascii 50))) (is-public bool))
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
                timestamp: block-height,
                likes: u0
            }
        ))
        (try! (update-user-stats-records tx-sender))
        (var-set record-id-nonce new-record-id)
        (ok new-record-id)
    )
)

;; Follow another user
(define-public (follow-user (user principal))
    (begin
        (asserts! (not (is-eq tx-sender user)) err-unauthorized)
        (try! (map-insert follows
            { follower: tx-sender, following: user }
            { timestamp: block-height }
        ))
        (try! (update-follow-stats tx-sender user))
        (ok true)
    )
)

;; Like a routine
(define-public (like-routine (routine-id uint))
    (let
        (
            (routine (get-routine routine-id))
        )
        (asserts! (is-some routine) err-not-found)
        (try! (map-insert routine-likes
            { user: tx-sender, routine-id: routine-id }
            { timestamp: block-height }
        ))
        (try! (increment-routine-likes routine-id))
        (ok true)
    )
)

;; Like a progress record
(define-public (like-record (record-id uint))
    (let
        (
            (record (get-progress-record record-id))
        )
        (asserts! (is-some record) err-not-found)
        (try! (map-insert record-likes
            { user: record-id, record-id: record-id }
            { timestamp: block-height }
        ))
        (try! (increment-record-likes record-id))
        (ok true)
    )
)

;; Private Functions

(define-private (create-routine-internal (id uint) (name (string-ascii 50)) (description (string-ascii 500)) (products (list 20 (string-ascii 50))) (is-public bool))
    (map-insert routines
        { routine-id: id }
        {
            owner: tx-sender,
            name: name,
            description: description,
            products: products,
            created-at: block-height,
            is-public: is-public,
            likes: u0
        }
    )
)

(define-private (update-user-stats-routines (user principal))
    (let
        (
            (stats (default-to 
                { routines-created: u0, records-created: u0, followers: u0, following: u0 }
                (map-get? user-stats { user: user })
            ))
        )
        (map-set user-stats
            { user: user }
            (merge stats { routines-created: (+ (get routines-created stats) u1) })
        )
        (ok true)
    )
)

(define-private (update-user-stats-records (user principal))
    (let
        (
            (stats (default-to
                { routines-created: u0, records-created: u0, followers: u0, following: u0 }
                (map-get? user-stats { user: user })
            ))
        )
        (map-set user-stats
            { user: user }
            (merge stats { records-created: (+ (get records-created stats) u1) })
        )
        (ok true)
    )
)

(define-private (update-follow-stats (follower principal) (following principal))
    (let
        (
            (follower-stats (default-to
                { routines-created: u0, records-created: u0, followers: u0, following: u0 }
                (map-get? user-stats { user: follower })
            ))
            (following-stats (default-to
                { routines-created: u0, records-created: u0, followers: u0, following: u0 }
                (map-get? user-stats { user: following })
            ))
        )
        (map-set user-stats
            { user: follower }
            (merge follower-stats { following: (+ (get following follower-stats) u1) })
        )
        (map-set user-stats
            { user: following }
            (merge following-stats { followers: (+ (get followers following-stats) u1) })
        )
        (ok true)
    )
)

(define-private (increment-routine-likes (routine-id uint))
    (let
        (
            (routine (unwrap! (get-routine routine-id) err-not-found))
        )
        (map-set routines
            { routine-id: routine-id }
            (merge routine { likes: (+ (get likes routine) u1) })
        )
        (ok true)
    )
)

(define-private (increment-record-likes (record-id uint))
    (let
        (
            (record (unwrap! (get-progress-record record-id) err-not-found))
        )
        (map-set progress-records
            { record-id: record-id }
            (merge record { likes: (+ (get likes record) u1) })
        )
        (ok true)
    )
)

;; Read Only Functions

(define-read-only (get-routine (routine-id uint))
    (map-get? routines { routine-id: routine-id })
)

(define-read-only (get-progress-record (record-id uint))
    (map-get? progress-records { record-id: record-id })
)

(define-read-only (get-user-stats (user principal))
    (map-get? user-stats { user: user })
)

(define-read-only (is-following (follower principal) (following principal))
    (is-some (map-get? follows { follower: follower, following: following }))
)

(define-read-only (has-liked-routine (user principal) (routine-id uint))
    (is-some (map-get? routine-likes { user: user, routine-id: routine-id }))
)

(define-read-only (has-liked-record (user principal) (record-id uint))
    (is-some (map-get? record-likes { user: user, record-id: record-id }))
)
