
## Overview

This project contains a comprehensive suite of Solidity smart contracts implementing tokenized vaults, oracle integrations, and DeFi utilities built on Ethereum-compatible networks. The system is designed to manage multi-asset yield farming with automated token swapping, AAVE integration, and unified share pricing through oracle aggregation.

---

## 📋 Contract Architecture

### Core Directory Structure

```
src/
├── Vaults-Beta/          # Main vault implementations
├── constants/            # Oracle proxy contracts
├── interfaces/           # Interface definitions
├── misc/                 # Utility contracts
├── modules/              # Swap modules
└── oracle/               # Oracle implementations
```

---

## 🏆 Detailed Contract Documentation

### 1. **Vaults-Beta Directory**

#### Vault.sol

**Type:** Core Vault Contract (ERC4626 Compliant)

**Purpose:** Single asset vault with AAVE integration supporting deposit, withdrawal, minting, and redemption workflows.

**Key Features:**
- Inherits from `AAVE4626` (ERC4626 standard implementation)
- Requires manager authorization for critical operations
- Initialization mechanism to prevent usage before setup
- Fee collection system (0.05% on deposits/withdrawals)
- Direct AAVE protocol integration for yield generation
- Decimal offset of 12 to handle precision

**Core Functions:**
- `_initializeVault(address sharesTo, address depositFrom, uint assetsToDeposit, uint sharesToMint)`: Sets up vault with initial assets and share distribution
- `execute(address target, bytes calldata data)`: Allows manager to execute arbitrary contract calls
- `deposit(uint256 assets, address receiver)`: Deposits assets and mints shares
- `mint(uint256 shares, address receiver)`: Mints shares with asset payment
- `withdraw(uint256 assets, address receiver, address owner)`: Withdraws assets by burning shares
- `redeem(uint256 shares, address receiver, address owner)`: Redeems shares for assets
- `setFeeReciever(address to)`: Updates fee collection address
- `setManager(address to)`: Changes vault manager (owner only)
- `burnShare(uint shares)`: Manually burn shares (requires initialization)

**State Variables:**
- `controller`: Manager address controlling vault operations
- `_initialized`: Flag preventing operations before initialization
- Inherits fee management and AAVE integration from parent

**Modifiers:**
- `onlyManager`: Restricts to vault controller
- `Initialized`: Prevents use before vault setup

**Security Considerations:**
- Initialization lock prevents unauthorized early operations
- Manager-only execution for sensitive operations
- Fee mechanism captures protocol value

---

#### Managed4626.sol

**Type:** ERC4626 Implementation with AAVE V3 Integration

**Purpose:** Base vault implementation handling single asset deposits with AAVE lending protocol integration, fee management, and share conversions.

**Key Features:**
- Full ERC4626 standard compliance
- AAVE V3 Pool integration for yield generation
- Dynamic fee system (0.05% on deposits/withdrawals)
- Virtual shares mechanism to prevent inflation attacks
- Supports both deposit/mint and withdraw/redeem workflows
- Handles assets with varying decimals
- SafeERC20 integration for safe token transfers

**Core Conversion Functions:**
- `convertToShares(uint256 assets)`: Converts assets to shares with fee deduction
- `convertToAssets(uint256 shares)`: Converts shares to assets with fee addition
- `_convertToShares(uint256 assets, Math.Rounding rounding)`: Internal conversion with virtual shares
- `_convertToAssets(uint256 shares, Math.Rounding rounding)`: Internal conversion with virtual assets

**Preview Functions:**
- `previewDeposit(uint256 assets)`: Calculates shares received for assets
- `previewMint(uint256 shares)`: Calculates asset cost for shares
- `previewWithdraw(uint256 assets)`: Calculates shares burned for assets
- `previewRedeem(uint256 shares)`: Calculates assets received for shares

**Deposit/Withdrawal Functions:**
- `deposit(uint256 assets, address receiver)`: Deposits assets, mints shares, collects fees
- `mint(uint256 shares, address receiver)`: Mints shares, collects fees
- `withdraw(uint256 assets, address receiver, address owner)`: Burns shares, withdraws assets
- `redeem(uint256 shares, address receiver, address owner)`: Redeems shares for assets

**Max Functions:**
- `maxDeposit(address)`: Returns unlimited deposit capacity
- `maxMint(address)`: Returns unlimited mint capacity
- `maxWithdraw(address owner)`: Returns maximum withdrawable assets
- `maxRedeem(address owner)`: Returns maximum redeemable shares

**State Variables:**
- `aavePool`: AAVEv3 lending pool address
- `aaveAsset`: Lent asset token (often different from underlying)
- `_asset`: Underlying vault asset
- `_underlyingDecimals`: Asset decimal places
- `_underlyingDecimalsAaveAsset`: AAVE asset decimal places
- `fee`: Fee percentage (default 50 = 0.05%)
- `_feeReciever`: Address receiving protocol fees

**Internal Workflow:**
1. User deposits assets and specifies receiver
2. Fees calculated and deducted from deposit
3. Assets transferred and approved to AAVE
4. AAVE pool supplied with assets (generates yield)
5. Shares minted to receiver
6. Fee shares minted to fee receiver

**Error Handling:**
- `ERC4626ExceededMaxDeposit`: Deposit exceeds limit
- `ERC4626ExceededMaxMint`: Mint exceeds limit
- `ERC4626ExceededMaxWithdraw`: Withdrawal exceeds balance
- `ERC4626ExceededMaxRedeem`: Redemption exceeds shares

---

#### MultiVault.sol

**Type:** Multi-Asset Vault with Oracle Aggregation

**Purpose:** Advanced vault supporting multiple underlying assets (BTC, ETH) with USD-based valuation through oracles and automatic DEX swapping for balanced asset allocation.

**Key Features:**
- Supports multiple underlying assets with different decimal places
- Oracle price aggregation for unified share pricing
- Uniswap V3 integration for 50-50 asset swapping
- Slippage protection with configurable parameters
- USDC entry/exit point for users
- Fee collection system (1% transaction fee default)
- Multi-asset balance tracking

**Core State Variables:**
- `_assets`: Array of underlying assets (BTC, ETH, etc.)
- `_assetDecimals`: Decimal places for each asset
- `_orcales`: Oracle addresses for price feeds
- `_usdc`: USDC token for entry/exit
- `feeValues`: Uniswap V3 fee tiers per asset pair
- `slippage`: Slippage tolerance (20 = 2%)
- `_txFee`: Transaction fee (100 = 1%)
- `s_okuRouter`, `s_okuQuoter`, `s_okuFactory`: Uniswap V3 components

**Price & Valuation Functions:**
- `totalAssets()`: Returns total USD value and individual asset prices
- `pricePerShare()`: Calculates share price in USD with 18 decimals
- `pricesForAssets()`: Returns USD prices for all underlying assets
- `totalAssetBalances()`: Returns balance array for all assets

**Preview Functions:**
- `previewMint(uint shares)`: Returns USDC cost to mint shares (with slippage)
- `previewRedeem(uint shares)`: Returns USDC received for redeeming shares
- `maxMint(address)`: Returns max shares mintable
- `maxRedeem(address owner)`: Returns max shares redeemable

**Mint & Redeem Functions:**
- `mint(uint256 shares, address receiver)`: 
  - Takes USDC from user
  - Splits USDC 50-50 between assets
  - Swaps on Uniswap V3 via oracle-determined amounts
  - Allocates received assets to vault
  - Issues vault shares
  
- `redeem(uint256 shares, address receiver)`:
  - Burns vault shares
  - Swaps underlying assets back to USDC
  - Returns USDC to receiver
  - Collects transaction fees

**Internal Swap Functions:**
- `_poolExistsExactInput(address tokenIn, address tokenOut, uint24 fee, uint minAmountOut)`: Validates pool existence and liquidity
- `_executeOkuSwap(bytes memory path, uint amountIn, uint amountOut)`: Executes Uniswap V3 swap
- `_quoteExactInput(bytes memory path, uint amountIn)`: Gets swap output quote
- `_getSwapPath(address tokenIn, uint24 fee, address tokenOut)`: Encodes swap path

**Asset Distribution:**
- `returnValues(uint sharesAmount)`: Calculates underlying asset amounts for share redemption
  - Distributes equally across assets (divisor = 2)
  - Accounts for different decimal places
  - Applies slippage adjustment for received amounts

**Fee Management:**
- `_processFee(uint shares)`: Calculates and collects transaction fees
- `_withdrawFee(uint amount, address to)`: Distributes collected fees
- `_setSlippage(uint num)`: Updates slippage tolerance
- `_setFee(uint num)`: Updates transaction fee

**Decimal Offset:** +8 (total decimals = 26 from 18 base)

**Important Notes:**
- Assumes hardcoded 2-asset structure (BTC with 8 decimals, ETH with 18 decimals)
- Oracle dependency critical for proper valuations
- Slippage settings impact redemption amounts
- Fee collection denominated in vault shares

---

#### BETHVault.sol

**Type:** Managed Multi-Asset Vault

**Purpose:** Extension of MultiVault with operator management, yield distribution, and fund utilization tracking for professional asset management.

**Key Features:**
- Inherits all MultiVault functionality
- Operator role for fund management
- Utilization tracking per asset
- Dynamic parameter adjustment
- Yield distribution separate from vault operations

**Core Functions:**
- `initialize(address to, uint sharesToMint, uint[] memory initialAssets)`: 
  - One-time setup transferring initial assets
  - Mints initial shares to specified address
  - Validates user has sufficient balances

- `execute(address target, bytes calldata data)`: Owner-only arbitrary execution

- `opWithdrawAssets(address token, uint amount, address to)`:
  - Operator withdraws assets for yield farming
  - Tracks withdrawn amount in `totalUtilised`
  - Updates vault balance

- `opDepositAssets(address token, uint amount, address from)`:
  - Operator returns borrowed assets
  - Decrements utilization counter
  - Only for initial assets (indices 0-1)

- `opDepositYield(address token, uint amount, address from)`:
  - Operator deposits earned yield
  - Increases vault asset balances
  - Contributes to vault value

- `withdrawFee(uint amount, address to)`: Distributes accumulated fees

- `changeStates(...)`: Owner can update all configuration parameters including:
  - Asset addresses
  - Oracle addresses
  - Swap routers and quoters
  - Decimal settings
  - Fee values

- `setSlippage(uint num)`: Adjusts slippage tolerance
- `setFee(uint num)`: Adjusts transaction fee
- `setOperator(address to)`: Changes operator

**State Variables:**
- `operator`: Address authorized to manage funds
- `initalized`: Initialization flag
- `totalUtilised`: Tracks borrowed amounts per asset

**Modifiers:**
- `isInitialized`: Requires initialization complete
- `isOp`: Restricts to operator address

---

#### calculationImpl.sol

**Type:** Utility/Test Contract

**Purpose:** Provides share-to-asset conversion calculations with hardcoded values for reference and testing.

**Functions:**
- `pricePerShare()`: Calculates share price from total supply and assets
- `returnValues()`: Maps shares to individual asset amounts (BTC, ETH) normalized to 18 decimals
- `totalAssetValue()`: Aggregates value of multi-asset position using hardcoded prices

**Hardcoded Values:**
- BTC Price: $97,842 (8 decimals)
- ETH Price: $3,681 (18 decimals)
- Example Holdings: 1 BTC + 1 ETH

**Note:** For testing/calculation reference only; replace with live oracle data in production.

---

### 2. **Constants Directory** (Oracle Proxies)

#### APIProxy.sol

**Type:** Interface Definition

**Purpose:** Defines the standard interface for oracle proxy contracts providing price feeds.

**Interface Definition:**
```solidity
interface IProxy {
    function read() external view returns (int224 value, uint32 timestamp);
    function api3ServerV1() external view returns (address);
}
```

**Return Values:**
- `value`: Price data with 224-bit signed integer (supports negative prices for error signaling)
- `timestamp`: Block timestamp when price was last updated
- Returns format: (int224, uint32)

---

#### AproAdjust.sol

**Type:** Chainlink Oracle Adapter

**Purpose:** Adapter contract converting Chainlink aggregator prices to IProxy-compatible format with price scaling.

**Key Components:**

**AggregatorV3Interface Implementation:**
- Integrates with Chainlink price feeds
- Reads latest round data with 8 decimals (standard Chainlink)

**Adjustor Contract:**
```solidity
contract Adjustor {
    AggregatorV3Interface internal priceFeed;
```

**Constructor:**
```solidity
constructor(address feed)
```
- Takes Chainlink aggregator address
- Stores as `priceFeed`

**Core Function:**
```solidity
function read() external view returns (int224 value, uint32 timestamp)
```
- Reads latest price from Chainlink aggregator
- Scales Chainlink's 8-decimal answer by 10^10 to reach 18 decimals
- Returns (scaled_price, block.timestamp)
- Example: Chainlink price 45000 (8 decimals) → 450000000000000000 (18 decimals)

**Important Notes:**
- Only accesses `latestRoundData()` from Chainlink
- Discards roundId, startedAt, and answeredInRound fields
- Provides consistent interface with other oracle implementations

---

### 3. **Interfaces Directory**

#### IAAVEFaucet.sol

**Type:** Interface Definition

**Purpose:** Defines interface for testnet AAVE faucet for obtaining test tokens.

**Function:**
```solidity
function mint(address token, address to, uint256 amount) external returns (uint256);
```
- `token`: ERC20 token address to mint
- `to`: Recipient address
- `amount`: Quantity to mint
- Returns: Amount actually minted

**Use Case:** Testnet token distribution for vault testing

---

#### IAAVEV3.sol

**Type:** Interface Definition

**Purpose:** Defines interface for AAVE V3 Lending Pool protocol operations.

**Core Supply Function:**
```solidity
function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
) external;
```
- Deposits asset into AAVE pool
- Mints aToken equal to deposit
- Assets generate yield automatically
- `referralCode`: Optional referral tracking

**Withdrawal Function:**
```solidity
function withdraw(address asset, uint256 amount, address to) external returns (uint256);
```
- Withdraws asset from AAVE pool
- Burns aToken and returns underlying
- Returns actual withdrawn amount

**Account Data Function:**
```solidity
function getUserAccountData(address user) external view returns (
    uint256 totalCollateralBase,
    uint256 totalDebtBase,
    uint256 availableBorrowsBase,
    uint256 currentLiquidationThreshold,
    uint256 ltv,
    uint256 healthFactor
);
```
- Returns comprehensive account metrics
- All values in base currency (USD)
- Critical for risk management

---

#### IBaseSwap.sol

**Type:** Interface Definition

**Purpose:** Defines standard swap interface for token exchanges.

**Structs:**
```solidity
struct ExactInputParams {
    address tokenIn;
    address tokenOut;
    uint128 amountIn;
    address recipient;
    uint24 fee;  // 500 (0.05%), 3000 (0.3%), 10000 (1%)
}

struct ExactOutputParams {
    address tokenIn;
    address tokenOut;
    uint128 amountOut;
    address recipient;
    uint24 fee;
}
```

**Functions:**
- `exactInputSwap(ExactInputParams memory params)`: Swap fixed input for variable output
- `exactOutputSwap(ExactOutputParams memory params)`: Swap variable input for fixed output
- Returns: Amount of output/input token

**Fee Tiers:**
- Mainnet: 500, 3000, 10000
- Testnet: 400, 2000, 10000

---

#### ISwapRouter.sol

**Type:** Interface Definition (Uniswap V3 Standard)

**Purpose:** Defines Uniswap V3 Router interface for multi-hop swaps.

**Structs:**
```solidity
struct ExactInputParams {
    bytes path;              // Encoded token route
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;  // Slippage protection
}

struct ExactOutputParams {
    bytes path;              // Encoded token route (reversed)
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;   // Slippage protection
}
```

**Functions:**
- `exactInput(ExactInputParams calldata params)`: Exact amount input swap
- `exactOutput(ExactOutputParams calldata params)`: Exact amount output swap
- Both accept ETH via payable
- Returns: Actual output/input amount

**Path Encoding:**
- `abi.encodePacked(token0, fee, token1, fee, token2, ...)`
- Supports multi-hop swaps through liquidity pools
- Fee tiers define pool selection

---

### 4. **Misc Directory** (Utilities)

#### MockToken.sol

**Type:** ERC20 Test Token

**Purpose:** Simple mock ERC20 token for testing vault operations.

**Features:**
- Inherits from OpenZeppelin ERC20
- Owner-controlled minting
- Configurable decimal places
- Auto-mints supply to deployer

**Constructor Parameters:**
- `name_`: Token name
- `symbol_`: Token symbol
- `decimals`: Number of decimal places
- `supply`: Initial supply to mint

**Example Usage:**
```solidity
new TOKENMOCK("Bitcoin Mock", "MBTC", 8, 1000000)
```

---

#### vaultRescue.sol

**Type:** Emergency Recovery Contract

**Purpose:** Extracts trapped tokens from contracts (safety mechanism).

**Function:**
```solidity
function rescue(address to, address target, address token) public
```
- `to`: Recipient address
- `target`: Contract holding tokens
- `token`: Token to rescue
- Transfers full balance from target to recipient

**Important Notes:**
- Owner-only operation
- Uses `transferFrom()` (requires target approval)
- For emergency recovery only
- **Security Risk**: Can be dangerous if target address controls insufficient permissions

---

### 5. **Modules Directory**

#### BaseSwapOku.sol

**Type:** Swap Module (Currently Commented/Inactive)

**Purpose:** Abstract contract providing Uniswap V3 swap functionality with pool validation.

**Status:** Code is fully commented out (pragmas and contract definition commented)

**Would Provide:**
- ExactInput and ExactOutput swap abstractions
- Pool existence validation before swaps
- Quote fetching via Quoter
- Automatic path encoding
- Slippage protection through min amount checks
- Multiple error types for swap failures

**Note:** Not currently active; uncomment to enable Uniswap V3 integration.

---

### 6. **Oracle Directory**

#### uniswapOracle.sol

**Type:** Price Oracle with Access Control

**Purpose:** Provides BTC & ETH price updates with time-based and permission-based access control.

**Key Features:**
- Maintains current price and last update timestamp
- Endpoint-based price update authorization
- Address-specific access tokens with expiration
- Time-lock protection on price reads

**State Variables:**
- `currentPrice`: Stored price (int224 format)
- `lastUpdatedTimestamp`: Timestamp of last price update
- `_allowedEndpoints`: Mapping of authorized update sources
- `_access`: Access tokens with expiration times

**Structs:**
```solidity
struct Access {
    bool stat;          // Active/Inactive status
    uint activeTill;    // Expiration timestamp
}
```

**Core Functions:**
- `read() external view returns (int224, uint32)`:
  - Requires active access for caller
  - Requires access not expired
  - Returns (currentPrice, lastUpdatedTimestamp)
  - Caller must have active token

- `updatePrice(int224 price)`:
  - Updates price and timestamp
  - Only callable by allowed endpoints
  - Emits updates immediately

- `isAllowed(address endpoint)`:
  - Checks if endpoint is authorized

- `setAllowed(address endpoint, bool status)`:
  - Owner updates endpoint authorization

- `setAccess(address _for, bool _stat, uint _activeTill)`:
  - Owner grants/revokes access with expiration

**Modifiers:**
- `OnlyAllowed`: Restricts to authorized endpoints
- `onlyOwner`: Restricts to contract owner

**Workflow:**
1. Owner authorizes update endpoints
2. Owner grants access tokens to readers (with expiration)
3. Endpoints call `updatePrice()` with new price
4. Authorized users call `read()` to fetch price
5. Access tokens automatically expire

**Notes:**
- Designed for manual off-chain price updates
- More centralized than Chainlink/API3
- Suitable for testing and private deployments
- Expiration mechanism prevents stale access

---

## 🔧 Foundry Setup

**Foundry** is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.

### Available Tools:

- **Forge**: Ethereum testing framework
- **Cast**: Smart contract interaction utility
- **Anvil**: Local Ethereum node
- **Chisel**: Solidity REPL

### Documentation
https://book.getfoundry.sh/

### Usage

```shell
# Build contracts
$ forge build

# Run tests
$ forge test

# Format code
$ forge fmt

# Generate gas snapshots
$ forge snapshot

# Start local node
$ anvil

# Deploy script
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>

# Cast utilities
$ cast <subcommand>

# Help
$ forge --help
```

---

## 📊 Key Design Patterns

### 1. **ERC4626 Tokenized Vault Standard**
All main vaults implement ERC4626 for standardized deposit/withdrawal mechanics

### 2. **Oracle Aggregation**
MultiVault aggregates multiple oracle sources for robust price discovery

### 3. **Fee Collection**
Protocol captures 0.05-1% on operations, distributed to fee receiver

### 4. **Uniswap V3 Integration**
Leverages concentrated liquidity for efficient token swaps

### 5. **AAVE V3 Integration**
Deposits underlying assets into AAVE for yield generation

---

## 🚀 Deployment Considerations

- **Test Thoroughly**: Use MockToken contracts for testing
- **Oracle Setup**: Configure oracle addresses before vault deployment
- **Manager Roles**: Assign appropriate manager/operator addresses
- **Fee Recipients**: Set fee receiver before initialization
- **Slippage**: Adjust slippage tolerances based on market conditions
- **Access Control**: Carefully manage owner and manager permissions

---

## ⚠️ Known Limitations & WIP Notes

1. **BaseSwapOku.sol**: Currently commented out; needs activation for full functionality
2. **MultiVault**: Hardcoded 2-asset structure (BTC/ETH); requires modification for other assets
3. **calculationImpl.sol**: Uses hardcoded prices; integrate with live oracles
4. **Oracle Access**: CustomOracle more centralized than decentralized alternatives
5. **Gas Efficiency**: Multiple oracle calls on MultiVault operations increase costs
