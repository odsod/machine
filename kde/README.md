# KDE Manual Setup Steps

- [ ] Set "All Fonts"
- [ ] Set KWin script
- [ ] Set Plasma keyboard layout
- [ ] Apply Plasma settings to SDDM
- [ ] Set KWallet password to match login password (for PAM auto-unlock)
- [ ] Ensure KWallet name is `kdewallet` (required for PAM)
- [ ] Ensure KWallet uses Blowfish encryption (required for PAM)

### Wallet Initialization (Plasma 6)

If the wallet does not exist, initialize it by opening **KWalletManager** from your application launcher or by running:

```bash
kwalletmanager6
```

- **New Wallet Name**: `kdewallet` (Must be this for PAM)
- **Encryption**: Blowfish (Must be this for PAM)
- **Password**: Your login password (Must match for auto-unlock)
