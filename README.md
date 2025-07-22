# 🩸 Tokenized Blood Donation Program

A Clarity smart contract that tokenizes blood donations using NFTs to create transparent, verifiable donation records with special incentives for rare blood types.

## 🎯 Features

- 🏥 **Hospital Registration** - Verified medical facilities can register to receive donations
- 🩸 **Donor Registration** - Donors register with their blood type for tracking
- 🎨 **NFT Donation Proof** - Each donation mints a unique NFT as verifiable proof
- ⭐ **Rare Blood Type Rewards** - Special treatment for rare blood types (AB-, AB+, A-, B-, O-)
- 🚨 **Emergency Requests** - Hospitals can create urgent blood requests
- 📊 **Analytics** - Track donation counts, blood type statistics, and donor history

## 🔧 Usage

### For Donors

1. **Register as Donor**
```clarity
(contract-call? .blood-donation register-donor "O-")
```

2. **Donate Blood**
```clarity
(contract-call? .blood-donation donate-blood 'ST1DONOR123... "City Hospital Main Campus")
```

### For Hospitals

1. **Register Hospital**
```clarity
(contract-call? .blood-donation register-hospital "City General Hospital" "123 Main St, City")
```

2. **Create Emergency Request**
```clarity
(contract-call? .blood-donation create-emergency-request "O-" u10 u9)
```

3. **Verify Donation**
```clarity
(contract-call? .blood-donation verify-donation u1 true)
```

### For Contract Owner

1. **Verify Hospital**
```clarity
(contract-call? .blood-donation verify-hospital 'ST1HOSPITAL123...)
```

2. **Set Rare Blood Types**
```clarity
(contract-call? .blood-donation set-rare-blood-type "RH-" true)
```

## 📋 Valid Blood Types

- `A+`, `A-`
- `B+`, `B-` 
- `AB+`, `AB-`
- `O+`, `O-`

## 🎁 Rare Blood Type Benefits

Donors with rare blood types (AB-, AB+, A-, B-, O-) receive:
- 🏆 Special NFTs with rare blood bonus flag
- ⚡ Priority status after 5+ donations
- 💰 Higher reward calculations (1000 vs 500 units)

## 🔍 Read-Only Functions

- `get-donor-info` - Get donor details and statistics
- `get-hospital-info` - Get hospital information
- `get-donation-record` - Get specific donation details
- `get-total-donations` - Get total platform donations
- `can-donate-today` - Check if donor can donate (24-hour cooldown)
- `is-rare-blood-type` - Check if blood type is considered rare

## 🛡️ Security Features

- Owner-only functions for hospital verification
- 24-hour donation cooldown per donor
- Hospital verification required for donations
- Token ownership validation for transfers

## 📊 Emergency System

Hospitals can create emergency blood requests with priority levels:
- Priority 9-10: Activates emergency mode
- Automatic tracking of fulfilled requests
- Emergency mode affects platform behavior

## 🚀 Getting Started

1. Deploy the contract to Stacks blockchain
2. Register hospitals and verify them
3. Donors can register and start donating
4. NFTs are automatically minted as donation proof

---

Built with ❤️ for the global health community using Clarity smart contracts.
