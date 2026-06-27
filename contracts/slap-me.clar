;; =========================================================
;; SlapMe Smart Contract
;; Stacks / Clarity
;; =========================================================

;; ---------- OWNER ----------

(define-data-var owner principal tx-sender)

;; ---------- PAUSE ----------

(define-data-var paused bool false)

;; ---------- GLOBAL STATS ----------

(define-data-var global-slaps uint u0)
(define-data-var global-punches uint u0)

;; ---------- ACTIVITY ----------

(define-data-var activity-id uint u0)

;; ---------- ERRORS ----------

(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-PAUSED (err u101))
(define-constant ERR-NOT-FOUND (err u102))

;; ---------- USER STATS ----------

(define-map user-stats
    principal
    {
        slaps: uint,
        punches: uint
    }
)

;; ---------- ACTIVITY ----------

(define-map activities
    uint
    {
        user: principal,
        action: uint,
        block: uint
    }
)

;; =========================================================
;; PRIVATE HELPERS
;; =========================================================

(define-private (assert-not-paused)
    (if
        (var-get paused)
        ERR-PAUSED
        (ok true)
    )
)

(define-private (get-user (user principal))

    (default-to

        {
            slaps: u0,
            punches: u0
        }

        (map-get? user-stats user)
    )
)

;; =========================================================
;; PUBLIC FUNCTIONS
;; =========================================================

;; ---------- SLAP ----------

(define-public (slap)

    (begin

        (try! (assert-not-paused))

        (let
            (
                (stats (get-user tx-sender))
                (next-id (+ (var-get activity-id) u1))
            )

            ;; Update User

            (map-set
                user-stats
                tx-sender
                {
                    slaps: (+ (get slaps stats) u1),
                    punches: (get punches stats)
                }
            )

            ;; Update Global

            (var-set
                global-slaps
                (+ (var-get global-slaps) u1)
            )

            ;; Activity Counter

            (var-set activity-id next-id)

            ;; Save Activity

            (map-set
                activities
                next-id
                {
                    user: tx-sender,
                    action: u1,
                    block: stacks-block-height
                }
            )

            (ok true)
        )
    )
)

;; ---------- PUNCH ----------

(define-public (punch)

    (begin

        (try! (assert-not-paused))

        (let
            (
                (stats (get-user tx-sender))
                (next-id (+ (var-get activity-id) u1))
            )

            ;; Update User

            (map-set
                user-stats
                tx-sender
                {
                    slaps: (get slaps stats),
                    punches: (+ (get punches stats) u1)
                }
            )

            ;; Update Global

            (var-set
                global-punches
                (+ (var-get global-punches) u1)
            )

            ;; Activity Counter

            (var-set activity-id next-id)

            ;; Save Activity

            (map-set
                activities
                next-id
                {
                    user: tx-sender,
                    action: u2,
                    block: stacks-block-height
                }
            )

            (ok true)
        )
    )
)


;; ---------------- OWNER ----------------

(define-public (pause)

    (begin
        (asserts!
            (is-eq tx-sender (var-get owner))
            ERR-OWNER-ONLY
        )

        (var-set paused true)

        (ok true)
    )
)

(define-public (unpause)

    (begin
        (asserts!
            (is-eq tx-sender (var-get owner))
            ERR-OWNER-ONLY
        )

        (var-set paused false)

        (ok true)
    )
)

;; ---------------- READ ONLY ----------------

(define-read-only (get-user-stats (user principal))
    (default-to
        {
            slaps: u0,
            punches: u0
        }
        (map-get? user-stats user)
    )
)

(define-read-only (get-global-stats)
    {
        slaps: (var-get global-slaps),
        punches: (var-get global-punches)
    }
)

(define-read-only (get-last-activity-id)
    (var-get activity-id)
)

(define-read-only (get-activity (id uint))

    (match
        (map-get? activities id)

        activity
        (ok activity)

        ERR-NOT-FOUND
    )
)