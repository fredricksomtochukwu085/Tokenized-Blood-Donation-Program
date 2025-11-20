;; Tokenized Blood Donation Program with Blood Bank Inventory Management
;; A comprehensive smart contract for managing blood donations, NFT rewards, and blood bank inventory

(define-non-fungible-token blood-donation-nft uint)

;; Contract constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-not-registered (err u103))
(define-constant err-invalid-blood-type (err u104))
(define-constant err-already-donated-today (err u105))
(define-constant err-invalid-hospital (err u106))
(define-constant err-donation-not-found (err u107))
(define-constant err-not-authorized (err u108))
(define-constant err-insufficient-points (err u109))
(define-constant err-reward-not-available (err u110))
(define-constant err-invalid-reward-id (err u111))
(define-constant err-inventory-not-found (err u112))
(define-constant err-expired-blood-unit (err u113))
(define-constant err-insufficient-inventory (err u114))
(define-constant err-invalid-expiration-date (err u115))
(define-constant err-invalid-referrer (err u116))
(define-constant err-self-referral (err u117))
(define-constant err-already-has-referrer (err u118))

;; Contract state variables
(define-data-var last-token-id uint u0)
(define-data-var total-donations uint u0)
(define-data-var emergency-mode bool false)
(define-data-var next-milestone-id uint u1)
(define-data-var next-reward-id uint u1)
(define-data-var next-inventory-id uint u1)
(define-data-var total-blood-units uint u0)
(define-data-var next-referral-id uint u1)

;; Data maps
(define-map donors principal 
  {
    blood-type: (string-ascii 3),
    total-donations: uint,
    last-donation-height: uint,
    rare-blood-type: bool,
    priority-status: bool
  })

(define-map hospitals principal 
  {
    name: (string-ascii 50),
    location: (string-ascii 100),
    verified: bool,
    total-received: uint
  })

(define-map donation-records uint 
  {
    donor: principal,
    hospital: principal,
    blood-type: (string-ascii 3),
    donation-date: uint,
    location: (string-ascii 100),
    verified: bool,
    rare-blood-bonus: bool
  })

(define-map blood-type-counts (string-ascii 3) uint)
(define-map rare-blood-types (string-ascii 3) bool)

(define-map emergency-requests principal 
  {
    blood-type: (string-ascii 3),
    units-needed: uint,
    priority-level: uint,
    request-height: uint,
    fulfilled: bool
  })

(define-map donor-milestones principal 
  {
    bronze-achieved: bool,
    silver-achieved: bool,
    gold-achieved: bool,
    platinum-achieved: bool,
    lifetime-hero: bool,
    achievement-count: uint
  })

(define-map milestone-rewards uint
  {
    milestone-name: (string-ascii 20),
    donation-threshold: uint,
    reward-multiplier: uint,
    special-status: bool
  })

(define-map reward-catalog uint
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    points-cost: uint,
    available-quantity: uint,
    category: (string-ascii 20),
    active: bool
  })

(define-map donor-points principal uint)

(define-map redemption-history uint
  {
    donor: principal,
    reward-id: uint,
    points-spent: uint,
    redemption-date: uint,
    status: (string-ascii 20)
  })

;; NEW: Blood Bank Inventory Management Maps
(define-map blood-inventory uint
  {
    blood-type: (string-ascii 3),
    units-available: uint,
    collection-date: uint,
    expiration-date: uint,
    hospital: principal,
    status: (string-ascii 20),
    batch-id: (string-ascii 50)
  })

(define-map inventory-allocations uint
  {
    inventory-id: uint,
    allocated-to: principal,
    units-allocated: uint,
    allocation-date: uint,
    purpose: (string-ascii 100),
    status: (string-ascii 20)
  })

(define-map donor-referrals principal
  {
    referrer: (optional principal),
    total-referrals: uint,
    successful-referrals: uint,
    referral-points-earned: uint,
    referral-tier: uint
  })

(define-map referral-records uint
  {
    referrer: principal,
    referred-donor: principal,
    referral-date: uint,
    referred-donation-count: uint,
    bonus-awarded: uint,
    status: (string-ascii 20)
  })

;; Read-only functions
(define-read-only (get-last-token-id)
  (var-get last-token-id))

(define-read-only (get-token-uri (token-id uint))
  (ok none))

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? blood-donation-nft token-id)))

(define-read-only (get-donor-info (donor principal))
  (map-get? donors donor))

(define-read-only (get-hospital-info (hospital principal))
  (map-get? hospitals hospital))

(define-read-only (get-donation-record (token-id uint))
  (map-get? donation-records token-id))

(define-read-only (get-total-donations)
  (var-get total-donations))

(define-read-only (get-blood-type-count (blood-type (string-ascii 3)))
  (default-to u0 (map-get? blood-type-counts blood-type)))

(define-read-only (is-rare-blood-type (blood-type (string-ascii 3)))
  (default-to false (map-get? rare-blood-types blood-type)))

(define-read-only (get-emergency-status)
  (var-get emergency-mode))

(define-read-only (can-donate-today (donor principal))
  (match (map-get? donors donor)
    donor-data
    (let ((last-donation (get last-donation-height donor-data))
          (current-height stacks-block-height))
      (> (- current-height last-donation) u144))
    true))

(define-read-only (get-donor-priority-status (donor principal))
  (match (map-get? donors donor)
    donor-data (get priority-status donor-data)
    false))

(define-read-only (calculate-donation-reward (blood-type (string-ascii 3)))
  (if (is-rare-blood-type blood-type)
    u1000
    u500))

(define-read-only (get-hospital-donation-count (hospital principal))
  (match (map-get? hospitals hospital)
    hospital-data (get total-received hospital-data)
    u0))

(define-read-only (get-donor-milestones (donor principal))
  (default-to 
    {
      bronze-achieved: false,
      silver-achieved: false, 
      gold-achieved: false,
      platinum-achieved: false,
      lifetime-hero: false,
      achievement-count: u0
    }
    (map-get? donor-milestones donor)))

(define-read-only (get-milestone-info (milestone-id uint))
  (map-get? milestone-rewards milestone-id))

(define-read-only (calculate-milestone-reward (donor principal))
  (match (map-get? donors donor)
    donor-data
    (let ((donation-count (get total-donations donor-data))
          (milestones (get-donor-milestones donor))
          (achievement-count (get achievement-count milestones)))
      (+ u500 (* achievement-count u250)))
    u500))

(define-read-only (get-next-milestone-threshold (donor principal))
  (match (map-get? donors donor)
    donor-data
    (let ((donation-count (get total-donations donor-data)))
      (if (<= donation-count u4)
        u5
        (if (<= donation-count u9) 
          u10
          (if (<= donation-count u24)
            u25
            (if (<= donation-count u49)
              u50
              u100)))))
    u5))

(define-read-only (get-donor-points (donor principal))
  (default-to u0 (map-get? donor-points donor)))

(define-read-only (get-reward-info (reward-id uint))
  (map-get? reward-catalog reward-id))

(define-read-only (get-available-rewards)
  (var-get next-reward-id))

(define-read-only (get-redemption-record (redemption-id uint))
  (map-get? redemption-history redemption-id))

(define-read-only (calculate-total-donor-points (donor principal))
  (match (map-get? donors donor)
    donor-data
    (let ((donation-count (get total-donations donor-data))
          (is-rare (get rare-blood-type donor-data))
          (milestone-bonus (calculate-milestone-reward donor))
          (base-points (* donation-count (if is-rare u1000 u500))))
      (+ base-points milestone-bonus))
    u0))

;; NEW: Blood Bank Inventory Read-Only Functions
(define-read-only (get-inventory-info (inventory-id uint))
  (map-get? blood-inventory inventory-id))

(define-read-only (get-total-blood-units)
  (var-get total-blood-units))

(define-read-only (get-available-blood-units (blood-type (string-ascii 3)))
  (fold + (map get-inventory-units-for-type (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)) u0))

(define-read-only (get-inventory-units-for-type (inventory-id uint))
  (match (map-get? blood-inventory inventory-id)
    inventory-data
    (if (and (is-eq (get status inventory-data) "available")
             (> (get expiration-date inventory-data) stacks-block-height))
      (get units-available inventory-data)
      u0)
    u0))

(define-read-only (is-blood-unit-expired (inventory-id uint))
  (match (map-get? blood-inventory inventory-id)
    inventory-data
    (< (get expiration-date inventory-data) stacks-block-height)
    false))

(define-read-only (get-hospital-inventory (hospital principal))
  (fold + (map get-hospital-inventory-units (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)) u0))

(define-read-only (get-hospital-inventory-units (inventory-id uint))
  (match (map-get? blood-inventory inventory-id)
    inventory-data
    (if (and (is-eq (get hospital inventory-data) tx-sender)
             (is-eq (get status inventory-data) "available"))
      (get units-available inventory-data)
      u0)
    u0))

(define-read-only (get-allocation-info (allocation-id uint))
  (map-get? inventory-allocations allocation-id))

(define-read-only (get-referral-info (donor principal))
  (default-to
    {
      referrer: none,
      total-referrals: u0,
      successful-referrals: u0,
      referral-points-earned: u0,
      referral-tier: u0
    }
    (map-get? donor-referrals donor)))

(define-read-only (get-referral-record (referral-id uint))
  (map-get? referral-records referral-id))

(define-read-only (get-referral-tier (donor principal))
  (let ((referral-data (get-referral-info donor))
        (successful-refs (get successful-referrals referral-data)))
    (if (>= successful-refs u50)
      u5
      (if (>= successful-refs u25)
        u4
        (if (>= successful-refs u10)
          u3
          (if (>= successful-refs u5)
            u2
            (if (>= successful-refs u1)
              u1
              u0)))))))

(define-read-only (calculate-referral-bonus (referrer principal))
  (let ((tier (get-referral-tier referrer)))
    (if (is-eq tier u5)
      u2500
      (if (is-eq tier u4)
        u1500
        (if (is-eq tier u3)
          u1000
          (if (is-eq tier u2)
            u500
            u250))))))

(define-read-only (get-referral-leaderboard-score (donor principal))
  (let ((referral-data (get-referral-info donor)))
    (+ (* (get successful-referrals referral-data) u1000)
       (get referral-points-earned referral-data))))

;; Public functions
(define-public (register-donor (blood-type (string-ascii 3)))
  (register-donor-with-referral blood-type none))

(define-public (register-donor-with-referral (blood-type (string-ascii 3)) (referrer (optional principal)))
  (let ((current-donor tx-sender))
    (asserts! (is-none (map-get? donors current-donor)) err-already-registered)
    (asserts! (is-valid-blood-type blood-type) err-invalid-blood-type)
    (match referrer
      ref-principal
      (begin
        (asserts! (not (is-eq current-donor ref-principal)) err-self-referral)
        (asserts! (is-some (map-get? donors ref-principal)) err-invalid-referrer)
        true)
      true)
    (let ((is-rare (is-rare-blood-type blood-type))
          (referral-id (var-get next-referral-id)))
      (map-set donors current-donor
        {
          blood-type: blood-type,
          total-donations: u0,
          last-donation-height: u0,
          rare-blood-type: is-rare,
          priority-status: is-rare
        })
      (map-set donor-referrals current-donor
        {
          referrer: referrer,
          total-referrals: u0,
          successful-referrals: u0,
          referral-points-earned: u0,
          referral-tier: u0
        })
      (match referrer
        ref-principal
        (begin
          (let ((ref-data (get-referral-info ref-principal)))
            (map-set donor-referrals ref-principal
              (merge ref-data
                {total-referrals: (+ (get total-referrals ref-data) u1)}))
            (map-set referral-records referral-id
              {
                referrer: ref-principal,
                referred-donor: current-donor,
                referral-date: stacks-block-height,
                referred-donation-count: u0,
                bonus-awarded: u0,
                status: "pending"
              })
            (var-set next-referral-id (+ referral-id u1)))
          true)
        true)
      (ok true))))

(define-public (register-hospital (name (string-ascii 50)) (location (string-ascii 100)))
  (let ((hospital tx-sender))
    (asserts! (is-none (map-get? hospitals hospital)) err-already-registered)
    (map-set hospitals hospital
      {
        name: name,
        location: location,
        verified: false,
        total-received: u0
      })
    (ok true)))

(define-public (verify-hospital (hospital principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? hospitals hospital)
      hospital-data
      (begin
        (map-set hospitals hospital (merge hospital-data {verified: true}))
        (ok true))
      err-not-registered)))

(define-public (donate-blood (hospital principal) (location (string-ascii 100)))
  (let ((donor tx-sender)
        (current-height stacks-block-height)
        (new-token-id (+ (var-get last-token-id) u1)))
    (match (map-get? donors donor)
      donor-data
      (let ((blood-type (get blood-type donor-data))
            (hospital-data (unwrap! (map-get? hospitals hospital) err-not-registered)))
        (asserts! (get verified hospital-data) err-invalid-hospital)
        (asserts! (can-donate-today donor) err-already-donated-today)
        (let ((is-rare (get rare-blood-type donor-data))
              (donation-count (get total-donations donor-data)))
          (try! (nft-mint? blood-donation-nft new-token-id donor))
          (map-set donation-records new-token-id
            {
              donor: donor,
              hospital: hospital,
              blood-type: blood-type,
              donation-date: current-height,
              location: location,
              verified: true,
              rare-blood-bonus: is-rare
            })
          (unwrap-panic (check-and-award-milestones donor (+ donation-count u1)))
          (map-set donors donor (merge donor-data 
            {
              total-donations: (+ donation-count u1),
              last-donation-height: current-height,
              priority-status: (or (get priority-status donor-data) 
                                 (and is-rare (> (+ donation-count u1) u5)))
            }))
          (map-set hospitals hospital (merge hospital-data 
            {total-received: (+ (get total-received hospital-data) u1)}))
          (map-set blood-type-counts blood-type 
            (+ (get-blood-type-count blood-type) u1))
          (update-donor-points donor)
          (try! (process-referral-donation donor (+ donation-count u1)))
          (var-set last-token-id new-token-id)
          (var-set total-donations (+ (var-get total-donations) u1))
          (ok new-token-id)))
      err-not-registered)))

(define-public (verify-donation (token-id uint) (verified bool))
  (match (map-get? donation-records token-id)
    record
    (let ((hospital (get hospital record)))
      (asserts! (is-eq tx-sender hospital) err-not-authorized)
      (map-set donation-records token-id (merge record {verified: verified}))
      (ok true))
    err-donation-not-found))

(define-public (set-rare-blood-type (blood-type (string-ascii 3)) (is-rare bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-valid-blood-type blood-type) err-invalid-blood-type)
    (map-set rare-blood-types blood-type is-rare)
    (ok true)))

(define-public (create-emergency-request (blood-type (string-ascii 3)) (units-needed uint) (priority-level uint))
  (let ((hospital tx-sender)
        (current-height stacks-block-height))
    (match (map-get? hospitals hospital)
      hospital-data
      (begin
        (asserts! (get verified hospital-data) err-invalid-hospital)
        (map-set emergency-requests hospital
          {
            blood-type: blood-type,
            units-needed: units-needed,
            priority-level: priority-level,
            request-height: current-height,
            fulfilled: false
          })
        (if (> priority-level u8)
          (var-set emergency-mode true)
          true)
        (ok true))
      err-not-registered)))

(define-public (fulfill-emergency-request (hospital principal))
  (match (map-get? emergency-requests hospital)
    request
    (begin
      (map-set emergency-requests hospital (merge request {fulfilled: true}))
      (var-set emergency-mode false)
      (ok true))
    err-not-registered))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    (nft-transfer? blood-donation-nft token-id sender recipient)))

(define-public (set-emergency-mode (enabled bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set emergency-mode enabled)
    (ok true)))

(define-public (claim-milestone-achievement (donor principal))
  (match (map-get? donors donor)
    donor-data
    (let ((donation-count (get total-donations donor-data))
          (current-milestones (get-donor-milestones donor)))
      (check-and-award-milestones donor donation-count))
    err-not-registered))

(define-public (create-reward (name (string-ascii 50)) (description (string-ascii 200)) (points-cost uint) (quantity uint) (category (string-ascii 20)))
  (let ((reward-id (var-get next-reward-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set reward-catalog reward-id
      {
        name: name,
        description: description,
        points-cost: points-cost,
        available-quantity: quantity,
        category: category,
        active: true
      })
    (var-set next-reward-id (+ reward-id u1))
    (ok reward-id)))

(define-public (update-reward-quantity (reward-id uint) (new-quantity uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? reward-catalog reward-id)
      reward-data
      (begin
        (map-set reward-catalog reward-id (merge reward-data {available-quantity: new-quantity}))
        (ok true))
      err-invalid-reward-id)))

(define-public (toggle-reward-status (reward-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? reward-catalog reward-id)
      reward-data
      (begin
        (map-set reward-catalog reward-id (merge reward-data {active: (not (get active reward-data))}))
        (ok true))
      err-invalid-reward-id)))

(define-public (redeem-reward (reward-id uint))
  (let ((donor tx-sender)
        (current-points (get-donor-points donor))
        (redemption-id (var-get next-reward-id)))
    (match (map-get? reward-catalog reward-id)
      reward-data
      (let ((points-cost (get points-cost reward-data))
            (available-qty (get available-quantity reward-data))
            (is-active (get active reward-data)))
        (asserts! is-active err-reward-not-available)
        (asserts! (> available-qty u0) err-reward-not-available)
        (asserts! (>= current-points points-cost) err-insufficient-points)
        (map-set donor-points donor (- current-points points-cost))
        (map-set reward-catalog reward-id (merge reward-data {available-quantity: (- available-qty u1)}))
        (map-set redemption-history redemption-id
          {
            donor: donor,
            reward-id: reward-id,
            points-spent: points-cost,
            redemption-date: stacks-block-height,
            status: "redeemed"
          })
        (var-set next-reward-id (+ redemption-id u1))
        (ok redemption-id))
      err-invalid-reward-id)))

;; NEW: Blood Bank Inventory Management Functions
(define-public (add-blood-inventory (blood-type (string-ascii 3)) (units uint) (expiration-blocks uint) (batch-id (string-ascii 50)))
  (let ((hospital tx-sender)
        (inventory-id (var-get next-inventory-id))
        (collection-date stacks-block-height)
        (expiration-date (+ stacks-block-height expiration-blocks)))
    (match (map-get? hospitals hospital)
      hospital-data
      (begin
        (asserts! (get verified hospital-data) err-invalid-hospital)
        (asserts! (is-valid-blood-type blood-type) err-invalid-blood-type)
        (asserts! (> expiration-blocks u0) err-invalid-expiration-date)
        (map-set blood-inventory inventory-id
          {
            blood-type: blood-type,
            units-available: units,
            collection-date: collection-date,
            expiration-date: expiration-date,
            hospital: hospital,
            status: "available",
            batch-id: batch-id
          })
        (var-set next-inventory-id (+ inventory-id u1))
        (var-set total-blood-units (+ (var-get total-blood-units) units))
        (ok inventory-id))
      err-not-registered)))

(define-public (allocate-blood-units (inventory-id uint) (units-requested uint) (recipient principal) (purpose (string-ascii 100)))
  (let ((hospital tx-sender)
        (allocation-id (var-get next-inventory-id)))
    (match (map-get? blood-inventory inventory-id)
      inventory-data
      (let ((available-units (get units-available inventory-data))
            (inventory-hospital (get hospital inventory-data))
            (inventory-status (get status inventory-data)))
        (asserts! (is-eq hospital inventory-hospital) err-not-authorized)
        (asserts! (is-eq inventory-status "available") err-inventory-not-found)
        (asserts! (not (is-blood-unit-expired inventory-id)) err-expired-blood-unit)
        (asserts! (>= available-units units-requested) err-insufficient-inventory)
        (map-set blood-inventory inventory-id (merge inventory-data 
          {units-available: (- available-units units-requested)}))
        (map-set inventory-allocations allocation-id
          {
            inventory-id: inventory-id,
            allocated-to: recipient,
            units-allocated: units-requested,
            allocation-date: stacks-block-height,
            purpose: purpose,
            status: "allocated"
          })
        (if (is-eq (- available-units units-requested) u0)
          (map-set blood-inventory inventory-id (merge inventory-data {status: "depleted"}))
          true)
        (var-set next-inventory-id (+ allocation-id u1))
        (ok allocation-id))
      err-inventory-not-found)))

(define-public (mark-inventory-expired (inventory-id uint))
  (let ((hospital tx-sender))
    (match (map-get? blood-inventory inventory-id)
      inventory-data
      (begin
        (asserts! (is-eq hospital (get hospital inventory-data)) err-not-authorized)
        (asserts! (is-blood-unit-expired inventory-id) err-invalid-expiration-date)
        (map-set blood-inventory inventory-id (merge inventory-data {status: "expired"}))
        (let ((expired-units (get units-available inventory-data)))
          (var-set total-blood-units (- (var-get total-blood-units) expired-units)))
        (ok true))
      err-inventory-not-found)))

(define-public (update-inventory-status (inventory-id uint) (new-status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? blood-inventory inventory-id)
      inventory-data
      (begin
        (map-set blood-inventory inventory-id (merge inventory-data {status: new-status}))
        (ok true))
      err-inventory-not-found)))

(define-public (transfer-inventory (inventory-id uint) (recipient-hospital principal) (units uint))
  (let ((source-hospital tx-sender))
    (match (map-get? blood-inventory inventory-id)
      inventory-data
      (let ((available-units (get units-available inventory-data))
            (blood-type (get blood-type inventory-data)))
        (asserts! (is-eq source-hospital (get hospital inventory-data)) err-not-authorized)
        (asserts! (>= available-units units) err-insufficient-inventory)
        (asserts! (not (is-blood-unit-expired inventory-id)) err-expired-blood-unit)
        (asserts! (is-some (map-get? hospitals recipient-hospital)) err-not-registered)
        (map-set blood-inventory inventory-id (merge inventory-data 
          {units-available: (- available-units units)}))
        (let ((new-inventory-id (var-get next-inventory-id)))
          (map-set blood-inventory new-inventory-id
            {
              blood-type: blood-type,
              units-available: units,
              collection-date: (get collection-date inventory-data),
              expiration-date: (get expiration-date inventory-data),
              hospital: recipient-hospital,
              status: "available",
              batch-id: (get batch-id inventory-data)
            })
          (var-set next-inventory-id (+ new-inventory-id u1))
          (if (is-eq (- available-units units) u0)
            (map-set blood-inventory inventory-id (merge inventory-data {status: "depleted"}))
            true)
          (ok new-inventory-id)))
      err-inventory-not-found)))

;; Private functions
(define-private (check-and-award-milestones (donor principal) (donation-count uint))
  (let ((current-milestones (get-donor-milestones donor)))
    (begin
      (if (and (>= donation-count u5) (not (get bronze-achieved current-milestones)))
        (map-set donor-milestones donor (merge current-milestones 
          {bronze-achieved: true, achievement-count: (+ (get achievement-count current-milestones) u1)}))
        true)
      (if (and (>= donation-count u10) (not (get silver-achieved current-milestones)))
        (map-set donor-milestones donor (merge (get-donor-milestones donor)
          {silver-achieved: true, achievement-count: (+ (get achievement-count (get-donor-milestones donor)) u1)}))
        true)
      (if (and (>= donation-count u25) (not (get gold-achieved current-milestones)))
        (map-set donor-milestones donor (merge (get-donor-milestones donor)
          {gold-achieved: true, achievement-count: (+ (get achievement-count (get-donor-milestones donor)) u1)}))
        true)
      (if (and (>= donation-count u50) (not (get platinum-achieved current-milestones)))
        (map-set donor-milestones donor (merge (get-donor-milestones donor)
          {platinum-achieved: true, achievement-count: (+ (get achievement-count (get-donor-milestones donor)) u1)}))
        true)
      (if (and (>= donation-count u100) (not (get lifetime-hero current-milestones)))
        (map-set donor-milestones donor (merge (get-donor-milestones donor)
          {lifetime-hero: true, achievement-count: (+ (get achievement-count (get-donor-milestones donor)) u1)}))
        true)
      (ok true))))

(define-private (update-donor-points (donor principal))
  (let ((total-points (calculate-total-donor-points donor))
        (referral-data (get-referral-info donor))
        (referral-bonus (get referral-points-earned referral-data)))
    (map-set donor-points donor (+ total-points referral-bonus))
    true))

(define-private (process-referral-donation (donor principal) (new-donation-count uint))
  (let ((referral-data (get-referral-info donor)))
    (match (get referrer referral-data)
      referrer-principal
      (let ((ref-data (get-referral-info referrer-principal))
            (bonus (calculate-referral-bonus referrer-principal)))
        (if (and (is-eq new-donation-count u1) (is-eq (get referred-donation-count (default-to {referrer: referrer-principal, referred-donor: donor, referral-date: u0, referred-donation-count: u0, bonus-awarded: u0, status: "pending"} (map-get? referral-records (- (var-get next-referral-id) u1)))) u0))
          (begin
            (map-set donor-referrals referrer-principal
              (merge ref-data
                {
                  successful-referrals: (+ (get successful-referrals ref-data) u1),
                  referral-points-earned: (+ (get referral-points-earned ref-data) bonus),
                  referral-tier: (get-referral-tier referrer-principal)
                }))
            (update-donor-points referrer-principal)
            (ok true))
          (ok true)))
      (ok true))))

(define-read-only (is-reward-available (reward-id uint))
  (match (map-get? reward-catalog reward-id)
    reward-data
    (and (get active reward-data) (> (get available-quantity reward-data) u0))
    false))

(define-private (initialize-milestones)
  (begin
    (map-set milestone-rewards u1 {milestone-name: "Bronze Donor", donation-threshold: u5, reward-multiplier: u2, special-status: false})
    (map-set milestone-rewards u2 {milestone-name: "Silver Donor", donation-threshold: u10, reward-multiplier: u3, special-status: false})
    (map-set milestone-rewards u3 {milestone-name: "Gold Donor", donation-threshold: u25, reward-multiplier: u4, special-status: true})
    (map-set milestone-rewards u4 {milestone-name: "Platinum Donor", donation-threshold: u50, reward-multiplier: u5, special-status: true})
    (map-set milestone-rewards u5 {milestone-name: "Lifetime Hero", donation-threshold: u100, reward-multiplier: u10, special-status: true})
    (ok true)))

(define-private (initialize-reward-catalog)
  (begin
    (unwrap-panic (create-reward "Priority Scheduling" "Skip the queue for your next donation appointment" u2000 u50 "scheduling"))
    (unwrap-panic (create-reward "Health Checkup Voucher" "Free basic health screening at partner clinics" u5000 u20 "health"))
    (unwrap-panic (create-reward "Donation T-Shirt" "Exclusive blood donor merchandise t-shirt" u1500 u100 "merchandise"))
    (unwrap-panic (create-reward "Recognition Certificate" "Official certificate of appreciation for donations" u1000 u200 "recognition"))
    (unwrap-panic (create-reward "VIP Donor Status" "Special recognition and benefits for one year" u10000 u10 "status"))
    (unwrap-panic (create-reward "Referral Champion Badge" "Exclusive badge for top referrers with lifetime benefits" u15000 u5 "recognition"))
    (ok true)))

(define-private (is-valid-blood-type (blood-type (string-ascii 3)))
  (or (is-eq blood-type "A+")
      (is-eq blood-type "A-")
      (is-eq blood-type "B+")
      (is-eq blood-type "B-")
      (is-eq blood-type "AB+")
      (is-eq blood-type "AB-")
      (is-eq blood-type "O+")
      (is-eq blood-type "O-")))

;; Initialize contract state
(map-set rare-blood-types "AB-" true)
(map-set rare-blood-types "AB+" true)
(map-set rare-blood-types "A-" true)
(map-set rare-blood-types "B-" true)
(map-set rare-blood-types "O-" true)

(initialize-milestones)
(initialize-reward-catalog)
