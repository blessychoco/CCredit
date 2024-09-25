# CCredit - DeFi Lending Platform

## Overview

This project implements a Decentralized Finance (DeFi) Lending Platform using Clarity smart contracts on the Stacks blockchain. The platform allows users to deposit and withdraw STX tokens as collateral, borrow from the liquidity pool, repay their loans, and includes a liquidation mechanism.

## Features

- Deposit STX tokens as collateral
- Withdraw STX tokens
- Borrow STX tokens
- Repay borrowed STX tokens
- Liquidate undercollateralized positions
- Check account balance, borrowed amount, and collateral
- View total platform liquidity
- Liquidation Incentive Token (LIT) for liquidators

## Prerequisites

- [Stacks CLI](https://docs.stacks.co/write-smart-contracts/cli-setup)
- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing

## Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/ccredit-defi-platform.git
   cd ccredit-defi-platform
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

The main smart contract (`c-credit.clar`) contains the following public functions:

- `(deposit-collateral (amount uint))`: Deposit STX tokens as collateral
- `(withdraw-collateral (amount uint))`: Withdraw STX tokens from collateral
- `(borrow (amount uint))`: Borrow STX tokens against collateral
- `(repay (amount uint))`: Repay borrowed STX tokens
- `(liquidate (borrower principal))`: Liquidate an undercollateralized position

And the following read-only functions:

- `(get-balance (account principal))`: Get the deposited balance of an account
- `(get-borrows (account principal))`: Get the borrowed amount of an account
- `(get-collateral (account principal))`: Get the collateral amount of an account
- `(get-total-liquidity)`: Get the total liquidity available in the platform
- `(get-current-debt (account principal))`: Get the current debt of an account including interest
- `(get-collateralization-ratio (account principal))`: Get the collateralization ratio of an account
- `(can-liquidate (account principal))`: Check if an account can be liquidated

## Key Components

- Interest rate calculation
- Collateralization ratio (150%)
- Liquidation threshold (130%)
- Liquidation Incentive Token (LIT) for liquidators

## Recent Updates

- Implemented robust overflow checks in the `deposit-collateral` function to ensure safe handling of user input.
- Added a `max-uint` constant to represent the maximum value for a uint in Clarity.

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

Example of calling the `deposit-collateral` function using the Stacks CLI:

```
stx call_contract_func -t <CONTRACT_ADDRESS> -c c-credit -f deposit-collateral -a <AMOUNT_IN_USTX> --testnet
```

## Future Improvements

- Implement dynamic interest rates based on utilization
- Support multiple token types as collateral
- Introduce governance features for parameter adjustments
- Develop a user-friendly frontend interface

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Blessing Eze

