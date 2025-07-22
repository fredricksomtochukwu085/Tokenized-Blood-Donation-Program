

(define-non-fungible-token blood-donation-nft uint)

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

(define-data-var last-token-id uint u0)
(define-data-var total-donations uint u0)
(define-data-var emergency-mode bool false)

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

(define-public (register-donor (blood-type (string-ascii 3)))
  (let ((current-donor tx-sender))
    (asserts! (is-none (map-get? donors current-donor)) err-already-registered)
    (asserts! (is-valid-blood-type blood-type) err-invalid-blood-type)
    (let ((is-rare (is-rare-blood-type blood-type)))
      (map-set donors current-donor
        {
          blood-type: blood-type,
          total-donations: u0,
          last-donation-height: u0,
          rare-blood-type: is-rare,
          priority-status: is-rare
        })
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

(define-private (is-valid-blood-type (blood-type (string-ascii 3)))
  (or (is-eq blood-type "A+")
      (is-eq blood-type "A-")
      (is-eq blood-type "B+")
      (is-eq blood-type "B-")
      (is-eq blood-type "AB+")
      (is-eq blood-type "AB-")
      (is-eq blood-type "O+")
      (is-eq blood-type "O-")))

(map-set rare-blood-types "AB-" true)
(map-set rare-blood-types "AB+" true)
(map-set rare-blood-types "A-" true)
(map-set rare-blood-types "B-" true)
(map-set rare-blood-types "O-" true)
