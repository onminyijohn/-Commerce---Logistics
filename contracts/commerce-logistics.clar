(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INSUFFICIENT_BALANCE (err u400))
(define-constant ERR_INVALID_AMOUNT (err u402))
(define-constant ERR_SUBSCRIPTION_EXPIRED (err u403))
(define-constant ERR_INVALID_PUBLISHER (err u405))

(define-constant EPOCH_BLOCKS u144)
(define-constant MIN_SUBSCRIPTION_AMOUNT u1000000)

(define-data-var next-subscription-id uint u1)
(define-data-var current-epoch uint u0)
(define-data-var total-locked-amount uint u0)

(define-map subscriptions
    uint
    {
        subscriber: principal,
        publisher: principal,
        amount: uint,
        start-block: uint,
        end-block: uint,
        is-active: bool
    }
)

(define-map publisher-info
    principal
    {
        is-registered: bool,
        total-earnings: uint,
        active-subscriptions: uint,
        service-name: (string-utf8 100)
    }
)

(define-map subscriber-subscriptions
    principal
    (list 50 uint)
)

(define-map publisher-subscribers
    principal
    (list 100 uint)
)

(define-map epoch-payouts
    { epoch: uint, publisher: principal }
    uint
)

(define-public (register-publisher (service-name (string-utf8 100)))
    (let
        (
            (publisher-data (default-to { is-registered: false, total-earnings: u0, active-subscriptions: u0, service-name: u"" } 
                            (map-get? publisher-info tx-sender)))
        )
        (if (get is-registered publisher-data)
            ERR_ALREADY_EXISTS
            (begin
                (map-set publisher-info tx-sender 
                    (merge publisher-data { is-registered: true, service-name: service-name }))
                (ok true)
            )
        )
    )
)

(define-public (create-subscription (publisher principal) (amount uint) (duration-blocks uint))
    (let
        (
            (subscription-id (var-get next-subscription-id))
            (publisher-data (map-get? publisher-info publisher))
            (current-block burn-block-height)
            (end-block (+ current-block duration-blocks))
        )
        (asserts! (>= amount MIN_SUBSCRIPTION_AMOUNT) ERR_INVALID_AMOUNT)
        (asserts! (is-some publisher-data) ERR_INVALID_PUBLISHER)
        (asserts! (get is-registered (unwrap-panic publisher-data)) ERR_INVALID_PUBLISHER)
        
        (match (stx-transfer? amount tx-sender (as-contract tx-sender))
            success
                (begin
                    (map-set subscriptions subscription-id
                        {
                            subscriber: tx-sender,
                            publisher: publisher,
                            amount: amount,
                            start-block: current-block,
                            end-block: end-block,
                            is-active: true
                        }
                    )
                    
                    (map-set subscriber-subscriptions tx-sender
                        (unwrap-panic (as-max-len? 
                            (append (default-to (list) (map-get? subscriber-subscriptions tx-sender)) subscription-id) 
                            u50))
                    )
                    
                    (map-set publisher-subscribers publisher
                        (unwrap-panic (as-max-len? 
                            (append (default-to (list) (map-get? publisher-subscribers publisher)) subscription-id) 
                            u100))
                    )
                    
                    (map-set publisher-info publisher
                        (merge (unwrap-panic publisher-data) 
                            { active-subscriptions: (+ (get active-subscriptions (unwrap-panic publisher-data)) u1) })
                    )
                    
                    (var-set next-subscription-id (+ subscription-id u1))
                    (var-set total-locked-amount (+ (var-get total-locked-amount) amount))
                    (ok subscription-id)
                )
            error ERR_INSUFFICIENT_BALANCE
        )
    )
)

(define-public (cancel-subscription (subscription-id uint))
    (let
        (
            (subscription-data (map-get? subscriptions subscription-id))
        )
        (asserts! (is-some subscription-data) ERR_NOT_FOUND)
        (let
            (
                (subscription (unwrap-panic subscription-data))
                (subscriber (get subscriber subscription))
                (publisher (get publisher subscription))
                (amount (get amount subscription))
                (is-active (get is-active subscription))
            )
            (asserts! (is-eq subscriber tx-sender) ERR_UNAUTHORIZED)
            (asserts! is-active ERR_NOT_FOUND)
            
            (match (as-contract (stx-transfer? amount tx-sender subscriber))
                success
                    (begin
                        (map-set subscriptions subscription-id
                            (merge subscription { is-active: false })
                        )
                        
                        (let
                            (
                                (publisher-data (unwrap-panic (map-get? publisher-info publisher)))
                            )
                            (map-set publisher-info publisher
                                (merge publisher-data 
                                    { active-subscriptions: (- (get active-subscriptions publisher-data) u1) })
                            )
                        )
                        
                        (var-set total-locked-amount (- (var-get total-locked-amount) amount))
                        (ok true)
                    )
                error ERR_INSUFFICIENT_BALANCE
            )
        )
    )
)

(define-public (claim-epoch-payout)
    (let
        (
            (current-epoch-val (get-current-epoch))
            (publisher-data (map-get? publisher-info tx-sender))
            (payout-key { epoch: current-epoch-val, publisher: tx-sender })
        )
        (asserts! (is-some publisher-data) ERR_INVALID_PUBLISHER)
        (asserts! (get is-registered (unwrap-panic publisher-data)) ERR_INVALID_PUBLISHER)
        (asserts! (is-none (map-get? epoch-payouts payout-key)) ERR_ALREADY_EXISTS)
        
        (let
            (
                (active-subs (get active-subscriptions (unwrap-panic publisher-data)))
                (payout-amount (* active-subs u100000))
            )
            (if (> payout-amount u0)
                (match (as-contract (stx-transfer? payout-amount tx-sender tx-sender))
                    success
                        (begin
                            (map-set epoch-payouts payout-key payout-amount)
                            (map-set publisher-info tx-sender
                                (merge (unwrap-panic publisher-data) 
                                    { total-earnings: (+ (get total-earnings (unwrap-panic publisher-data)) payout-amount) })
                            )
                            (ok payout-amount)
                        )
                    error ERR_INSUFFICIENT_BALANCE
                )
                (ok u0)
            )
        )
    )
)

(define-public (update-epoch)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set current-epoch (+ (var-get current-epoch) u1))
        (ok (var-get current-epoch))
    )
)

(define-read-only (get-subscription (subscription-id uint))
    (map-get? subscriptions subscription-id)
)

(define-read-only (get-publisher-info (publisher principal))
    (map-get? publisher-info publisher)
)

(define-read-only (get-subscriber-subscriptions (subscriber principal))
    (default-to (list) (map-get? subscriber-subscriptions subscriber))
)

(define-read-only (get-publisher-subscribers (publisher principal))
    (default-to (list) (map-get? publisher-subscribers publisher))
)

(define-read-only (get-current-epoch)
    (/ burn-block-height EPOCH_BLOCKS)
)

(define-read-only (get-contract-stats)
    {
        total-subscriptions: (- (var-get next-subscription-id) u1),
        current-epoch: (var-get current-epoch),
        total-locked-amount: (var-get total-locked-amount)
    }
)

(define-read-only (is-subscription-active (subscription-id uint))
    (match (map-get? subscriptions subscription-id)
        subscription-data
            (and 
                (get is-active subscription-data)
                (< burn-block-height (get end-block subscription-data))
            )
        false
    )
)

(define-read-only (get-epoch-payout (epoch uint) (publisher principal))
    (map-get? epoch-payouts { epoch: epoch, publisher: publisher })
)
