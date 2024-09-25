# CCredit - DeFi Lending Platform

## Overview

This project implements a basic Decentralized Finance (DeFi) Lending Platform using Clarity smart contracts on the Stacks blockchain. The platform allows users to deposit and withdraw STX tokens, borrow from the liquidity pool, and repay their loans.

## Features

- Deposit STX tokens
- Withdraw STX tokens
- Borrow STX tokens
- Repay borrowed STX tokens
- Check account balance
- Check borrowed amount
- View total platform liquidity

## Prerequisites

- [Stacks CLI](https://docs.stacks.co/write-smart-contracts/cli-setup)
- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing

## Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/defi-lending-platform.git
   cd defi-lending-platform
   ```

2. Install dependencies:
   ```
   clarinet requirements
   ```

3. Test the smart contract:
   ```
   clarinet test
   ```

## Smart Contract Overview

The main smart contract (`defi-lending.clar`) contains the following public functions:

- `(deposit (amount uint))`: Deposit STX tokens into the platform
- `(withdraw (amount uint))`: Withdraw STX tokens from the platform
- `(borrow (amount uint))`: Borrow STX tokens from the liquidity pool
- `(repay (amount uint))`: Repay borrowed STX tokens

And the following read-only functions:

- `(get-balance (account principal))`: Get the deposited balance of an account
- `(get-borrows (account principal))`: Get the borrowed amount of an account
- `(get-total-liquidity)`: Get the total liquidity available in the platform

## Deployment

To deploy the smart contract to the Stacks testnet:

1. Make sure you have STX tokens in your testnet wallet.
2. Update the `Clarinet.toml` file with your deployment settings.
3. Run the deployment command:
   ```
   clarinet deploy --testnet
   ```

## Usage

After deployment, users can interact with the contract using the Stacks CLI or by integrating it into a web application using the [Stacks.js library](https://github.com/hirosystems/stacks.js).

Example of calling the `deposit` function using the Stacks CLI:

```
stx call_contract_func -t <CONTRACT_ADDRESS> -c defi-lending -f deposit -a <AMOUNT_IN_USTX> --testnet
```

## Future Improvements

- Implement interest rate calculations
- Add collateralization requirements
- Develop liquidation mechanisms
- Support multiple token types
- Introduce governance features

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Blessing Eze